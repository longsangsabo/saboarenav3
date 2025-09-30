-- REFERRAL SYSTEM TEST QUERIES
-- Chạy các query này trong Supabase SQL Editor để test

-- 1. Kiểm tra tất cả referral codes
SELECT 
    code,
    user_id,
    current_uses,
    max_uses,
    is_active,
    created_at
FROM referral_codes 
ORDER BY created_at DESC;

-- 2. Kiểm tra referral usage
SELECT 
    ru.*,
    rc.code as referral_code
FROM referral_usage ru
JOIN referral_codes rc ON ru.referral_code_id = rc.id
ORDER BY ru.used_at DESC;

-- 3. Kiểm tra users có SPA balance
SELECT 
    id,
    email,
    full_name,
    spa_balance,
    referral_code,
    created_at
FROM users 
WHERE spa_balance > 0 OR referral_code IS NOT NULL
ORDER BY spa_balance DESC;

-- 4. Test tạo referral code thủ công
INSERT INTO referral_codes (
    user_id, 
    code, 
    max_uses, 
    current_uses,
    spa_reward_referrer,
    spa_reward_referred,
    is_active
) VALUES (
    (SELECT id FROM users LIMIT 1),
    'SABO-MANUAL-TEST',
    10,
    0,
    100,
    50,
    true
);

-- 5. Test simulate referral usage
INSERT INTO referral_usage (
    referral_code_id,
    referrer_id,
    referred_user_id,
    spa_awarded_referrer,
    spa_awarded_referred
) VALUES (
    (SELECT id FROM referral_codes WHERE code = 'SABO-MANUAL-TEST'),
    (SELECT user_id FROM referral_codes WHERE code = 'SABO-MANUAL-TEST'),
    (SELECT id FROM users ORDER BY created_at DESC LIMIT 1),
    100,
    50
);

-- 6. Verify kết quả
SELECT 
    'Total Referral Codes' as metric,
    COUNT(*) as value
FROM referral_codes

UNION ALL

SELECT 
    'Active Referral Codes',
    COUNT(*)
FROM referral_codes 
WHERE is_active = true

UNION ALL

SELECT 
    'Total Referral Usage',
    COUNT(*)
FROM referral_usage

UNION ALL

SELECT 
    'Users with SPA > 0',
    COUNT(*)
FROM users 
WHERE spa_balance > 0;