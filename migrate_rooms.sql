-- ============================================
-- 多房间功能迁移脚本
-- 在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- 1. 创建 rooms 表
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rooms_all" ON rooms;
CREATE POLICY "rooms_all" ON rooms FOR ALL USING (true) WITH CHECK (true);

-- 2. 添加 room_id 到 matches 和 bets
ALTER TABLE matches ADD COLUMN IF NOT EXISTS room_id UUID REFERENCES rooms(id);
ALTER TABLE bets ADD COLUMN IF NOT EXISTS room_id UUID REFERENCES rooms(id);

-- 3. 创建默认房间（密码 wcsz2026），如果已存在则跳过
INSERT INTO rooms (name, password_hash)
SELECT '默认房间', '3654aea138a1e5989d2333cabe3c2682f664821fda7ce9cdbdf7074716a3ffdd'
WHERE NOT EXISTS (SELECT 1 FROM rooms WHERE password_hash = '3654aea138a1e5989d2333cabe3c2682f664821fda7ce9cdbdf7074716a3ffdd');

-- 4. 把现有数据归属到默认房间
UPDATE matches SET room_id = (SELECT id FROM rooms WHERE password_hash = '3654aea138a1e5989d2333cabe3c2682f664821fda7ce9cdbdf7074716a3ffdd' LIMIT 1)
WHERE room_id IS NULL;

UPDATE bets SET room_id = (SELECT id FROM rooms WHERE password_hash = '3654aea138a1e5989d2333cabe3c2682f664821fda7ce9cdbdf7074716a3ffdd' LIMIT 1)
WHERE room_id IS NULL;
