import psycopg2

# Database connection parameters
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:SABOv1_2025@aws-0-ap-southeast-1.pooler.supabase.co:6543/postgres"

def apply_trigger():
    """Apply the tournament progression trigger to the database"""
    try:
        # Connect to database
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        print("🔌 Connected to database")
        
        # Read the SQL file
        with open('tournament_progression_trigger.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("📄 Read SQL file")
        
        # Execute the SQL
        cur.execute(sql_content)
        conn.commit()
        
        print("✅ Tournament progression trigger applied successfully!")
        
        # Test the trigger by checking if it was created
        cur.execute("""
            SELECT trigger_name, event_manipulation, event_object_table 
            FROM information_schema.triggers 
            WHERE trigger_name = 'auto_create_next_round';
        """)
        
        result = cur.fetchone()
        if result:
            print(f"✅ Trigger '{result[0]}' created on table '{result[2]}'")
        else:
            print("⚠️ Trigger not found in information_schema")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error applying trigger: {e}")

if __name__ == "__main__":
    print("=== APPLYING TOURNAMENT PROGRESSION TRIGGER ===")
    apply_trigger()