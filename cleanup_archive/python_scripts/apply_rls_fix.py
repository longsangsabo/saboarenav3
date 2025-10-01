#!/usr/bin/env python3
import os
import subprocess

def apply_rls_fix():
    """Apply RLS policy fixes to Supabase database"""
    
    print("🔧 Applying RLS policy fixes...")
    
    # Read the SQL file
    with open('fix_tournament_rls.sql', 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print("📄 SQL content loaded:")
    print("- Dropping existing restrictive policies")
    print("- Creating public read access for tournament_participants")
    print("- Allowing club managers to manage their tournament participants")
    print("- Adding public read access for users basic info")
    
    print("\n⚠️  To apply these changes:")
    print("1. Copy the SQL content from fix_tournament_rls.sql")
    print("2. Go to Supabase Dashboard > SQL Editor")
    print("3. Paste and run the SQL")
    print("4. Or use supabase CLI: supabase db reset --local")
    
    print("\n🎯 Expected result after applying:")
    print("- Anonymous users can view tournament participants")
    print("- Club managers can manage participants of their tournaments")
    print("- No more service role key needed in client app")
    
    return sql_content

if __name__ == "__main__":
    apply_rls_fix()