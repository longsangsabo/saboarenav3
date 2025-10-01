-- Fix RLS Policies - Remove infinite recursion
-- Apply this after the main schema

BEGIN;

-- Drop existing policies that cause recursion
DROP POLICY IF EXISTS "Club owners can manage all shift sessions" ON shift_sessions;
DROP POLICY IF EXISTS "Staff can manage their shift sessions" ON shift_sessions;
DROP POLICY IF EXISTS "Club staff can manage shift data" ON shift_transactions;
DROP POLICY IF EXISTS "Club staff can manage inventory" ON shift_inventory;
DROP POLICY IF EXISTS "Club staff can manage expenses" ON shift_expenses;
DROP POLICY IF EXISTS "Club staff can view reports" ON shift_reports;

-- Create simplified, non-recursive policies

-- Shift sessions - club owners and their staff can access
CREATE POLICY "shift_sessions_access" ON shift_sessions
    FOR ALL USING (
        -- Club owner access
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
        OR
        -- Staff access (direct user match)
        staff_id IN (
            SELECT cs.id FROM club_staff cs 
            WHERE cs.user_id = auth.uid()
        )
    );

-- Shift transactions - access through club ownership or staff assignment
CREATE POLICY "shift_transactions_access" ON shift_transactions
    FOR ALL USING (
        -- Club owner access
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
        OR
        -- Staff access through their sessions
        shift_session_id IN (
            SELECT ss.id FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            WHERE cs.user_id = auth.uid()
        )
    );

-- Shift inventory - same pattern
CREATE POLICY "shift_inventory_access" ON shift_inventory
    FOR ALL USING (
        -- Club owner access
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
        OR
        -- Staff access through their sessions
        shift_session_id IN (
            SELECT ss.id FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            WHERE cs.user_id = auth.uid()
        )
    );

-- Shift expenses - same pattern
CREATE POLICY "shift_expenses_access" ON shift_expenses
    FOR ALL USING (
        -- Club owner access
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
        OR
        -- Staff access through their sessions
        shift_session_id IN (
            SELECT ss.id FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            WHERE cs.user_id = auth.uid()
        )
    );

-- Shift reports - read access for club owners and staff
CREATE POLICY "shift_reports_access" ON shift_reports
    FOR SELECT USING (
        -- Club owner access
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
        OR
        -- Staff access through their sessions
        shift_session_id IN (
            SELECT ss.id FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            WHERE cs.user_id = auth.uid()
        )
    );

-- Allow insert/update for reports by club owners
CREATE POLICY "shift_reports_modify" ON shift_reports
    FOR INSERT WITH CHECK (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    );

CREATE POLICY "shift_reports_update" ON shift_reports
    FOR UPDATE USING (
        club_id IN (
            SELECT id FROM clubs WHERE owner_id = auth.uid()
        )
    );

COMMIT;