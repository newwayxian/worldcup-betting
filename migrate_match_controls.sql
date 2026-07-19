-- ============================================
-- 比赛控制功能迁移脚本：显示/隐藏 + 自定义封盘时间
-- 在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- 1. matches 表新增字段
ALTER TABLE matches ADD COLUMN IF NOT EXISTS hidden BOOLEAN DEFAULT false;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS custom_deadline TIMESTAMPTZ;

-- 2. 防作弊触发器：封盘后 custom_deadline 不可再修改
--    有效截止时间 = custom_deadline（若设置）否则 match_time - 3 小时
CREATE OR REPLACE FUNCTION check_deadline_lock() RETURNS trigger AS $$
BEGIN
  IF NEW.custom_deadline IS DISTINCT FROM OLD.custom_deadline THEN
    IF now() >= COALESCE(OLD.custom_deadline, OLD.match_time - interval '3 hours') THEN
      RAISE EXCEPTION '该场已封盘，封盘时间不可再修改';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS deadline_lock ON matches;
CREATE TRIGGER deadline_lock
  BEFORE UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION check_deadline_lock();
