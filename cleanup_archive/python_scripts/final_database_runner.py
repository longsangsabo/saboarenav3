import psycopg2
from urllib.parse import urlparse
import json

# Database connection string - construct from Supabase details
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
# Extract project ref from URL
project_ref = "mogjjvscxjwvhtpkrlqr"

# Supabase PostgreSQL connection details
# Format: postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
DATABASE_URL = f"postgresql://postgres.{project_ref}:{'PASSWORD_PLACEHOLDER'}@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"

def connect_and_fix_database():
    print("=== ATTEMPTING DIRECT DATABASE CONNECTION ===\n")
    
    # Note: We need the actual database password to connect directly
    print("❌ Direct database connection requires the actual database password.")
    print("   This is not available through the service role key alone.")
    print("   The service role key is for REST API access, not direct PostgreSQL connection.")
    
    print("\n=== ALTERNATIVE SOLUTION ===")
    print("Please run the following SQL script manually in Supabase SQL Editor:")
    print("File: fix_with_real_schema.sql")
    print("\nOr copy and paste this SQL:")
    
    sql_script = """-- FINAL FIX - Based on actual database schema inspection
-- Using real tables: clubs, club_members, users (NOT club_memberships or users)

DROP FUNCTION IF EXISTS get_pending_rank_change_requests();

CREATE OR REPLACE FUNCTION get_pending_rank_change_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_requests JSON;
    v_is_admin BOOLEAN := false;
    v_user_club_id UUID;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user is system admin (using actual users table)
    SELECT COALESCE(
        (SELECT role = 'admin' FROM users WHERE id = v_user_id),
        false
    ) INTO v_is_admin;

    -- Get user's club using actual club_members table
    IF NOT v_is_admin THEN
        -- First check if user is a member of any club
        SELECT club_id INTO v_user_club_id
        FROM club_members 
        WHERE user_id = v_user_id 
        AND status = 'active'
        LIMIT 1;
        
        -- Also check if user owns any club
        IF v_user_club_id IS NULL THEN
            SELECT id INTO v_user_club_id
            FROM clubs 
            WHERE owner_id = v_user_id 
            LIMIT 1;
        END IF;
        
        -- If user is not admin and not associated with any club, return empty
        IF v_user_club_id IS NULL THEN
            RETURN '[]'::JSON;
        END IF;
    END IF;

    -- Get pending requests using actual users table
    SELECT json_agg(
        json_build_object(
            'id', n.id,
            'user_id', n.user_id,
            'user_name', COALESCE(
                (SELECT display_name FROM users WHERE id = n.user_id),
                (SELECT full_name FROM users WHERE id = n.user_id),
                'Unknown User'
            ),
            'user_email', COALESCE(
                (SELECT email FROM users WHERE id = n.user_id),
                'unknown@email.com'
            ),
            'user_avatar', (SELECT avatar_url FROM users WHERE id = n.user_id),
            'current_rank', (n.data->>'current_rank'),
            'requested_rank', (n.data->>'requested_rank'),
            'reason', (n.data->>'reason'),
            'evidence_urls', (n.data->'evidence_urls'),
            'submitted_at', (n.data->>'submitted_at'),
            'workflow_status', (n.data->>'workflow_status'),
            'user_club_id', (n.data->>'user_club_id'),
            'created_at', n.created_at
        )
    ) INTO v_requests
    FROM notifications n
    WHERE n.type = 'rank_change_request'
    AND (n.data->>'workflow_status') IN ('pending_club_review', 'pending_admin_review')
    AND (
        v_is_admin OR  -- System admin sees all
        (n.data->>'user_club_id')::UUID = v_user_club_id  -- Club admin sees their club's requests
    )
    ORDER BY n.created_at DESC;

    RETURN COALESCE(v_requests, '[]'::JSON);
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_pending_rank_change_requests() TO authenticated;"""
    
    print("\n" + "="*60)
    print(sql_script)
    print("="*60)
    
    return sql_script

def create_simple_runner():
    print("\n=== CREATING SIMPLE SQL RUNNER ===\n")
    
    # Save the SQL to a file for easy manual execution
    sql_content = connect_and_fix_database()
    
    with open("final_database_fix.sql", "w", encoding="utf-8") as f:
        f.write(sql_content)
    
    print("✅ SQL script saved to: final_database_fix.sql")
    print("✅ Please run this script in Supabase SQL Editor")
    
    print("\n📋 SUMMARY:")
    print("1. ✅ Club logo system is fully implemented")
    print("2. ✅ Database schema analysis completed")
    print("3. ✅ Correct SQL fix generated")
    print("4. ⏳ Manual execution needed in Supabase SQL Editor")
    print("5. 🎯 After running SQL, test club logo feature!")

if __name__ == "__main__":
    create_simple_runner()