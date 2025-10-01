-- Disable RLS for all related tables to ensure smooth testing

-- Shift reporting tables (already disabled)
ALTER TABLE shift_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_inventory DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_reports DISABLE ROW LEVEL SECURITY;

-- Related tables that might be needed
ALTER TABLE clubs DISABLE ROW LEVEL SECURITY;
ALTER TABLE club_staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;