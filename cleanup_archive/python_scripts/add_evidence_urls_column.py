#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Add Evidence URLs Column to Rank Requests Table
Thêm cột evidence_urls vào bảng rank_requests để hỗ trợ upload ảnh bằng chứng
"""

import os
import json
from supabase import create_client, Client

def load_config():
    """Load Supabase configuration"""
    try:
        # Try to load from env.json first
        if os.path.exists('env.json'):
            with open('env.json', 'r') as f:
                config = json.load(f)
                return config.get('supabase_url'), config.get('supabase_service_key')
        
        # Fallback to environment variables
        url = os.getenv('SUPABASE_URL')
        key = os.getenv('SUPABASE_SERVICE_KEY')
        
        if not url or not key:
            print("❌ Missing Supabase configuration")
            print("   Create env.json with supabase_url and supabase_service_key")
            return None, None
            
        return url, key
    except Exception as e:
        print(f"❌ Error loading config: {e}")
        return None, None

def add_evidence_urls_column():
    """Add evidence_urls column to rank_requests table"""
    print("🚀 Adding Evidence URLs Column to Rank Requests")
    print("=" * 50)
    
    url, key = load_config()
    if not url or not key:
        return False
    
    try:
        supabase: Client = create_client(url, key)
        print("✅ Connected to Supabase")
        
        # Read the SQL script
        with open('add_evidence_urls_column.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        print("📄 Loaded SQL script")
        
        # Execute the SQL script
        print("🔄 Adding evidence_urls column...")
        
        try:
            result = supabase.rpc('exec_sql', {'sql_query': sql_script}).execute()
            print("✅ Evidence URLs column added successfully")
            
            # Verify the changes
            print("\n📊 Verifying table structure...")
            verify_sql = """
            SELECT 
                column_name,
                data_type,
                is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'rank_requests' 
            AND column_name = 'evidence_urls';
            """
            
            verify_result = supabase.rpc('exec_sql', {'sql_query': verify_sql}).execute()
            if verify_result.data and len(verify_result.data) > 0:
                print("  ✅ Column 'evidence_urls' confirmed in rank_requests table")
                print(f"  📋 Type: {verify_result.data[0].get('data_type', 'N/A')}")
            else:
                print("  ⚠️  Could not verify column creation")
            
        except Exception as e:
            print(f"❌ Error executing SQL: {e}")
            print("\n📌 You may need to run the SQL manually in Supabase Dashboard:")
            print("   1. Go to Supabase Dashboard > SQL Editor")
            print("   2. Copy content from add_evidence_urls_column.sql")
            print("   3. Paste and click 'Run'")
            return False
        
        print("\n" + "=" * 50)
        print("🎉 EVIDENCE URLS COLUMN SETUP COMPLETED!")
        print("🎯 Users can now upload tournament evidence images")
        print("📱 Rank registration form will support image uploads")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during setup: {e}")
        return False

if __name__ == "__main__":
    add_evidence_urls_column()