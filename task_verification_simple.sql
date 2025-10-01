-- =====================================================
-- TASK VERIFICATION SYSTEM - SIMPLE VERSION
-- Tables only for manual deployment
-- =====================================================

-- 1. Task Templates Table
CREATE TABLE task_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    task_type TEXT NOT NULL,
    task_name TEXT NOT NULL,
    description TEXT NOT NULL,
    requires_photo BOOLEAN DEFAULT true,
    requires_location BOOLEAN DEFAULT true,
    requires_timestamp BOOLEAN DEFAULT true,
    estimated_duration INTEGER,
    deadline_hours INTEGER,
    instructions JSONB DEFAULT '{}',
    verification_notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Staff Tasks Table
CREATE TABLE staff_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    template_id UUID REFERENCES task_templates(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES club_staff(id),
    task_type TEXT NOT NULL,
    task_name TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    assigned_at TIMESTAMP DEFAULT NOW(),
    due_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    status TEXT DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'verified', 'rejected')),
    completion_percentage INTEGER DEFAULT 0,
    required_location JSONB,
    assignment_notes TEXT,
    completion_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Task Verifications Table
CREATE TABLE task_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES staff_tasks(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_hash TEXT NOT NULL,
    photo_size INTEGER,
    photo_mime_type TEXT DEFAULT 'image/jpeg',
    captured_latitude DECIMAL(10,8),
    captured_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    location_verified BOOLEAN DEFAULT false,
    distance_from_required DECIMAL(10,2),
    captured_at TIMESTAMP NOT NULL,
    server_received_at TIMESTAMP DEFAULT NOW(),
    timestamp_verified BOOLEAN DEFAULT false,
    time_drift_seconds INTEGER,
    device_info JSONB DEFAULT '{}',
    camera_metadata JSONB DEFAULT '{}',
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'suspicious')),
    auto_verification_score DECIMAL(3,2),
    manual_review_required BOOLEAN DEFAULT false,
    reviewed_by UUID REFERENCES club_staff(id),
    reviewed_at TIMESTAMP,
    review_notes TEXT,
    rejection_reason TEXT,
    fraud_flags JSONB DEFAULT '{}',
    confidence_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Verification Audit Log Table
CREATE TABLE verification_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_id UUID REFERENCES task_verifications(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    performed_by UUID REFERENCES club_staff(id),
    performed_at TIMESTAMP DEFAULT NOW(),
    old_status TEXT,
    new_status TEXT,
    reason TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 5. Fraud Detection Rules Table
CREATE TABLE fraud_detection_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    rule_name TEXT NOT NULL,
    rule_type TEXT NOT NULL,
    description TEXT,
    parameters JSONB NOT NULL,
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    auto_reject BOOLEAN DEFAULT false,
    require_manual_review BOOLEAN DEFAULT true,
    alert_managers BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_task_templates_club_type ON task_templates(club_id, task_type);
CREATE INDEX idx_staff_tasks_assigned ON staff_tasks(assigned_to, status, due_at);
CREATE INDEX idx_staff_tasks_club_status ON staff_tasks(club_id, status, assigned_at);
CREATE INDEX idx_task_verifications_task ON task_verifications(task_id, verification_status);
CREATE INDEX idx_task_verifications_staff_date ON task_verifications(staff_id, captured_at);
CREATE INDEX idx_verification_audit_verification ON verification_audit_log(verification_id, performed_at);