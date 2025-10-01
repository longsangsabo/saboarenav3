-- REMOVE SKILL LEVEL MIGRATION
-- Xóa skill_level_required vì không sử dụng

-- 1. Drop constraint liên quan đến skill_level_required
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_required_check;
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS tournaments_skill_level_check;

-- 2. Xóa cột skill_level_required khỏi tournaments table
ALTER TABLE tournaments DROP COLUMN IF EXISTS skill_level_required;

-- 3. Xóa index liên quan
DROP INDEX IF EXISTS idx_tournaments_skill_level;

-- Migration completed - skill level removed