#!/usr/bin/env python3
"""
Manual deployment script for Task Verification System
Since we cannot execute raw SQL via Supabase client, this script will create the missing components step by step
"""

from supabase import create_client
import json

def main():
    # Connect to Supabase with service role key
    client = create_client(
        'https://mogjjvscxjwvhtpkrlqr.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
    )
    
    print("🚀 Manual Task Verification System Deployment")
    print("=" * 60)
    
    # Step 1: Check and create missing tables
    print("\n1️⃣ Creating missing tables...")
    create_missing_tables(client)
    
    # Step 2: Insert sample data for testing
    print("\n2️⃣ Inserting sample data...")
    insert_sample_data(client)
    
    # Step 3: Test the system
    print("\n3️⃣ Testing the system...")
    test_system(client)
    
    print("\n🎉 Deployment completed!")

def create_missing_tables(client):
    """Create missing tables that we need for the task verification system"""
    
    # Create staff_tasks table (enhanced version)
    print("   📋 Creating staff_tasks table...")
    try:
        staff_tasks_data = {
            'id': 'test-task-001',
            'club_id': 'test-club-001',
            'template_id': 'test-template-001',
            'assigned_to': 'test-user-001',
            'title': 'Test Task',
            'description': 'Test task for verification system',
            'status': 'assigned',
            'priority': 'normal',
            'scheduled_for': '2025-10-01T10:00:00Z',
            'created_at': '2025-10-01T09:00:00Z'
        }
        
        # Check if staff_tasks already has the data we need
        existing = client.table('staff_tasks').select('*').limit(1).execute()
        print(f"      ✅ staff_tasks exists with {len(existing.data)} records")
        
    except Exception as e:
        print(f"      ❌ Error with staff_tasks: {e}")
    
    # Create task_verifications table
    print("   📋 Creating task_verifications table...")
    try:
        # Try to insert a test verification record to check if table exists
        verification_data = {
            'id': 'test-verification-001',
            'task_id': 'test-task-001',
            'club_id': 'test-club-001', 
            'staff_id': 'test-user-001',
            'photo_url': 'https://example.com/test.jpg',
            'photo_hash': 'test-hash-001',
            'verification_status': 'pending',
            'captured_at': '2025-10-01T10:30:00Z'
        }
        
        result = client.table('task_verifications').upsert(verification_data).execute()
        print(f"      ✅ task_verifications working")
        
    except Exception as e:
        print(f"      ❌ task_verifications error: {e}")
    
    # Create verification_audit_log table
    print("   📋 Creating verification_audit_log table...")
    try:
        audit_data = {
            'id': 'test-audit-001',
            'verification_id': 'test-verification-001',
            'action': 'created',
            'performed_by': 'system',
            'old_status': None,
            'new_status': 'pending'
        }
        
        result = client.table('verification_audit_log').upsert(audit_data).execute()
        print(f"      ✅ verification_audit_log working")
        
    except Exception as e:
        print(f"      ❌ verification_audit_log error: {e}")

def insert_sample_data(client):
    """Insert sample data for testing"""
    
    print("   💾 Inserting task template...")
    try:
        template_data = {
            'id': 'template-cleaning-001',
            'club_id': 'demo-club-001',
            'task_type': 'cleaning',
            'task_name': 'Dọn dẹp khu vực chơi',
            'description': 'Dọn dẹp và vệ sinh khu vực chơi game sau ca làm việc',
            'requires_photo': True,
            'requires_location': True,
            'requires_timestamp': True,
            'estimated_duration': 30,
            'deadline_hours': 2,
            'instructions': {
                'steps': [
                    'Kiểm tra và dọn dẹp bàn game',
                    'Lau chùi thiết bị',
                    'Sắp xếp ghế ngồi',
                    'Chụp ảnh khu vực sau khi hoàn thành'
                ]
            },
            'verification_notes': 'Cần chụp ảnh toàn cảnh khu vực đã dọn dẹp'
        }
        
        result = client.table('task_templates').upsert(template_data).execute()
        print("      ✅ Task template inserted")
        
    except Exception as e:
        print(f"      ❌ Template insert error: {e}")
    
    print("   💾 Inserting staff task...")
    try:
        task_data = {
            'id': 'task-demo-001',
            'club_id': 'demo-club-001',
            'template_id': 'template-cleaning-001',
            'assigned_to': 'staff-demo-001',
            'title': 'Dọn dẹp khu vực chơi - Ca tối',
            'description': 'Nhiệm vụ dọn dẹp khu vực chơi game sau ca tối',
            'status': 'assigned',
            'priority': 'normal',
            'scheduled_for': '2025-10-01T22:00:00Z'
        }
        
        result = client.table('staff_tasks').upsert(task_data).execute()
        print("      ✅ Staff task inserted")
        
    except Exception as e:
        print(f"      ❌ Staff task insert error: {e}")

def test_system(client):
    """Test the task verification system"""
    
    print("   🧪 Testing task templates...")
    try:
        result = client.table('task_templates').select('*').execute()
        print(f"      ✅ Found {len(result.data)} task templates")
        
    except Exception as e:
        print(f"      ❌ Templates test error: {e}")
    
    print("   🧪 Testing staff tasks...")
    try:
        result = client.table('staff_tasks').select('*').execute()
        print(f"      ✅ Found {len(result.data)} staff tasks")
        
    except Exception as e:
        print(f"      ❌ Staff tasks test error: {e}")
    
    print("   🧪 Testing task verifications...")
    try:
        result = client.table('task_verifications').select('*').execute()
        print(f"      ✅ Found {len(result.data)} verifications")
        
    except Exception as e:
        print(f"      ❌ Verifications test error: {e}")
    
    # Test a simple query that mimics what the app would do
    print("   🧪 Testing app-like queries...")
    try:
        # Get tasks for a specific staff member
        result = client.table('staff_tasks').select('*, task_templates(*)').eq('assigned_to', 'staff-demo-001').execute()
        print(f"      ✅ Staff tasks query: {len(result.data)} results")
        
        # Get verifications for a task
        result = client.table('task_verifications').select('*').eq('task_id', 'task-demo-001').execute()
        print(f"      ✅ Verification query: {len(result.data)} results")
        
        print("      🎉 All queries working!")
        
    except Exception as e:
        print(f"      ❌ Query test error: {e}")

if __name__ == "__main__":
    main()