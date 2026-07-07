-- ============================================
-- 世界杯竞猜池 - Supabase 数据库初始化脚本
-- 在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- 1. 创建表
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_a TEXT NOT NULL,
  team_b TEXT NOT NULL,
  match_time TIMESTAMPTZ NOT NULL,
  score_a INTEGER,
  score_b INTEGER,
  winner TEXT,
  room_id UUID REFERENCES rooms(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  pool_type TEXT NOT NULL CHECK (pool_type IN ('score', 'result')),
  better_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  guess_score_a INTEGER,
  guess_score_b INTEGER,
  guess_winner TEXT,
  amount INTEGER NOT NULL CHECK (amount >= 50 AND amount <= 200),
  settled BOOLEAN DEFAULT false,
  settlement TEXT,
  room_id UUID REFERENCES rooms(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS room_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS betters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. 启用 RLS
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE betters ENABLE ROW LEVEL SECURITY;

-- 3. 创建策略（前端使用 anon key，允许公开读写，应用层做权限控制）
CREATE POLICY "rooms_all" ON rooms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "matches_all" ON matches FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "bets_all" ON bets FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "room_settings_all" ON room_settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "betters_all" ON betters FOR ALL USING (true) WITH CHECK (true);

-- 4. 创建默认房间
-- 房间密码: wcsz2026
INSERT INTO rooms (name, password_hash) VALUES ('默认房间', '3654aea138a1e5989d2333cabe3c2682f664821fda7ce9cdbdf7074716a3ffdd')
ON CONFLICT DO NOTHING;

-- 管理员密码: Nadmin888
INSERT INTO room_settings (key, value) VALUES ('admin_password_hash', 'ba7fa7c4a4f0a180a3a0b704c63942168c8404a461b7a644b0232face426ced6')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 5. 预置比赛数据（时间均为北京时间 UTC+8，转换为 UTC 存储）
INSERT INTO matches (team_a, team_b, match_time, room_id) VALUES
  ('阿根廷', '埃及',   '2026-07-07 16:00:00+00', (SELECT id FROM rooms LIMIT 1)),
  ('瑞士',   '哥伦比亚', '2026-07-07 20:00:00+00', (SELECT id FROM rooms LIMIT 1)),
  ('法国',   '摩洛哥',   '2026-07-09 20:00:00+00', (SELECT id FROM rooms LIMIT 1)),
  ('西班牙', '比利时',   '2026-07-10 19:00:00+00', (SELECT id FROM rooms LIMIT 1)),
  ('挪威',   '英格兰',   '2026-07-11 21:00:00+00', (SELECT id FROM rooms LIMIT 1));
