-- =============================================
-- STAFF ATTENDANCE SYSTEM - DATABASE SCHEMA  
-- Version: 1.0 - Simple Static QR Implementation
-- =============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. Add QR columns to existing clubs table
ALTER TABLE clubs 
ADD COLUMN IF NOT EXISTS attendance_qr_code TEXT,
ADD COLUMN IF NOT EXISTS qr_secret_key TEXT,
ADD COLUMN IF NOT EXISTS qr_created_at TIMESTAMP DEFAULT NOW();

-- 2. Staff shifts table
CREATE TABLE IF NOT EXISTS staff_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
    
    -- Shift scheduling
    shift_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    
    -- Status tracking
    shift_status TEXT DEFAULT 'scheduled' CHECK (shift_status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    
    -- Performance metrics
    overtime_hours NUMERIC DEFAULT 0,
    total_scheduled_hours NUMERIC GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (scheduled_end_time - scheduled_start_time)) / 3600
    ) STORED,
    
    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    
    -- Constraints
    UNIQUE(staff_id, shift_date),
    CHECK (scheduled_end_time > scheduled_start_time)
);

-- 3. Staff attendance table (actual check-in/out records)
CREATE TABLE IF NOT EXISTS staff_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES staff_shifts(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Check-in data
    check_in_time TIMESTAMP NOT NULL DEFAULT NOW(),
    check_in_method TEXT DEFAULT 'qr_code' CHECK (check_in_method IN ('qr_code', 'manual', 'emergency')),
    check_in_location GEOGRAPHY(POINT),
    check_in_device_info JSONB,
    
    -- Check-out data
    check_out_time TIMESTAMP,
    check_out_method TEXT CHECK (check_out_method IN ('qr_code', 'manual', 'emergency')),
    check_out_location GEOGRAPHY(POINT),
    check_out_device_info JSONB,
    
    -- Calculated fields
    total_hours_worked NUMERIC,
    late_minutes INTEGER DEFAULT 0,
    early_departure_minutes INTEGER DEFAULT 0,
    
    -- Status
    attendance_status TEXT DEFAULT 'checked_in' CHECK (attendance_status IN ('checked_in', 'checked_out', 'incomplete')),
    
    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CHECK (check_out_time IS NULL OR check_out_time > check_in_time)
);

-- 4. Staff breaks table (optional breaks during shift)
CREATE TABLE IF NOT EXISTS staff_breaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_id UUID NOT NULL REFERENCES staff_attendance(id) ON DELETE CASCADE,
    
    -- Break timing
    break_start TIMESTAMP NOT NULL DEFAULT NOW(),
    break_end TIMESTAMP,
    break_duration_minutes INTEGER,
    
    -- Break type
    break_type TEXT DEFAULT 'rest' CHECK (break_type IN ('lunch', 'rest', 'emergency', 'other')),
    break_reason TEXT,
    
    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CHECK (break_end IS NULL OR break_end > break_start)
);

-- 5. Attendance notifications table
CREATE TABLE IF NOT EXISTS attendance_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id),
    
    -- Notification content
    notification_type TEXT NOT NULL CHECK (notification_type IN ('late_arrival', 'early_departure', 'shift_reminder', 'missing_checkout', 'overtime_alert')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    
    -- Status
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP DEFAULT NOW(),
    read_at TIMESTAMP,
    
    -- Additional data
    metadata JSONB
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Staff shifts indexes
CREATE INDEX IF NOT EXISTS idx_staff_shifts_club_date ON staff_shifts(club_id, shift_date);
CREATE INDEX IF NOT EXISTS idx_staff_shifts_staff_date ON staff_shifts(staff_id, shift_date);
CREATE INDEX IF NOT EXISTS idx_staff_shifts_status ON staff_shifts(shift_status);

-- Staff attendance indexes
CREATE INDEX IF NOT EXISTS idx_staff_attendance_shift ON staff_attendance(shift_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_staff_date ON staff_attendance(staff_id, DATE(check_in_time));
CREATE INDEX IF NOT EXISTS idx_staff_attendance_club_date ON staff_attendance(club_id, DATE(check_in_time));
CREATE INDEX IF NOT EXISTS idx_staff_attendance_status ON staff_attendance(attendance_status);

-- Staff breaks indexes
CREATE INDEX IF NOT EXISTS idx_staff_breaks_attendance ON staff_breaks(attendance_id);
CREATE INDEX IF NOT EXISTS idx_staff_breaks_start_time ON staff_breaks(break_start);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_attendance_notifications_recipient ON attendance_notifications(recipient_id, is_read);
CREATE INDEX IF NOT EXISTS idx_attendance_notifications_club ON attendance_notifications(club_id, sent_at);

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE staff_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_breaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_notifications ENABLE ROW LEVEL SECURITY;

-- Staff shifts policies
CREATE POLICY "Club owners can manage all shifts" ON staff_shifts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = staff_shifts.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can view their own shifts" ON staff_shifts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM club_staff cs
            JOIN users u ON u.id = cs.user_id
            WHERE cs.id = staff_shifts.staff_id
            AND u.id = auth.uid()
        )
    );

