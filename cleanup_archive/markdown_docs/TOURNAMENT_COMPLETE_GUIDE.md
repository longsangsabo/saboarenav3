# 🏆 HƯỚNG DẪN SỬ DỤNG TOURNAMENT SYSTEM - HOÀN CHỈNH

## ❌ VẤN ĐỀ ĐÃ PHÁT HIỆN

Khi bạn tạo tournaments và có participants nhưng **không thấy trận đấu nào**, đó là vì:

1. **Bảng đấu chưa được tạo** từ participants 
2. **RLS Policy restrictive** không cho phép tạo matches
3. **Button "Bắt đầu" chưa hoạt động** thực sự

## ✅ GIẢI PHÁP HOÀN CHỈNH

### **BƯỚC 1: CẬP NHẬT RLS POLICIES**

Vào **Supabase Dashboard > SQL Editor** và execute đoạn code sau:

```sql
-- =====================================================
-- RLS POLICY FOR MATCHES TABLE
-- Execute this in Supabase Dashboard > SQL Editor
-- =====================================================

-- Drop existing matches policies
DROP POLICY IF EXISTS "Matches are readable by everyone" ON matches;
DROP POLICY IF EXISTS "Tournament participants can create matches" ON matches;
DROP POLICY IF EXISTS "Tournament organizers can manage matches" ON matches;
DROP POLICY IF EXISTS "matches_public_read" ON matches;
DROP POLICY IF EXISTS "matches_owners_full_access" ON matches;

-- Public read policy for matches
CREATE POLICY "matches_public_read" 
ON matches 
FOR SELECT 
USING (true);

-- Full access for tournament organizers and club owners
CREATE POLICY "matches_owners_full_access" 
ON matches 
FOR ALL 
USING (
    -- Tournament organizer has full access
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = matches.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    -- Club owner has full access to their club's tournament matches
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        WHERE t.id = matches.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Players in the match can manage their own matches
    matches.player1_id = auth.uid() OR matches.player2_id = auth.uid()
    OR
    -- Admin has full access
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = matches.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        WHERE t.id = matches.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    matches.player1_id = auth.uid() OR matches.player2_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- Verify matches policies
SELECT 
    tablename, 
    policyname, 
    cmd,
    'Matches policy created successfully' as status
FROM pg_policies 
WHERE tablename = 'matches'
ORDER BY policyname;
```

### **BƯỚC 2: TẠO MATCHES TỰ ĐỘNG (CÁCH NHANH)**

Nếu bạn đã có tournaments với participants, chạy script Python này để tạo matches tự động:

```python
#!/usr/bin/env python3
import os
import sys
from supabase import create_client, Client
import uuid
from datetime import datetime

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    supabase = create_client(SUPABASE_URL, ANON_KEY)
    
    # Lấy tournaments cần tạo matches
    tournaments = supabase.table('tournaments').select('*').execute()
    
    for tournament in tournaments.data:
        tournament_id = tournament['id']
        
        # Kiểm tra participants và matches
        participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
        matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        
        if len(participants.data) >= 2 and len(matches.data) == 0:
            print(f"Creating matches for tournament: {tournament.get('title', 'No title')}")
            
            # Tạo single elimination matches
            matches_to_create = []
            for i in range(0, len(participants.data), 2):
                player1 = participants.data[i]
                player2 = participants.data[i + 1] if i + 1 < len(participants.data) else None
                
                match_data = {
                    'id': str(uuid.uuid4()),
                    'tournament_id': tournament_id,
                    'player1_id': player1['user_id'],
                    'player2_id': player2['user_id'] if player2 else None,
                    'round_number': 1,
                    'match_number': (i // 2) + 1,
                    'status': 'pending',
                    'created_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat(),
                }
                
                if player2 is None:  # BYE
                    match_data['winner_id'] = player1['user_id']
                    match_data['status'] = 'completed'
                    match_data['player1_score'] = 2
                    match_data['player2_score'] = 0
                
                matches_to_create.append(match_data)
            
            # Insert matches
            try:
                supabase.table('matches').insert(matches_to_create).execute()
                print(f"✅ Created {len(matches_to_create)} matches")
                
                # Update tournament status
                supabase.table('tournaments').update({
                    'status': 'in_progress',
                    'updated_at': datetime.now().isoformat()
                }).eq('id', tournament_id).execute()
                
            except Exception as e:
                print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
```

