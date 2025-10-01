"""
Clear SABO tournament data and prepare for correct SABO DE16 testing
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print("🔧 FIXING SABO DE16 LOGIC")
print("=" * 40)
print()

print("❌ PROBLEM IDENTIFIED:")
print("   • SABO DE16 creating 31 matches instead of 27")
print("   • Wrong logic: sabo_de16 routed to CompleteDoubleEliminationService")
print("   • Should route to _generateSaboDE16Bracket instead")
print()

print("✅ LOGIC FIXED:")
print("   • Moved sabo_de16 check BEFORE double_elimination check")
print("   • sabo_de16 → _generateSaboDE16Bracket (27 matches)")
print("   • double_elimination → _generateDE16Bracket (31 matches)")
print()

print("🧹 CLEARING TOURNAMENT DATA...")
try:
    # Find SABO tournaments and clear their matches
    tournaments = supabase.table('tournaments').select('*').ilike('name', '%sabo%').execute()
    
    if tournaments.data:
        for tournament in tournaments.data:
            tournament_id = tournament['id']
            tournament_name = tournament['name']
            
            # Clear matches
            result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
            cleared_count = len(result.data) if result.data else 0
            
            print(f"   • {tournament_name}: Cleared {cleared_count} matches")
            
        print()
        print("✅ TOURNAMENT DATA CLEARED")
        print()
        print("🚀 READY TO TEST:")
        print("   1. Hot reload Flutter app (press 'R' in terminal)")
        print("   2. Create new SABO DE16 tournament")
        print("   3. Should create 27 matches (not 31)")
        print("   4. Verify SABO structure: WB(14) + LA(7) + LB(3) + Finals(3)")
        
    else:
        print("   No SABO tournaments found")
        
except Exception as e:
    print(f"Error: {e}")