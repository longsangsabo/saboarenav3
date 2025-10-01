import requests
import json

def verify_supabase_database():
    print("🔍 COMPLETE SUPABASE DATABASE VERIFICATION")
    print("=" * 60)
    
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"
    
    headers = {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    # List of all possible tables based on SQL schema files
    all_potential_tables = [
        # Core tables
        'users', 'tournaments', 'clubs', 'posts', 'matches', 'achievements',
        'comments', 'post_likes', 'user_achievements', 'tournament_participants',
        'club_members', 'notifications', 'friendships', 'club_reviews',
        
        # Additional tables from migrations
        'rank_requests', 'user_preferences', 'tournament_matches',
        'match_results', 'user_stats', 'rankings', 'leaderboards',
        'prizes', 'tournament_prizes', 'user_tournaments', 'club_tournaments',
        'users', 'social_posts', 'user_follows', 'post_comments',
        
        # System tables that might exist
        'auth.users', 'storage.objects', 'storage.buckets',
        
        # Possible additional tables
        'game_types', 'skill_levels', 'tournament_formats',
        'member_roles', 'club_settings', 'user_settings',
        'activity_logs', 'audit_logs'
    ]
    
    existing_tables = []
    table_info = {}
    
    print("\n📊 TESTING ALL POTENTIAL TABLES...")
    
    for table in all_potential_tables:
        try:
            # Test table existence with count
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/{table}?select=count",
                headers={**headers, "Prefer": "count=exact"}
            )
            
            # Status 200 or 206 means table exists
            if response.status_code in [200, 206]:
                existing_tables.append(table)
                
                # Extract count from Content-Range header
                content_range = response.headers.get('Content-Range', '')
                if '/' in content_range:
                    total_count = content_range.split('/')[-1]
                    table_info[table] = {
                        'rows': total_count,
                        'status': response.status_code
                    }
                    print(f"   ✅ {table}: {total_count} rows (status: {response.status_code})")
                else:
                    table_info[table] = {
                        'rows': 'unknown',
                        'status': response.status_code
                    }
                    print(f"   ✅ {table}: exists (status: {response.status_code})")
                    
            elif response.status_code == 404:
                # Table doesn't exist - skip silently
                pass
            else:
                print(f"   ⚠️  {table}: unexpected status {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            # Skip network errors
            pass
        except Exception as e:
            # Skip other errors
            pass
    
    print(f"\n📈 DATABASE TABLES SUMMARY:")
    print(f"   📊 Total found: {len(existing_tables)} tables")
    print(f"   📋 Complete list:")
    
    for i, table in enumerate(sorted(existing_tables), 1):
        info = table_info.get(table, {})
        rows = info.get('rows', 'unknown')
        status = info.get('status', 'unknown')
        print(f"      {i:2d}. {table:<25} ({rows} rows)")
    
    # Test RPC functions
    print(f"\n🔧 TESTING RPC FUNCTIONS...")
    
    potential_functions = [
        'get_user_stats', 'get_user_by_id', 'get_club_members',
        'get_tournament_leaderboard', 'join_tournament', 'leave_tournament',
        'create_match', 'update_match_result', 'update_user_elo',
        'update_comment_count', 'get_nearby_players', 'calculate_elo_change',
        'calculate_win_rate', 'get_user_feed', 'handle_new_user',
        'update_post_interaction_counts', 'update_comment_counts',
        'update_user_tournament_stats', 'cleanup_test_data',
        'find_nearby_users', 'update_user_rank_on_approval'
    ]
    
    existing_functions = []
    
    for func in potential_functions:
        try:
            # Test function existence
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/{func}",
                headers=headers,
                json={}
            )
            
            # Any status other than 404 means function exists
            if response.status_code != 404:
                existing_functions.append(func)
                print(f"   ✅ {func} (status: {response.status_code})")
            
        except:
            pass
    
    print(f"\n🔧 RPC FUNCTIONS SUMMARY:")
    print(f"   📊 Total found: {len(existing_functions)} functions")
    
    if len(existing_functions) > 0:
        print(f"   📋 Function list:")
        for i, func in enumerate(sorted(existing_functions), 1):
            print(f"      {i:2d}. {func}")
    
    # Final summary
    print(f"\n🎉 VERIFICATION RESULTS:")
    print(f"   📊 Tables found: {len(existing_tables)}")
    print(f"   🔧 Functions found: {len(existing_functions)}")
    
    if len(existing_tables) >= 25:
        print(f"   ✅ Close to your mentioned 29 tables!")
    elif len(existing_tables) >= 15:
        print(f"   ✅ Good number of tables found!")
    else:
        print(f"   ⚠️  Fewer tables than expected")
    
    return existing_tables, existing_functions

if __name__ == "__main__":
    tables, functions = verify_supabase_database()