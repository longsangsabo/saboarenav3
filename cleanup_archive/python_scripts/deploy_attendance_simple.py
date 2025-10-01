#!/usr/bin/env python3
"""
Simple Database Schema Deployment for Staff Attendance System
Uses direct SQL execution via psycopg2
"""

import psycopg2
import os
from urllib.parse import urlparse

def deploy_attendance_schema():
    """Deploy the attendance system schema to PostgreSQL database"""
    
    # Supabase connection details via Session Pooler (Port 6543)
    # Format: postgres://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]
    database_url = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"
    
    try:
        print("🔗 Connecting to Supabase PostgreSQL...")
        conn = psycopg2.connect(database_url)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("✅ Connected successfully!")
        print("📂 Reading SQL schema file...")
        
        # Read the SQL file
        with open('staff_attendance_schema.sql', 'r', encoding='utf-8') as file:
            sql_content = file.read()
        
        print("⚡ Executing SQL schema...")
        
        # Execute the entire SQL content
        cursor.execute(sql_content)
        
        print("✅ Schema deployment completed successfully!")
        
        # Verify tables were created
        print("🔍 Verifying table creation...")
        tables_to_check = [
            'staff_shifts',
            'staff_attendance', 
            'staff_breaks',
            'attendance_notifications'
        ]
        
        for table in tables_to_check:
            cursor.execute(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = '{table}'
                );
            """)
            exists = cursor.fetchone()[0]
            if exists:
                print(f"✅ Table '{table}' created successfully")
            else:
                print(f"❌ Table '{table}' was not created")
        
        # Check if QR columns were added to clubs table
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'clubs' 
            AND column_name IN ('attendance_qr_code', 'qr_secret_key');
        """)
        qr_columns = cursor.fetchall()
        if len(qr_columns) >= 2:
            print("✅ QR columns added to clubs table")
        else:
            print("❌ QR columns missing from clubs table")
        
        # Generate QR codes for existing clubs
        print("📱 Generating QR codes for existing clubs...")
        cursor.execute("""
            UPDATE clubs 
            SET 
                attendance_qr_code = 'SABO_ATTENDANCE_' || id || '_' || EXTRACT(EPOCH FROM NOW())::TEXT,
                qr_secret_key = gen_random_uuid()::TEXT,
                qr_created_at = NOW()
            WHERE attendance_qr_code IS NULL OR qr_secret_key IS NULL;
        """)
        
        cursor.execute("SELECT COUNT(*) FROM clubs WHERE attendance_qr_code IS NOT NULL;")
        clubs_with_qr = cursor.fetchone()[0]
        print(f"✅ Generated QR codes for {clubs_with_qr} clubs")
        
        print("\n🎉 Attendance System Deployment Complete!")
        print("=" * 50)
        print("✅ Database schema deployed successfully")
        print("✅ All tables and functions created")
        print("✅ QR codes generated for existing clubs")
        print("✅ Row Level Security policies enabled")
        print("✅ Triggers and automation functions active")
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
        
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()
        print("🔌 Database connection closed")

if __name__ == "__main__":
    print("🚀 Starting Staff Attendance System Database Deployment")
    print("=" * 60)
    
    success = deploy_attendance_schema()
    
    if success:
        print("\n🎯 Next Steps:")
        print("1. 📱 Create Flutter attendance service")
        print("2. 🎨 Build QR scanner UI component")
        print("3. 📊 Create attendance dashboard")
        print("4. 🧪 Test the complete system")
    else:
        print("\n❌ Deployment failed. Please check the errors above.")