-- Staff attendance policies  
CREATE POLICY "Club owners can manage all attendance" ON staff_attendance
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM clubs
            WHERE clubs.id = staff_attendance.club_id
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can manage their own attendance" ON staff_attendance
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM club_staff cs
            JOIN users u ON u.id = cs.user_id  
            WHERE cs.id = staff_attendance.staff_id
            AND u.id = auth.uid()
        )
    );

-- Staff breaks policies
CREATE POLICY "Users can manage breaks for their attendance" ON staff_breaks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM staff_attendance sa
            JOIN club_staff cs ON cs.id = sa.staff_id
            JOIN users u ON u.id = cs.user_id
            WHERE sa.id = staff_breaks.attendance_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM staff_attendance sa
            JOIN clubs c ON c.id = sa.club_id
            WHERE sa.id = staff_breaks.attendance_id
            AND c.owner_id = auth.uid()
        )
    );

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON attendance_notifications
    FOR SELECT USING (recipient_id = auth.uid());

CREATE POLICY "Club owners can send notifications" ON attendance_notifications
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM clubs
            WHERE clubs.id = attendance_notifications.club_id
            AND clubs.owner_id = auth.uid()
        )
    );

-- =============================================
-- TRIGGER FUNCTIONS
-- =============================================

-- Function to calculate late arrival
CREATE OR REPLACE FUNCTION calculate_late_arrival()
RETURNS TRIGGER AS $$
DECLARE
    scheduled_start TIME;
    actual_start TIME;
    late_mins INTEGER;
