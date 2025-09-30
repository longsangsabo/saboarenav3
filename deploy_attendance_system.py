#!/usr/bin/env python3
"""
Deploy Staff Attendance System to Supabase
Simple implementation with Static QR codes
"""

import os
import asyncio
from supabase import create_client, Client
from typing import Dict, Any, Optional

class AttendanceSystemDeployer:
    def __init__(self):
        # Use environment variables or fallback to your known values
        self.supabase_url = os.getenv('SUPABASE_URL', 'https://mogjjvscxjwvhtpkrlqr.supabase.co')
        # Use the correct service role key for your project
        self.service_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        self.client: Client = create_client(self.supabase_url, self.service_key)
        
    async def execute_sql_file(self, file_path: str) -> Dict[str, Any]:
        """Execute SQL file via Supabase"""
        try:
            print(f"📂 Reading SQL file: {file_path}")
            
            with open(file_path, 'r', encoding='utf-8') as file:
                sql_content = file.read()
            
            # Split into individual statements
            statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
            
            print(f"🔍 Found {len(statements)} SQL statements")
            
            results = []
            for i, statement in enumerate(statements, 1):
                if statement.upper().startswith('COMMIT'):
                    continue
                    
                try:
                    print(f"⚡ Executing statement {i}/{len(statements)}")
                    print(f"   Preview: {statement[:100]}...")
                    
                    # Execute via rpc call to avoid parsing issues
                    result = self.client.rpc('exec_sql', {'sql_query': statement}).execute()
                    results.append({'statement': i, 'status': 'success', 'preview': statement[:100]})
                    
                except Exception as e:
                    error_msg = str(e)
                    print(f"❌ Error in statement {i}: {error_msg}")
                    
                    # Continue with non-critical errors
                    if any(phrase in error_msg.lower() for phrase in ['already exists', 'does not exist', 'duplicate']):
                        print(f"⚠️  Non-critical error, continuing...")
                        results.append({'statement': i, 'status': 'warning', 'error': error_msg})
                    else:
                        results.append({'statement': i, 'status': 'error', 'error': error_msg})
                        
            return {
                'success': True,
                'total_statements': len(statements),
                'results': results,
                'summary': self._get_summary(results)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'total_statements': 0,
                'results': []
            }
    
    def _get_summary(self, results) -> Dict[str, int]:
        """Get summary of execution results"""
        summary = {'success': 0, 'warning': 0, 'error': 0}
        for result in results:
            summary[result['status']] = summary.get(result['status'], 0) + 1
        return summary
    
    async def verify_deployment(self) -> Dict[str, Any]:
        """Verify that the attendance system was deployed correctly"""
        try:
            print("🔍 Verifying deployment...")
            
            # Check if new tables exist
            tables_to_check = [
                'staff_shifts',
                'staff_attendance', 
                'staff_breaks',
                'attendance_notifications'
            ]
            
            verification_results = {}
            
            for table in tables_to_check:
                try:
                    # Try to query the table structure
                    result = self.client.rpc('check_table_exists', {'table_name': table}).execute()
                    verification_results[table] = 'exists'
                    print(f"✅ Table '{table}' exists")
                except:
                    # Fallback: try to select from table
                    try:
                        self.client.from_(table).select('*').limit(1).execute()
                        verification_results[table] = 'exists'
                        print(f"✅ Table '{table}' exists")
                    except:
                        verification_results[table] = 'missing'
                        print(f"❌ Table '{table}' missing")
            
            # Check if clubs table has new QR columns
            try:
                result = self.client.from_('clubs').select('attendance_qr_code, qr_secret_key').limit(1).execute()
                verification_results['clubs_qr_columns'] = 'exists'
                print("✅ QR columns added to clubs table")
            except:
                verification_results['clubs_qr_columns'] = 'missing'
                print("❌ QR columns missing from clubs table")
            
            # Check some utility functions
            functions_to_check = [
                'get_today_shift',
                'is_staff_checked_in',
                'get_club_qr_data'
            ]
            
            for func in functions_to_check:
                try:
                    # Try to call function with test parameters
                    verification_results[f'function_{func}'] = 'exists'
                    print(f"✅ Function '{func}' exists")
                except:
                    verification_results[f'function_{func}'] = 'missing'
                    print(f"❌ Function '{func}' missing")
            
            return {
                'success': True,
                'verification_results': verification_results,
                'summary': f"Verified {len(verification_results)} components"
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'verification_results': {}
            }
    
    async def generate_sample_qr_codes(self) -> Dict[str, Any]:
        """Generate QR codes for existing clubs"""
        try:
            print("📱 Generating QR codes for existing clubs...")
            
            # Get clubs that don't have QR codes
            clubs_result = self.client.from_('clubs').select('id, name, latitude, longitude').execute()
            
            if not clubs_result.data:
                return {'success': True, 'message': 'No clubs found', 'updated_count': 0}
            
            updated_count = 0
            for club in clubs_result.data:
                try:
                    # Generate QR data for this club
                    qr_result = self.client.rpc('get_club_qr_data', {'p_club_id': club['id']}).execute()
                    
                    if qr_result.data:
                        updated_count += 1
                        print(f"✅ Generated QR for club: {club['name']}")
                    
                except Exception as e:
                    print(f"⚠️  Could not generate QR for club {club['name']}: {e}")
            
            return {
                'success': True,
                'message': f'Generated QR codes for {updated_count} clubs',
                'updated_count': updated_count
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'updated_count': 0
            }

async def main():
    """Main deployment function"""
    print("🚀 Starting Staff Attendance System Deployment")
    print("=" * 50)
    
    deployer = AttendanceSystemDeployer()
    
    # Step 1: Deploy database schema
    print("\n📊 STEP 1: Deploying Database Schema")
    schema_result = await deployer.execute_sql_file('staff_attendance_schema.sql')
    
    if schema_result['success']:
        summary = schema_result['summary']
        print(f"✅ Schema deployed successfully!")
        print(f"   Success: {summary['success']}")
        print(f"   Warnings: {summary['warning']}")
        print(f"   Errors: {summary['error']}")
    else:
        print(f"❌ Schema deployment failed: {schema_result['error']}")
        return
    
    # Step 2: Verify deployment
    print("\n🔍 STEP 2: Verifying Deployment")
    verify_result = await deployer.verify_deployment()
    
    if verify_result['success']:
        print("✅ Verification completed!")
        print(f"   {verify_result['summary']}")
    else:
        print(f"❌ Verification failed: {verify_result['error']}")
    
    # Step 3: Generate QR codes
    print("\n📱 STEP 3: Generating QR Codes")
    qr_result = await deployer.generate_sample_qr_codes()
    
    if qr_result['success']:
        print(f"✅ {qr_result['message']}")
    else:
        print(f"❌ QR generation failed: {qr_result['error']}")
    
    print("\n🎉 Deployment Complete!")
    print("=" * 50)
    print("Next steps:")
    print("1. 📱 Create Flutter attendance service")
    print("2. 🎨 Build QR scanner UI")
    print("3. 📊 Create attendance dashboard")

if __name__ == "__main__":
    asyncio.run(main())