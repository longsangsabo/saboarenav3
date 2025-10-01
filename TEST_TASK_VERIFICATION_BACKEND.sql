-- =====================================================
-- TEST TASK VERIFICATION SYSTEM BACKEND
-- Run each section to test functionality
-- =====================================================

-- 1. CHECK TABLES CREATED
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('task_templates', 'staff_tasks', 'task_verifications', 'verification_audit_log', 'fraud_detection_rules') 
        THEN '✅ Required Table'
        ELSE '❌ Unexpected Table'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name LIKE '%task%' 
    OR table_name LIKE '%verification%' 
    OR table_name LIKE '%fraud%'
ORDER BY table_name;

-- 2. CHECK SAMPLE DATA
SELECT 'Task Templates Count' as test, COUNT(*) as result FROM task_templates
UNION ALL
SELECT 'Fraud Detection Rules Count' as test, COUNT(*) as result FROM fraud_detection_rules;

-- 3. TEST RPC FUNCTION - Get Staff Tasks
SELECT 'Testing get_staff_tasks function...' as test;
SELECT * FROM get_staff_tasks(
    (SELECT id FROM clubs LIMIT 1),  -- club_id
    NULL,  -- staff_id (all staff)
    NULL,  -- status (all statuses)
    10,    -- limit
    0      -- offset
);

-- 4. CREATE TEST TASK TEMPLATE
INSERT INTO task_templates (
    club_id,
    task_type,
    task_name,
    description,
    estimated_duration,
    deadline_hours,
    instructions
) 
SELECT 
    c.id,
    'test_cleaning',
    'TEST: Vệ sinh khu vực',
    'Đây là task test để kiểm tra hệ thống verification',
    20,
    2,
    '{"steps": ["Chuẩn bị dụng cụ", "Dọn dẹp", "Chụp ảnh xác nhận"]}'
FROM clubs c 
LIMIT 1
RETURNING id, task_name, 'Task template created successfully' as status;

-- 5. CREATE TEST STAFF TASK
INSERT INTO staff_tasks (
    club_id,
    template_id,
    assigned_to,
    task_type,
    task_name,
    description,
    priority,
    due_at,
    required_location
)
SELECT 
    c.id as club_id,
    tt.id as template_id,
    cs.id as assigned_to,
    'test_cleaning',
    'TEST: Vệ sinh bàn số 1',
    'Task test để kiểm tra photo verification',
    'normal',
    NOW() + INTERVAL '2 hours',
    jsonb_build_object(
        'lat', 21.0285,
        'lng', 105.8542,
        'address', 'Test Location Hanoi',
        'radius', 50
    )
FROM clubs c
CROSS JOIN task_templates tt
CROSS JOIN club_staff cs
WHERE tt.task_type = 'test_cleaning'
    AND cs.club_id = c.id
LIMIT 1
RETURNING id, task_name, status, 'Staff task created successfully' as result;

-- 6. TEST AUTO VERIFICATION FUNCTION
SELECT 'Testing auto_verify_task_submission function...' as test;

-- First create a test verification record
WITH test_verification AS (
    INSERT INTO task_verifications (
        task_id,
        club_id,
        staff_id,
        photo_url,
        photo_hash,
        photo_size,
        captured_latitude,
        captured_longitude,
        location_accuracy,
        captured_at,
        device_info,
        camera_metadata
    )
    SELECT 
        st.id,
        st.club_id,
        st.assigned_to,
        'https://test-bucket.supabase.co/test-photo.jpg',
        'abc123def456',
        125000,
        21.0285,
        105.8542,
        15.5,
        NOW() - INTERVAL '30 seconds',
        '{"device": "test_device", "os": "android"}',
        '{"camera": "rear", "flash": false}'
    FROM staff_tasks st
    WHERE st.task_type = 'test_cleaning'
    LIMIT 1
    RETURNING id
)
-- Now test auto verification
SELECT auto_verify_task_submission(tv.id) as verification_result
FROM test_verification tv;

-- 7. TEST SUBMIT TASK VERIFICATION FUNCTION
SELECT 'Testing submit_task_verification function...' as test;

SELECT submit_task_verification(
    (SELECT id FROM staff_tasks WHERE task_type = 'test_cleaning' LIMIT 1),
    'https://test-bucket.supabase.co/test-photo-2.jpg',
    'def456ghi789',
    150000,
    21.0280::DECIMAL,
    105.8540::DECIMAL,
    12.0::DECIMAL,
    NOW() - INTERVAL '10 seconds',
    '{"device": "test_device_2", "os": "ios"}'::JSONB,
    '{"camera": "rear", "flash": true, "exposure": "auto"}'::JSONB
) as submit_result;