BEGIN
    -- Get scheduled start time
    SELECT scheduled_start_time INTO scheduled_start
    FROM staff_shifts 
    WHERE id = NEW.shift_id;
    
    -- Calculate late minutes
    actual_start := NEW.check_in_time::TIME;
    late_mins := GREATEST(0, EXTRACT(EPOCH FROM (actual_start - scheduled_start)) / 60);
    
    NEW.late_minutes := late_mins;
    
    -- Send notification if late > 5 minutes
    IF late_mins > 5 THEN
        INSERT INTO attendance_notifications (
            club_id, staff_id, recipient_id, notification_type, title, message
        ) VALUES (
            NEW.club_id,
            NEW.staff_id,
            (SELECT owner_id FROM clubs WHERE id = NEW.club_id),
            'late_arrival',
            'Nhân viên đi muộn',
            (SELECT u.full_name FROM users u 
             JOIN club_staff cs ON cs.user_id = u.id 
             WHERE cs.id = NEW.staff_id) || ' đã đi muộn ' || late_mins || ' phút'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate work hours on checkout
CREATE OR REPLACE FUNCTION calculate_work_hours()
RETURNS TRIGGER AS $$
DECLARE
    total_hours NUMERIC;
    break_time NUMERIC := 0;
    scheduled_end TIME;
    actual_end TIME;
    early_mins INTEGER;
BEGIN
    -- Only calculate when check_out_time is set
    IF NEW.check_out_time IS NOT NULL AND OLD.check_out_time IS NULL THEN
        
        -- Calculate total hours
        total_hours := EXTRACT(EPOCH FROM (NEW.check_out_time - NEW.check_in_time)) / 3600.0;
        
        -- Subtract break time
        SELECT COALESCE(SUM(break_duration_minutes), 0) / 60.0
        INTO break_time
        FROM staff_breaks 
        WHERE attendance_id = NEW.id;
        
        total_hours := total_hours - break_time;
        NEW.total_hours_worked := GREATEST(0, total_hours);
        
        -- Calculate early departure
        SELECT scheduled_end_time INTO scheduled_end
        FROM staff_shifts 
        WHERE id = NEW.shift_id;
        
        actual_end := NEW.check_out_time::TIME;
        early_mins := GREATEST(0, EXTRACT(EPOCH FROM (scheduled_end - actual_end)) / 60);
        NEW.early_departure_minutes := early_mins;
        
        -- Update attendance status
        NEW.attendance_status := 'checked_out';
        
        -- Update shift status and overtime
        UPDATE staff_shifts 
        SET shift_status = 'completed',
            overtime_hours = GREATEST(0, total_hours - total_scheduled_hours)
        WHERE id = NEW.shift_id;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate break duration
CREATE OR REPLACE FUNCTION calculate_break_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.break_end IS NOT NULL AND OLD.break_end IS NULL THEN
        NEW.break_duration_minutes := EXTRACT(EPOCH FROM (NEW.break_end - NEW.break_start)) / 60;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS
-- =============================================

-- Late arrival calculation trigger
CREATE TRIGGER trigger_calculate_late_arrival
    BEFORE INSERT ON staff_attendance
    FOR EACH ROW
    EXECUTE FUNCTION calculate_late_arrival();

-- Work hours calculation trigger
CREATE TRIGGER trigger_calculate_work_hours
    BEFORE UPDATE ON staff_attendance
    FOR EACH ROW
    EXECUTE FUNCTION calculate_work_hours();

-- Break duration calculation trigger
CREATE TRIGGER trigger_calculate_break_duration
    BEFORE UPDATE ON staff_breaks
    FOR EACH ROW
    EXECUTE FUNCTION calculate_break_duration();

-- Updated at triggers
CREATE TRIGGER trigger_staff_shifts_updated_at
    BEFORE UPDATE ON staff_shifts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_staff_attendance_updated_at
    BEFORE UPDATE ON staff_attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- INITIAL QR CODE SETUP FOR EXISTING CLUBS
-- =============================================

-- Generate QR codes for existing clubs that don't have them
UPDATE clubs 
SET 
    attendance_qr_code = 'SABO_ATTENDANCE_' || id || '_' || EXTRACT(EPOCH FROM NOW())::TEXT,
    qr_secret_key = gen_random_uuid()::TEXT,
    qr_created_at = NOW()
WHERE attendance_qr_code IS NULL OR qr_secret_key IS NULL;

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

-- Function to get today's shift for a staff member
CREATE OR REPLACE FUNCTION get_today_shift(p_staff_id UUID)
RETURNS TABLE (
    shift_id UUID,
    shift_date DATE,
    scheduled_start_time TIME,
    scheduled_end_time TIME,
    shift_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT ss.id, ss.shift_date, ss.scheduled_start_time, ss.scheduled_end_time, ss.shift_status
    FROM staff_shifts ss
    WHERE ss.staff_id = p_staff_id 
    AND ss.shift_date = CURRENT_DATE
    AND ss.shift_status IN ('scheduled', 'in_progress')
    ORDER BY ss.scheduled_start_time
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to check if staff is currently checked in
CREATE OR REPLACE FUNCTION is_staff_checked_in(p_staff_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    attendance_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO attendance_count
    FROM staff_attendance
    WHERE staff_id = p_staff_id
    AND DATE(check_in_time) = CURRENT_DATE
    AND attendance_status = 'checked_in';
    
    RETURN attendance_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to get club's QR code data
CREATE OR REPLACE FUNCTION get_club_qr_data(p_club_id UUID)
RETURNS JSONB AS $$
DECLARE
    club_data RECORD;
    qr_content JSONB;
BEGIN
    SELECT id, name, latitude, longitude, attendance_qr_code, qr_secret_key
    INTO club_data
    FROM clubs
    WHERE id = p_club_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Club not found';
    END IF;
    
    qr_content := jsonb_build_object(
        'type', 'attendance',
        'club_id', club_data.id,
        'club_name', club_data.name,
        'location', jsonb_build_object(
            'lat', club_data.latitude,
            'lng', club_data.longitude
        ),
        'secret', club_data.qr_secret_key,
        'created_at', extract(epoch from now())
    );
    
    RETURN qr_content;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- SAMPLE DATA INSERTION (Optional)
-- =============================================

-- This will be uncommented when we want to add test data
/*
-- Insert sample shift for testing
INSERT INTO staff_shifts (club_id, staff_id, shift_date, scheduled_start_time, scheduled_end_time, created_by)
SELECT 
    c.id,
    cs.id,
    CURRENT_DATE,
    '09:00:00'::TIME,
    '17:00:00'::TIME,
    c.owner_id
FROM clubs c
JOIN club_staff cs ON cs.club_id = c.id
WHERE cs.is_active = true
LIMIT 1;
*/

COMMIT;