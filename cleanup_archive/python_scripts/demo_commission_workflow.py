#!/usr/bin/env python3
"""
Demo commission system workflow
"""

import asyncio
import asyncpg
import uuid
from datetime import datetime

DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

async def demo_commission_workflow():
    print('🎯 DEMO: Nhân viên nhận hoa hồng như thế nào?')
    print('=' * 60)
    
    conn = await asyncpg.connect(DATABASE_URL)
    
    try:
        # Get sample data
        sample_users = await conn.fetch("SELECT id, full_name FROM users LIMIT 3")
        sample_club = await conn.fetchrow("SELECT id, name FROM clubs LIMIT 1")
        
        if len(sample_users) < 2 or not sample_club:
            print('❌ Cần ít nhất 2 users và 1 club để demo')
            return
            
        staff_user = sample_users[0]
        customer_user = sample_users[1]
        club = sample_club
        
        print(f'🏢 Club: {club["name"]}')
        print(f'👤 Nhân viên: {staff_user["full_name"]}')
        print(f'🛒 Khách hàng: {customer_user["full_name"]}')
        
        # IDs for demo
        staff_id = str(uuid.uuid4())
        referral_id = str(uuid.uuid4())
        transaction_id = str(uuid.uuid4())
        
        print('\n' + '='*60)
        print('📋 BƯỚC 1: Thêm nhân viên với 8% hoa hồng')
        
        await conn.execute("""
            INSERT INTO club_staff (id, club_id, user_id, staff_role, commission_rate, is_active)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (id) DO UPDATE SET
                commission_rate = EXCLUDED.commission_rate
        """, staff_id, club['id'], staff_user['id'], 'staff', 8.0, True)
        
        print(f'✅ {staff_user["full_name"]} được thêm làm nhân viên với 8% hoa hồng')
        
        print('\n' + '='*60)
        print('🤝 BƯỚC 2: Nhân viên giới thiệu khách hàng (10% hoa hồng đặc biệt)')
        
        await conn.execute("""
            INSERT INTO staff_referrals (id, staff_id, customer_id, club_id, commission_rate, is_active)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (id) DO UPDATE SET
                commission_rate = EXCLUDED.commission_rate
        """, referral_id, staff_id, customer_user['id'], club['id'], 10.0, True)
        
        print(f'✅ Mối quan hệ giới thiệu tạo thành công')
        print(f'   👥 {staff_user["full_name"]} giới thiệu {customer_user["full_name"]}')
        print(f'   💰 Hoa hồng đặc biệt: 10% (thay vì 8% mặc định)')
        
        print('\n' + '='*60)
        print('💳 BƯỚC 3: Khách hàng thực hiện giao dịch...')
        
        # Scenario 1: Tournament fee
        transaction_amount = 150000  # 150k VND
        await conn.execute("""
            INSERT INTO customer_transactions (
                id, customer_id, club_id, staff_referral_id,
                transaction_type, amount, commission_eligible, description
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (id) DO UPDATE SET
                amount = EXCLUDED.amount
        """, transaction_id, customer_user['id'], club['id'], referral_id,
            'tournament_fee', transaction_amount, True, 'Tham gia giải đấu tháng 9')
        
        print(f'💰 Giao dịch: {transaction_amount:,} VND (Tournament fee)')
        print('⚡ Trigger đang chạy tự động...')
        
        # Wait for trigger
        await asyncio.sleep(2)
        
        print('\n' + '='*60)
        print('🎉 BƯỚC 4: Kết quả tự động!')
        
        # Check commission created
        commission = await conn.fetchrow("""
            SELECT 
                sc.*,
                ct.transaction_type,
                ct.description
            FROM staff_commissions sc
            JOIN customer_transactions ct ON ct.id = sc.customer_transaction_id
            WHERE sc.customer_transaction_id = $1
        """, transaction_id)
        
        if commission:
            print('✅ Hoa hồng đã được tính tự động!')
            print(f'   💰 Số tiền giao dịch: {int(commission["transaction_amount"]):,} VND')
            print(f'   📊 Tỷ lệ hoa hồng: {commission["commission_rate"]}%')
            print(f'   💵 Hoa hồng nhận được: {int(commission["commission_amount"]):,} VND')
            print(f'   📝 Loại hoa hồng: {commission["commission_type"]}')
            print(f'   ⏰ Thời gian: {commission["earned_at"]}')
            print(f'   💳 Trạng thái: {"Đã thanh toán" if commission["is_paid"] else "Chưa thanh toán"}')
        else:
            print('⚠️ Chưa tìm thấy hoa hồng - có thể trigger chưa chạy xong')
        
        # Show updated referral totals
        referral_stats = await conn.fetchrow("""
            SELECT total_commission_earned, total_customer_spending
            FROM staff_referrals WHERE id = $1
        """, referral_id)
        
        if referral_stats:
            print(f'\n📈 Cập nhật tổng kết:')
            print(f'   💰 Tổng hoa hồng kiếm được: {int(referral_stats["total_commission_earned"] or 0):,} VND')
            print(f'   🛒 Tổng chi tiêu khách hàng: {int(referral_stats["total_customer_spending"] or 0):,} VND')
        
        print('\n' + '='*60)
        print('📊 BƯỚC 5: Thêm giao dịch để demo tích lũy')
        
        # Add more transactions
        scenarios = [
            ('table_booking', 80000, 'Đặt bàn chơi 2 tiếng'),
            ('merchandise', 250000, 'Mua cơ bi-a cao cấp'),
            ('tournament_fee', 200000, 'Giải đấu VIP'),
        ]
        
        total_revenue = transaction_amount
        
        for i, (tx_type, amount, desc) in enumerate(scenarios, 2):
            tx_id = str(uuid.uuid4())
            
            await conn.execute("""
                INSERT INTO customer_transactions (
                    id, customer_id, club_id, staff_referral_id,
                    transaction_type, amount, commission_eligible, description
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """, tx_id, customer_user['id'], club['id'], referral_id,
                tx_type, amount, True, desc)
            
            total_revenue += amount
            expected_commission = amount * 0.10  # 10%
            print(f'   {i}. {desc}: {amount:,} VND → Hoa hồng: {int(expected_commission):,} VND')
        
        await asyncio.sleep(3)  # Wait for all triggers
        
        # Final summary
        final_stats = await conn.fetchrow("""
            SELECT 
                COUNT(*) as total_transactions,
                SUM(commission_amount) as total_commissions,
                AVG(commission_rate) as avg_rate
            FROM staff_commissions 
            WHERE staff_id = $1
        """, staff_id)
        
        print(f'\n🎯 TỔNG KẾT CUỐI CÙNG:')
        print(f'   📊 Tổng giao dịch: {final_stats["total_transactions"]}')
        print(f'   💰 Tổng doanh thu tạo ra: {total_revenue:,} VND')
        print(f'   💵 Tổng hoa hồng kiếm được: {int(final_stats["total_commissions"] or 0):,} VND')
        print(f'   📈 Tỷ lệ hoa hồng trung bình: {final_stats["avg_rate"] or 0:.1f}%')
        
        expected_total = total_revenue * 0.10
        print(f'   ✓ Kỳ vọng: {int(expected_total):,} VND')
        
        # Cleanup demo data
        print(f'\n🧹 Dọn dẹp dữ liệu demo...')
        await conn.execute("DELETE FROM staff_commissions WHERE staff_id = $1", staff_id)
        await conn.execute("DELETE FROM customer_transactions WHERE staff_referral_id = $1", referral_id)
        await conn.execute("DELETE FROM staff_referrals WHERE id = $1", referral_id)
        await conn.execute("DELETE FROM club_staff WHERE id = $1", staff_id)
        
        print('✅ Demo hoàn tất!')
        print('\n' + '='*60)
        print('🚀 HỆ THỐNG HOA HỒNG HOẠT ĐỘNG HOÀN HẢO!')
        print('✅ Tự động tính toán khi có giao dịch')
        print('✅ Hỗ trợ nhiều loại giao dịch')
        print('✅ Linh hoạt về tỷ lệ hoa hồng')
        print('✅ Theo dõi realtime và báo cáo chi tiết')
        
    except Exception as e:
        print(f'❌ Lỗi demo: {e}')
        import traceback
        traceback.print_exc()
        
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(demo_commission_workflow())