### **BƯỚC 3: SỬ DỤNG GIAO DIỆN FLUTTER**

#### **3.1. Vào Tournament Management Panel**
1. Mở tournament detail screen
2. Chọn tab **"Tournament Management"**
3. Chọn tab **"Bracket Management"** 

#### **3.2. Tạo Bracket**
1. **Chọn thể thức**: Single Elimination, Double Elimination, Round Robin, etc.
2. **Chọn seeding method**: ELO Rating, Ranking, Random, Manual
3. **Click "🚀 Tạo bảng đấu"**
4. Hệ thống sẽ generate bracket từ participants

#### **3.3. Bắt đầu Tournament**
1. Sau khi tạo bracket, sẽ xuất hiện **"✅ Bảng đấu đã được tạo"**
2. **Click "Bắt đầu"** 
3. Confirm dialog → **Click "Bắt đầu"**
4. Hệ thống sẽ:
   - Tạo tất cả matches vào database
   - Cập nhật tournament status thành `in_progress`
   - Hiển thị thông báo số matches đã tạo

### **BƯỚC 4: KIỂM TRA KẾT QUẢ**

#### **4.1. Kiểm tra Matches đã tạo**
Vào tab **"Match Management"** để xem tất cả matches đã được tạo:
- Trận đấu Round 1 với participants thật
- Placeholder matches cho các rounds tiếp theo
- BYE matches (nếu số participants lẻ)

#### **4.2. Xem Bracket**
Vào tab **"Bracket"** để xem:
- Sơ đồ bảng đấu hoàn chỉnh
- Participants đã được seeded
- Matches theo từng round

## 🎯 QUY TRÌNH HOÀN CHỈNH

### **Tạo Tournament Mới:**
1. **Tạo tournament** với title, format, max_participants
2. **Participants đăng ký** vào tournament
3. **Club owner** vào Tournament Management Panel
4. **Generate bracket** từ participants
5. **Start tournament** - tạo matches vào database
6. **Participants bắt đầu thi đấu**

### **Xem Tournament đã có:**
1. Vào **Tournament Detail Screen**
2. **Tab Matches**: Xem tất cả trận đấu
3. **Tab Bracket**: Xem sơ đồ bảng đấu  
4. **Tab Management**: Quản lý tournament (chỉ club owner)

## 🚨 TROUBLESHOOTING

### **Không tạo được matches?**
- ✅ Kiểm tra RLS policies cho matches table
- ✅ Đảm bảo có ít nhất 2 participants
- ✅ User phải là club owner hoặc tournament organizer

### **Không thấy button "Tạo bảng đấu"?**
- ✅ Phải vào đúng tab "Tournament Management" 
- ✅ Phải là club owner hoặc organizer
- ✅ Tournament phải có participants

### **Button "Bắt đầu" không hoạt động?**
- ✅ Đảm bảo đã generate bracket trước
- ✅ Kiểm tra RLS policies
- ✅ Xem console logs để debug lỗi

## 🎉 KẾT QUẢ MONG ĐỢI

Sau khi hoàn thành, bạn sẽ có:
- ✅ Tournament với matches hiển thị đầy đủ
- ✅ Bracket visualization hoàn chỉnh
- ✅ Participants có thể xem schedule của mình
- ✅ Club owner có thể quản lý toàn bộ tournament
- ✅ Matches progression tự động theo kết quả

**🚀 TOURNAMENT SYSTEM HOẠT ĐỘNG HOÀN CHỈNH!**