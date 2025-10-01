-- =====================================================
-- RLS RELAXATION FOR CLUB OWNERS - TOURNAMENT MANAGEMENT
-- Điều chỉnh RLS để Club Owners có toàn quyền truy cập data CLB
-- =====================================================

-- Kết nối với service_role để bypass RLS hiện tại
-- URL: https://mogjjvscxjwvhtpkrlqr.supabase.co
-- Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo

-- =====================================================
-- STEP 1: TOURNAMENTS TABLE - Club owners full access
-- =====================================================

-- Xóa policies cũ có thể xung đột
DROP POLICY IF EXISTS "Club owners can manage tournaments" ON tournaments;
DROP POLICY IF EXISTS "Tournament organizers can manage tournaments" ON tournaments;
DROP POLICY IF EXISTS "Tournaments are publicly readable" ON tournaments;

-- Tạo policy mới: Public read, club owners/organizers full access
CREATE POLICY "public_read_tournaments" 
ON tournaments 
FOR SELECT 
USING (true);

CREATE POLICY "club_owners_full_tournament_access" 
ON tournaments 
FOR ALL 
USING (
    -- Club owner có toàn quyền với tournaments của CLB họ
    EXISTS (
        SELECT 1 FROM clubs 
        WHERE clubs.id = tournaments.club_id 
        AND clubs.owner_id = auth.uid()
    )
    OR 
    -- Tournament organizer có toàn quyền với tournament của họ
    tournaments.organizer_id = auth.uid()
    OR
    -- Admin có toàn quyền
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM clubs 
        WHERE clubs.id = tournaments.club_id 
        AND clubs.owner_id = auth.uid()
    )
    OR 
    tournaments.organizer_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
);

-- =====================================================
-- STEP 2: TOURNAMENT_PARTICIPANTS TABLE - Club owners full access
-- =====================================================

-- Xóa tất cả policies cũ
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admin users can manage all tournament participants" ON tournament_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Users can withdraw from tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament participants are publicly readable" ON tournament_participants;
DROP POLICY IF EXISTS "Admin full access" ON tournament_participants;
DROP POLICY IF EXISTS "User self registration" ON tournament_participants;
DROP POLICY IF EXISTS "User manage own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Public read participants" ON tournament_participants;

-- Public read access
CREATE POLICY "public_read_tournament_participants" 
ON tournament_participants 
FOR SELECT 
USING (true);

-- Club owners và tournament organizers có toàn quyền
CREATE POLICY "club_owners_full_participants_access" 
ON tournament_participants 
FOR ALL 
USING (
    -- Club owner có toàn quyền với participants của tournaments thuộc CLB họ
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON t.club_id = c.id
        WHERE t.id = tournament_participants.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Tournament organizer có toàn quyền
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    -- Admin có toàn quyền
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    -- User có thể manage participation của chính họ
    tournament_participants.user_id = auth.uid()
) 
WITH CHECK (
    -- Tương tự cho WITH CHECK
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON t.club_id = c.id
        WHERE t.id = tournament_participants.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    tournament_participants.user_id = auth.uid()
);

-- =====================================================
-- STEP 3: CLUB_MEMBERS TABLE - Club owners full access
-- =====================================================

-- Xóa policies cũ
DROP POLICY IF EXISTS "Club members are readable by club members" ON club_members;
DROP POLICY IF EXISTS "Users can join clubs" ON club_members;
DROP POLICY IF EXISTS "Users can leave clubs" ON club_members;
DROP POLICY IF EXISTS "Club admins can manage members" ON club_members;

-- Public read cho club members (cần để hiển thị danh sách)
CREATE POLICY "public_read_club_members" 
ON club_members 
FOR SELECT 
USING (true);

