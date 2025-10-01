#!/usr/bin/env python3
"""
🔍 SABO ARENA - Database Schema Analyzer
Analyze existing Supabase database structure for tournament bracket integration
"""

import os
import sys
import json
from typing import Dict, List, Any

try:
    from supabase import create_client, Client
except ImportError:
    print("❌ Error: supabase package not found")
    print("Please install: pip install supabase")
    sys.exit(1)

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def main():
    print("🔍 SABO ARENA - Database Schema Analysis")
    print("=" * 60)
    
    try:
        # Create Supabase client with service role
        supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)
        print("✅ Connected to Supabase successfully")
        
        # Analyze existing schema
        analyze_existing_schema(supabase)
        
        # Check tournament-related tables
        analyze_tournament_tables(supabase)
        
        # Suggest bracket integration schema
        suggest_bracket_schema()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

def analyze_existing_schema(supabase: Client):
    """Analyze existing database schema"""
    print("\n📊 EXISTING DATABASE SCHEMA")
    print("-" * 40)
    
    try:
        # Get all tables using PostgreSQL system catalogs
        result = supabase.rpc('get_table_info').execute()
        if result.data:
            print("📋 Available Tables:")
            for table in result.data:
                print(f"  • {table}")
        else:
            # Fallback: try to list some common tables
            common_tables = [
                'users', 'user_profiles', 'clubs', 'tournaments', 
                'tournament_participants', 'matches', 'challenges'
            ]
            
            print("📋 Checking Common Tables:")
            for table_name in common_tables:
                try:
                    result = supabase.table(table_name).select("*", count="exact").limit(1).execute()
                    count = result.count if hasattr(result, 'count') else 'Unknown'
                    print(f"  ✅ {table_name} (count: {count})")
                except Exception as e:
                    print(f"  ❌ {table_name} - {str(e)[:50]}...")
                    
    except Exception as e:
        print(f"⚠️ Could not get schema info: {e}")

def analyze_tournament_tables(supabase: Client):
    """Analyze tournament-related tables in detail"""
    print("\n🏆 TOURNAMENT TABLES ANALYSIS")
    print("-" * 40)
    
    tournament_tables = ['tournaments', 'tournament_participants', 'matches']
    
    for table_name in tournament_tables:
        try:
            print(f"\n📋 Table: {table_name}")
            
            # Get sample data
            result = supabase.table(table_name).select("*").limit(3).execute()
            
            if result.data:
                print(f"  ✅ Found {len(result.data)} sample records")
                
                # Show structure
                if result.data:
                    sample = result.data[0]
                    print("  📝 Columns:")
                    for col, value in sample.items():
                        data_type = type(value).__name__
                        print(f"    • {col}: {data_type}")
                        
                print("  📄 Sample Data:")
                for i, record in enumerate(result.data):
                    print(f"    Record {i+1}: {json.dumps(record, indent=6, default=str)}")
            else:
                print(f"  ⚠️ Table {table_name} exists but is empty")
                
        except Exception as e:
            print(f"  ❌ Error accessing {table_name}: {str(e)[:100]}...")

def suggest_bracket_schema():
    """Suggest database schema for bracket integration"""
    print("\n🎯 SUGGESTED BRACKET INTEGRATION SCHEMA")
    print("-" * 50)
    
    schema_suggestions = {
        "tournament_brackets": {
            "description": "Main bracket data for each tournament",
            "columns": {
                "id": "UUID PRIMARY KEY",
                "tournament_id": "UUID REFERENCES tournaments(id)",
                "format": "TEXT (single_elimination, double_elimination, etc.)",
                "structure": "JSONB (bracket metadata)",
                "participants": "JSONB (seeded participant list)",
                "status": "TEXT (generating, active, completed)",
                "created_at": "TIMESTAMP",
                "updated_at": "TIMESTAMP"
            }
        },
        "tournament_rounds": {
            "description": "Tournament rounds within a bracket",
            "columns": {
                "id": "UUID PRIMARY KEY",
                "bracket_id": "UUID REFERENCES tournament_brackets(id)",
                "round_number": "INTEGER",
                "name": "TEXT (Vòng 1, Bán kết, Chung kết, etc.)",
                "type": "TEXT (winner, loser, grand_final, etc.)",
                "status": "TEXT (pending, active, completed)",
                "metadata": "JSONB (round-specific data)",
                "created_at": "TIMESTAMP"
            }
        },
        "tournament_matches": {
            "description": "Individual matches within rounds",
            "columns": {
                "id": "UUID PRIMARY KEY",
                "round_id": "UUID REFERENCES tournament_rounds(id)",
                "match_number": "INTEGER",
                "player1_id": "UUID REFERENCES users(id)",
                "player2_id": "UUID REFERENCES users(id)",
                "winner_id": "UUID REFERENCES users(id)",
                "status": "TEXT (pending, in_progress, completed, bye)",
                "scheduled_time": "TIMESTAMP",
                "result": "JSONB (scores, details)",
                "metadata": "JSONB (match-specific data)",
                "created_at": "TIMESTAMP",
                "updated_at": "TIMESTAMP"
            }
        }
    }
    
    for table_name, info in schema_suggestions.items():
        print(f"\n📋 {table_name.upper()}")
        print(f"  Purpose: {info['description']}")
        print("  Columns:")
        for col, desc in info['columns'].items():
            print(f"    • {col}: {desc}")

if __name__ == "__main__":
    main()