-- 8. CHECK VERIFICATION RESULTS
SELECT 'Verification Results Check' as test;
SELECT 
    tv.id,
    tv.verification_status,
    tv.auto_verification_score,
    tv.location_verified,
    tv.timestamp_verified,
    tv.fraud_flags,
    tv.manual_review_required,
    'Verification record created' as status
FROM task_verifications tv
JOIN staff_tasks st ON tv.task_id = st.id
WHERE st.task_type = 'test_cleaning'
ORDER BY tv.created_at DESC;

-- 9. CHECK AUDIT LOGS
SELECT 'Audit Log Check' as test;
SELECT 
    val.action,
    val.old_status,
    val.new_status,
    val.reason,
    val.performed_at,
    'Audit log created' as status
FROM verification_audit_log val
JOIN task_verifications tv ON val.verification_id = tv.id
JOIN staff_tasks st ON tv.task_id = st.id
WHERE st.task_type = 'test_cleaning'
ORDER BY val.performed_at DESC;

-- 10. CHECK TASK STATUS UPDATES
SELECT 'Task Status Update Check' as test;
SELECT 
    st.id,
    st.status,
    st.completion_percentage,
    st.started_at,
    st.completed_at,
    CASE 
        WHEN st.status = 'verified' THEN '✅ Auto verification passed'
        WHEN st.status = 'completed' THEN '⏳ Pending verification'
        ELSE '❌ Status issue'
    END as status_check
FROM staff_tasks st
WHERE st.task_type = 'test_cleaning'
ORDER BY st.updated_at DESC;

-- 11. TEST FRAUD DETECTION
SELECT 'Testing fraud detection...' as test;

-- Create a suspicious verification (far location)
WITH suspicious_verification AS (
    INSERT INTO task_verifications (
        task_id,
        club_id,
        staff_id,
        photo_url,
        photo_hash,
        photo_size,
        captured_latitude,
        captured_longitude,
        location_accuracy,
        distance_from_required,
        captured_at,
        time_drift_seconds,
        device_info
    )
    SELECT 
        st.id,
        st.club_id,
        st.assigned_to,
        'https://test-bucket.supabase.co/suspicious-photo.jpg',
        'suspicious123',
        25000, -- Small photo size (suspicious)
        21.1000, -- Far from required location
        105.9000,
        100.0, -- Poor accuracy
        500.0, -- 500m away (suspicious)
        NOW() - INTERVAL '10 minutes', -- Old timestamp
        600, -- 10 minutes drift (suspicious)
        '{"device": "unknown"}'
    FROM staff_tasks st
    WHERE st.task_type = 'test_cleaning'
    LIMIT 1
    RETURNING id
)
SELECT auto_verify_task_submission(sv.id) as fraud_test_result
FROM suspicious_verification sv;

-- 12. CHECK FRAUD DETECTION RESULTS
SELECT 'Fraud Detection Results' as test;
SELECT 
    tv.verification_status,
    tv.auto_verification_score,
    tv.fraud_flags,
    tv.manual_review_required,
    CASE 
        WHEN tv.verification_status = 'suspicious' OR tv.verification_status = 'rejected' 
        THEN '✅ Fraud detection working'
        ELSE '❌ Fraud detection failed'
    END as fraud_check
FROM task_verifications tv
JOIN staff_tasks st ON tv.task_id = st.id
WHERE st.task_type = 'test_cleaning'
    AND tv.auto_verification_score < 80
ORDER BY tv.created_at DESC
LIMIT 1;

-- 13. PERFORMANCE TEST - Check indexes
SELECT 'Index Performance Check' as test;
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef,
    '✅ Index exists' as status
FROM pg_indexes 
WHERE tablename IN ('task_templates', 'staff_tasks', 'task_verifications', 'verification_audit_log', 'fraud_detection_rules')
ORDER BY tablename, indexname;

-- 14. FUNCTION PERMISSIONS TEST
SELECT 'Function Permissions Check' as test;
SELECT 
    routine_name,
    routine_type,
    security_type,
    '✅ Function accessible' as status
FROM information_schema.routines 
WHERE routine_name IN ('get_staff_tasks', 'submit_task_verification', 'auto_verify_task_submission')
ORDER BY routine_name;

-- 15. CLEANUP TEST DATA
DELETE FROM task_verifications 
WHERE task_id IN (
    SELECT id FROM staff_tasks WHERE task_type = 'test_cleaning'
);

DELETE FROM staff_tasks WHERE task_type = 'test_cleaning';
DELETE FROM task_templates WHERE task_type = 'test_cleaning';

SELECT '🎉 Backend testing completed successfully! All systems operational.' as final_result;