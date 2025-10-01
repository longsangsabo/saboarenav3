import psycopg2
import sys

# Database connection - Using separate parameters with new password
try:
    conn = psycopg2.connect(
        host="aws-1-ap-southeast-1.pooler.supabase.com",
        port=6543,
        database="postgres",
        user="postgres.mogjjvscxjwvhtpkrlqr",
        password="Acookingoil123"
    )
    cursor = conn.cursor()
    
    print("=== CHECKING USERS TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        ORDER BY ordinal_position;
    """)
    
    users_columns = cursor.fetchall()
    print("Users table columns:")
    for col in users_columns:
        print(f"  {col[0]} ({col[1]}) - Nullable: {col[2]}")
    
    print("\n=== CHECKING IF current_rank COLUMN EXISTS ===")
    cursor.execute("""
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name = 'current_rank'
        );
    """)
    
    has_current_rank = cursor.fetchone()[0]
    print(f"current_rank column exists: {has_current_rank}")
    
    print("\n=== SAMPLE USER DATA ===")
    cursor.execute("SELECT * FROM users LIMIT 1;")
    sample_user = cursor.fetchone()
    
    # Get column names
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        ORDER BY ordinal_position;
    """)
    column_names = [row[0] for row in cursor.fetchall()]
    
    if sample_user:
        print("Sample user data:")
        for i, value in enumerate(sample_user):
            print(f"  {column_names[i]}: {value}")
    else:
        print("No users found")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)