-- =====================================================
-- TASK VERIFICATION SYSTEM - DEPLOY TO SUPABASE
-- Copy toàn bộ nội dung này và paste vào Supabase SQL Editor
-- =====================================================

-- 1. Create task_templates table
CREATE TABLE IF NOT EXISTS task_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    task_type VARCHAR(50) NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requires_photo BOOLEAN DEFAULT true,
    requires_location BOOLEAN DEFAULT true,
    requires_timestamp BOOLEAN DEFAULT true,
    estimated_duration INTEGER, -- minutes
    deadline_hours INTEGER,
    instructions JSONB DEFAULT '{}',
    verification_notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create staff_tasks table
CREATE TABLE IF NOT EXISTS staff_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES task_templates(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES club_staff(id) ON DELETE SET NULL,
    task_type VARCHAR(50) NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'verified', 'rejected')),
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    required_location JSONB, -- {lat, lng, address, radius}
    assignment_notes TEXT,
    completion_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create task_verifications table
CREATE TABLE IF NOT EXISTS task_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES staff_tasks(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_hash VARCHAR(64) NOT NULL, -- SHA-256 hash
    photo_size INTEGER,
    photo_mime_type VARCHAR(50) DEFAULT 'image/jpeg',
    captured_latitude DECIMAL(10, 8),
    captured_longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(10, 2),
    location_verified BOOLEAN DEFAULT false,
    distance_from_required DECIMAL(10, 2), -- meters
    captured_at TIMESTAMP WITH TIME ZONE NOT NULL,
    server_received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    timestamp_verified BOOLEAN DEFAULT false,
    time_drift_seconds INTEGER,
    device_info JSONB DEFAULT '{}',
    camera_metadata JSONB DEFAULT '{}',
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'suspicious')),
    auto_verification_score DECIMAL(5, 2),
    manual_review_required BOOLEAN DEFAULT false,
    reviewed_by UUID REFERENCES club_staff(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    rejection_reason TEXT,
    fraud_flags JSONB DEFAULT '{}',
    confidence_score DECIMAL(5, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create verification_audit_log table
CREATE TABLE IF NOT EXISTS verification_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_id UUID NOT NULL REFERENCES task_verifications(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    performed_by UUID REFERENCES club_staff(id) ON DELETE SET NULL,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    reason TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create fraud_detection_rules table
CREATE TABLE IF NOT EXISTS fraud_detection_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    rule_name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    parameters JSONB NOT NULL DEFAULT '{}',
    weight DECIMAL(5, 2) DEFAULT 1.00,
    threshold DECIMAL(5, 2),
    action VARCHAR(50) DEFAULT 'flag' CHECK (action IN ('flag', 'reject', 'require_review')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Task templates indexes
CREATE INDEX IF NOT EXISTS idx_task_templates_club_id ON task_templates(club_id);
CREATE INDEX IF NOT EXISTS idx_task_templates_active ON task_templates(is_active) WHERE is_active = true;

-- Staff tasks indexes
CREATE INDEX IF NOT EXISTS idx_staff_tasks_club_id ON staff_tasks(club_id);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_assigned_to ON staff_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_status ON staff_tasks(status);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_due_at ON staff_tasks(due_at);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_priority ON staff_tasks(priority);

-- Task verifications indexes
CREATE INDEX IF NOT EXISTS idx_task_verifications_task_id ON task_verifications(task_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_club_id ON task_verifications(club_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_staff_id ON task_verifications(staff_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_status ON task_verifications(verification_status);
CREATE INDEX IF NOT EXISTS idx_task_verifications_captured_at ON task_verifications(captured_at);
CREATE INDEX IF NOT EXISTS idx_task_verifications_manual_review ON task_verifications(manual_review_required) WHERE manual_review_required = true;

-- Audit log indexes
CREATE INDEX IF NOT EXISTS idx_verification_audit_log_verification_id ON verification_audit_log(verification_id);
CREATE INDEX IF NOT EXISTS idx_verification_audit_log_performed_at ON verification_audit_log(performed_at);

-- Fraud detection rules indexes
CREATE INDEX IF NOT EXISTS idx_fraud_detection_rules_club_id ON fraud_detection_rules(club_id);
CREATE INDEX IF NOT EXISTS idx_fraud_detection_rules_active ON fraud_detection_rules(is_active) WHERE is_active = true;

-- =====================================================
-- UPDATE TRIGGERS
-- =====================================================

-- Update trigger for task_templates
CREATE OR REPLACE FUNCTION update_task_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_templates_updated_at
    BEFORE UPDATE ON task_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_task_templates_updated_at();

-- Update trigger for staff_tasks
CREATE OR REPLACE FUNCTION update_staff_tasks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_staff_tasks_updated_at
    BEFORE UPDATE ON staff_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_staff_tasks_updated_at();

-- Update trigger for task_verifications
CREATE OR REPLACE FUNCTION update_task_verifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_verifications_updated_at
    BEFORE UPDATE ON task_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_task_verifications_updated_at();

-- Update trigger for fraud_detection_rules
CREATE OR REPLACE FUNCTION update_fraud_detection_rules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fraud_detection_rules_updated_at
    BEFORE UPDATE ON fraud_detection_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_fraud_detection_rules_updated_at();

-- =====================================================
-- AUTOMATED VERIFICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION auto_verify_task_submission(
    p_verification_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_verification task_verifications%ROWTYPE;
    v_task staff_tasks%ROWTYPE;
    v_rules fraud_detection_rules%ROWTYPE;
    v_score DECIMAL(5, 2) := 0;
    v_flags JSONB := '{}';
    v_result JSONB;
    v_manual_review BOOLEAN := false;
    v_final_status VARCHAR(20) := 'verified';
BEGIN
    -- Get verification record
    SELECT * INTO v_verification FROM task_verifications WHERE id = p_verification_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Verification not found');
    END IF;

    -- Get task record
    SELECT * INTO v_task FROM staff_tasks WHERE id = v_verification.task_id;

    -- Start verification scoring
    v_score := 100.0;

    -- Check location accuracy
    IF v_verification.location_accuracy IS NOT NULL AND v_verification.location_accuracy > 50 THEN
        v_score := v_score - 20;
        v_flags := v_flags || jsonb_build_object('poor_location_accuracy', true);
    END IF;

    -- Check distance from required location
    IF v_verification.distance_from_required IS NOT NULL AND v_verification.distance_from_required > 100 THEN
        v_score := v_score - 30;
        v_flags := v_flags || jsonb_build_object('location_mismatch', true);
    END IF;

    -- Check timestamp drift
    IF v_verification.time_drift_seconds IS NOT NULL AND ABS(v_verification.time_drift_seconds) > 300 THEN
        v_score := v_score - 25;
        v_flags := v_flags || jsonb_build_object('timestamp_suspicious', true);
    END IF;

    -- Check photo size (too small might be suspicious)
    IF v_verification.photo_size IS NOT NULL AND v_verification.photo_size < 50000 THEN
        v_score := v_score - 15;
        v_flags := v_flags || jsonb_build_object('small_photo_size', true);
    END IF;

    -- Determine final status
    IF v_score < 60 THEN
        v_final_status := 'rejected';
        v_manual_review := true;
    ELSIF v_score < 80 THEN
        v_final_status := 'suspicious';
        v_manual_review := true;
    END IF;

    -- Update verification record
    UPDATE task_verifications 
    SET 
        auto_verification_score = v_score,
        fraud_flags = v_flags,
        verification_status = v_final_status,
        manual_review_required = v_manual_review,
        location_verified = (v_verification.distance_from_required IS NULL OR v_verification.distance_from_required <= 100),
        timestamp_verified = (v_verification.time_drift_seconds IS NULL OR ABS(v_verification.time_drift_seconds) <= 300),
        updated_at = NOW()
    WHERE id = p_verification_id;

    -- Update task status if verification passed
    IF v_final_status = 'verified' THEN
        UPDATE staff_tasks 
        SET 
            status = 'verified',
            completed_at = COALESCE(completed_at, NOW()),
            completion_percentage = 100,
            updated_at = NOW()
        WHERE id = v_verification.task_id;
    END IF;

    -- Log the action
    INSERT INTO verification_audit_log (
        verification_id,
        action,
        performed_by,
        old_status,
        new_status,
        reason
    ) VALUES (
        p_verification_id,
        'auto_verified',
        NULL,
        'pending',
        v_final_status,
        format('Auto verification completed with score: %s', v_score)
    );

    -- Return result
    v_result := jsonb_build_object(
        'verification_id', p_verification_id,
        'status', v_final_status,
        'score', v_score,
        'flags', v_flags,
        'manual_review_required', v_manual_review
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TASK PROGRESSION TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION handle_task_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-set completion timestamp when status changes to completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = COALESCE(NEW.completed_at, NOW());
        NEW.completion_percentage = 100;
    END IF;

    -- Auto-set started timestamp when status changes to in_progress
    IF NEW.status = 'in_progress' AND OLD.status != 'in_progress' THEN
        NEW.started_at = COALESCE(NEW.started_at, NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_handle_task_status_change
    BEFORE UPDATE ON staff_tasks
    FOR EACH ROW
    EXECUTE FUNCTION handle_task_status_change();

-- =====================================================
-- RPC FUNCTIONS FOR FLUTTER
-- =====================================================

-- Get staff tasks with filtering
CREATE OR REPLACE FUNCTION get_staff_tasks(
    p_club_id UUID,
    p_staff_id UUID DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    club_id UUID,
    template_id UUID,
    assigned_to UUID,
    assigned_by UUID,
    task_type VARCHAR,
    task_name VARCHAR,
    description TEXT,
    priority VARCHAR,
    assigned_at TIMESTAMP WITH TIME ZONE,
    due_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR,
    completion_percentage INTEGER,
    required_location JSONB,
    assignment_notes TEXT,
    completion_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    staff_name TEXT,
    verification_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        st.id,
        st.club_id,
        st.template_id,
        st.assigned_to,
        st.assigned_by,
        st.task_type,
        st.task_name,
        st.description,
        st.priority,
        st.assigned_at,
        st.due_at,
        st.started_at,
        st.completed_at,
        st.status,
        st.completion_percentage,
        st.required_location,
        st.assignment_notes,
        st.completion_notes,
        st.created_at,
        st.updated_at,
        COALESCE(cs.full_name, cs.name, 'Unknown') as staff_name,
        COALESCE(tv.verification_status, 'none') as verification_status
    FROM staff_tasks st
    LEFT JOIN club_staff cs ON st.assigned_to = cs.id
    LEFT JOIN task_verifications tv ON st.id = tv.task_id
    WHERE st.club_id = p_club_id
        AND (p_staff_id IS NULL OR st.assigned_to = p_staff_id)
        AND (p_status IS NULL OR st.status = p_status)
    ORDER BY st.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Submit task verification
CREATE OR REPLACE FUNCTION submit_task_verification(
    p_task_id UUID,
    p_photo_url TEXT,
    p_photo_hash VARCHAR,
    p_photo_size INTEGER,
    p_captured_latitude DECIMAL,
    p_captured_longitude DECIMAL,
    p_location_accuracy DECIMAL,
    p_captured_at TIMESTAMP WITH TIME ZONE,
    p_device_info JSONB,
    p_camera_metadata JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_task staff_tasks%ROWTYPE;
    v_verification_id UUID;
    v_verification_result JSONB;
    v_distance DECIMAL;
BEGIN
    -- Get task
    SELECT * INTO v_task FROM staff_tasks WHERE id = p_task_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Task not found');
    END IF;

    -- Calculate distance if required location exists
    IF v_task.required_location IS NOT NULL THEN
        SELECT ST_Distance(
            ST_GeogFromText(format('POINT(%s %s)', 
                (v_task.required_location->>'lng')::DECIMAL,
                (v_task.required_location->>'lat')::DECIMAL
            )),
            ST_GeogFromText(format('POINT(%s %s)', p_captured_longitude, p_captured_latitude))
        ) INTO v_distance;
    END IF;

    -- Insert verification record
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
        device_info,
        camera_metadata
    ) VALUES (
        p_task_id,
        v_task.club_id,
        v_task.assigned_to,
        p_photo_url,
        p_photo_hash,
        p_photo_size,
        p_captured_latitude,
        p_captured_longitude,
        p_location_accuracy,
        v_distance,
        p_captured_at,
        EXTRACT(EPOCH FROM (NOW() - p_captured_at))::INTEGER,
        p_device_info,
        p_camera_metadata
    ) RETURNING id INTO v_verification_id;

    -- Update task status
    UPDATE staff_tasks 
    SET 
        status = 'completed',
        completed_at = NOW(),
        completion_percentage = 100,
        updated_at = NOW()
    WHERE id = p_task_id;

    -- Run auto verification
    SELECT auto_verify_task_submission(v_verification_id) INTO v_verification_result;

    RETURN jsonb_build_object(
        'success', true,
        'verification_id', v_verification_id,
        'verification_result', v_verification_result
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- INSERT SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Sample task templates
INSERT INTO task_templates (club_id, task_type, task_name, description, estimated_duration, deadline_hours) 
SELECT 
    c.id,
    'cleaning',
    'Dọn dẹp khu vực chơi',
    'Dọn dẹp và sắp xếp lại các bàn bi-a, kiểm tra thiết bị',
    30,
    4
FROM clubs c 
WHERE NOT EXISTS (SELECT 1 FROM task_templates WHERE task_type = 'cleaning')
LIMIT 1;

INSERT INTO task_templates (club_id, task_type, task_name, description, estimated_duration, deadline_hours)
SELECT 
    c.id,
    'maintenance',
    'Kiểm tra thiết bị',
    'Kiểm tra tình trạng các bàn bi-a và thiết bị phụ trợ',
    45,
    8
FROM clubs c 
WHERE NOT EXISTS (SELECT 1 FROM task_templates WHERE task_type = 'maintenance')
LIMIT 1;

-- Sample fraud detection rules
INSERT INTO fraud_detection_rules (club_id, rule_name, rule_type, parameters, weight, threshold, action)
SELECT 
    c.id,
    'Location Distance Check',
    'location_validation',
    '{"max_distance_meters": 100}',
    1.5,
    0.8,
    'require_review'
FROM clubs c 
WHERE NOT EXISTS (SELECT 1 FROM fraud_detection_rules WHERE rule_type = 'location_validation')
LIMIT 1;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE ON task_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON staff_tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE ON task_verifications TO authenticated;
GRANT SELECT, INSERT ON verification_audit_log TO authenticated;
GRANT SELECT ON fraud_detection_rules TO authenticated;

-- Grant sequence permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- DEPLOYMENT COMPLETE
-- =====================================================

SELECT 'Task Verification System deployed successfully!' as result;