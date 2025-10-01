import psycopg2
import sys

# Database connection with new password
conn = psycopg2.connect(
    host="aws-1-ap-southeast-1.pooler.supabase.com",
    port=6543,
    database="postgres",
    user="postgres.mogjjvscxjwvhtpkrlqr",
    password="Acookingoil123"
)

try:
    cursor = conn.cursor()
    
    print("=== CHECKING MATCHES TABLE ===")
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'matches' 
        ORDER BY ordinal_position;
    """)
    
    matches_columns = cursor.fetchall()
    print("Matches table columns:")
    has_format = False
    for col in matches_columns:
        print(f"  {col[0]} ({col[1]}) - Nullable: {col[2]}")
        if col[0] == 'format':
            has_format = True
    
    if has_format:
        print("\n✅ 'format' column already exists!")
    else:
        print("\n❌ 'format' column missing - adding it now...")
        
        # Add format column to matches table
        cursor.execute("""
            ALTER TABLE matches 
            ADD COLUMN format TEXT DEFAULT 'single_elimination';
        """)
        
        print("✅ Added 'format' column to matches table")
    
    # Commit changes
    conn.commit()
    
    # Verify the change
    print("\n=== VERIFYING MATCHES TABLE AFTER UPDATE ===")
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'matches' 
        AND column_name = 'format';
    """)
    
    format_col = cursor.fetchone()
    if format_col:
        print(f"✅ 'format' column verified: {format_col[0]} ({format_col[1]}) - Nullable: {format_col[2]}")
    else:
        print("❌ 'format' column still not found!")
    
    cursor.close()
    conn.close()
    print("\n🎯 Database update completed!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    conn.rollback()
    sys.exit(1)