import psycopg2
import sys

# Database connection
conn = psycopg2.connect(
    host="aws-1-ap-southeast-1.pooler.supabase.com",
    port=6543,
    database="postgres",
    user="postgres.mogjjvscxjwvhtpkrlqr",
    password="Acookingoil123"
)

try:
    cursor = conn.cursor()
    
    print("=== ANALYZING MATCHES TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'matches' 
        ORDER BY ordinal_position;
    """)
    
    matches_columns = cursor.fetchall()
    print("Current matches table columns:")
    
    has_round = False
    has_format = False
    for col in matches_columns:
        print(f"  {col[0]} ({col[1]}) - Nullable: {col[2]}")
        if col[0] == 'round':
            has_round = True
        if col[0] == 'format':
            has_format = True
    
    print(f"\nColumn Status:")
    print(f"  'format' column: {'EXISTS' if has_format else 'MISSING'}")
    print(f"  'round' column: {'EXISTS' if has_round else 'MISSING'}")
    
    # Add missing columns
    if not has_round:
        print("\n-- Adding 'round' column...")
        cursor.execute("""
            ALTER TABLE matches 
            ADD COLUMN round TEXT;
        """)
        print("   Added 'round' column")
    
    # Check what other columns might be missing based on the code
    missing_columns = []
    
    # Check for common tournament bracket columns that might be missing
    expected_columns = [
        ('bracket_position', 'INTEGER'),
        ('parent_match_id', 'UUID'),
        ('next_match_id', 'UUID'),
        ('match_level', 'INTEGER'),
        ('is_final', 'BOOLEAN DEFAULT FALSE'),
        ('is_third_place', 'BOOLEAN DEFAULT FALSE')
    ]
    
    current_column_names = [col[0] for col in matches_columns]
    
    for col_name, col_type in expected_columns:
        if col_name not in current_column_names:
            missing_columns.append((col_name, col_type))
    
    if missing_columns:
        print(f"\n-- Found {len(missing_columns)} potentially missing columns for tournament brackets:")
        for col_name, col_type in missing_columns:
            print(f"   {col_name} ({col_type})")
            try:
                cursor.execute(f"ALTER TABLE matches ADD COLUMN {col_name} {col_type};")
                print(f"   ✓ Added {col_name}")
            except Exception as e:
                print(f"   ✗ Failed to add {col_name}: {e}")
    
    # Commit changes
    conn.commit()
    print("\n=== FINAL VERIFICATION ===")
    
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'matches' 
        AND column_name IN ('round', 'format', 'bracket_position', 'parent_match_id')
        ORDER BY column_name;
    """)
    
    verified_cols = cursor.fetchall()
    print("Verified key columns:")
    for col in verified_cols:
        print(f"  ✓ {col[0]}")
    
    cursor.close()
    conn.close()
    print("\nDatabase update completed!")
    
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()
    sys.exit(1)