-- Club owners có toàn quyền quản lý members
CREATE POLICY "club_owners_full_members_access" 
ON club_members 
FOR ALL 
USING (
    -- Club owner có toàn quyền với members của CLB họ
    EXISTS (
        SELECT 1 FROM clubs c
        WHERE c.id = club_members.club_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Club admin có quyền quản lý
    EXISTS (
        SELECT 1 FROM club_members cm
        WHERE cm.club_id = club_members.club_id 
        AND cm.user_id = auth.uid()
        AND cm.role IN ('owner', 'admin')
        AND cm.status = 'active'
    )
    OR
    -- User có thể manage membership của chính họ
    club_members.user_id = auth.uid()
    OR
    -- Admin có toàn quyền
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM clubs c
        WHERE c.id = club_members.club_id 
        AND c.owner_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM club_members cm
        WHERE cm.club_id = club_members.club_id 
        AND cm.user_id = auth.uid()
        AND cm.role IN ('owner', 'admin')
        AND cm.status = 'active'
    )
    OR
    club_members.user_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- =====================================================
-- STEP 4: CLUBS TABLE - Owners full access
-- =====================================================

-- Xóa policies cũ nếu có
DROP POLICY IF EXISTS "Clubs are publicly readable" ON clubs;
DROP POLICY IF EXISTS "Club owners can manage clubs" ON clubs;

-- Public read
CREATE POLICY "public_read_clubs" 
ON clubs 
FOR SELECT 
USING (true);

-- Club owners full access
CREATE POLICY "club_owners_full_club_access" 
ON clubs 
FOR ALL 
USING (
    clubs.owner_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    clubs.owner_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- =====================================================
-- STEP 5: MATCHES TABLE (nếu có) - Tournament related access
-- =====================================================

-- Kiểm tra xem bảng matches có tồn tại không
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'matches') THEN
        -- Xóa policies cũ
        DROP POLICY IF EXISTS "public_read_matches" ON matches;
        DROP POLICY IF EXISTS "tournament_managers_full_matches_access" ON matches;
        
        -- Public read
        EXECUTE 'CREATE POLICY "public_read_matches" ON matches FOR SELECT USING (true)';
        
        -- Tournament managers full access
        EXECUTE 'CREATE POLICY "tournament_managers_full_matches_access" 
        ON matches 
        FOR ALL 
        USING (
            EXISTS (
                SELECT 1 FROM tournaments t
                JOIN clubs c ON t.club_id = c.id
                WHERE t.id = matches.tournament_id 
                AND c.owner_id = auth.uid()
            )
            OR
            EXISTS (
                SELECT 1 FROM tournaments t
                WHERE t.id = matches.tournament_id 
                AND t.organizer_id = auth.uid()
            )
            OR
            EXISTS (
                SELECT 1 FROM users u 
                WHERE u.id = auth.uid() 
                AND u.role = ''admin''
            )
        ) 
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM tournaments t
                JOIN clubs c ON t.club_id = c.id
                WHERE t.id = matches.tournament_id 
                AND c.owner_id = auth.uid()
            )
            OR
            EXISTS (
                SELECT 1 FROM tournaments t
                WHERE t.id = matches.tournament_id 
                AND t.organizer_id = auth.uid()
            )
            OR
            EXISTS (
                SELECT 1 FROM users u 
                WHERE u.id = auth.uid() 
                AND u.role = ''admin''
            )
        )';
        
        RAISE NOTICE 'Updated matches table policies';
    ELSE
        RAISE NOTICE 'Matches table does not exist, skipping';
    END IF;
END
$$;

-- =====================================================
-- STEP 6: Verify và Grant Permissions
-- =====================================================

-- Đảm bảo RLS được bật
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON tournaments TO authenticated;
GRANT SELECT ON tournaments TO anon;

GRANT ALL ON tournament_participants TO authenticated;
GRANT SELECT ON tournament_participants TO anon;

GRANT ALL ON club_members TO authenticated;
GRANT SELECT ON club_members TO anon;

GRANT ALL ON clubs TO authenticated;
GRANT SELECT ON clubs TO anon;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Kiểm tra policies đã tạo
SELECT 'VERIFICATION: Current RLS Policies' as info;

SELECT 
    tablename, 
    policyname, 
    cmd,
    CASE 
        WHEN length(qual) > 50 THEN left(qual, 50) || '...'
        ELSE qual 
    END as using_clause
FROM pg_policies 
WHERE tablename IN ('tournaments', 'tournament_participants', 'club_members', 'clubs')
ORDER BY tablename, policyname;

-- Kiểm tra dữ liệu mẫu
SELECT 'VERIFICATION: Sample Data Counts' as info;

SELECT 
    'clubs' as table_name, 
    count(*) as record_count 
FROM clubs
UNION ALL
SELECT 
    'tournaments' as table_name, 
    count(*) as record_count 
FROM tournaments
UNION ALL
SELECT 
    'tournament_participants' as table_name, 
    count(*) as record_count 
FROM tournament_participants
UNION ALL
SELECT 
    'club_members' as table_name, 
    count(*) as record_count 
FROM club_members;

COMMIT;