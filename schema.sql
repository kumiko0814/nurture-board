-- ============================================================
-- ナーチャリング共有ボード テーブル定義
-- Supabase ダッシュボード → SQL Editor に丸ごと貼って RUN するだけ
-- （Re:alize と同じプロジェクトに相乗り。既存テーブルには一切触れません）
-- ============================================================

-- 1. タスク（ToDoリスト本体）
CREATE TABLE IF NOT EXISTS nurture_tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  title       TEXT NOT NULL,
  owner       TEXT NOT NULL DEFAULT 'kumiko',   -- 'kumiko' or 'client'
  status      TEXT NOT NULL DEFAULT 'todo',      -- 'todo' | 'doing' | 'done'
  memo        TEXT DEFAULT '',                   -- つまずき・補足メモ（タスク単位）
  sort_order  BIGINT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  done_at     TIMESTAMPTZ
);

-- 2. 議題ログ（話したこと・決まったことの時系列記録）
CREATE TABLE IF NOT EXISTS nurture_topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  content     TEXT NOT NULL,
  author      TEXT DEFAULT 'kumiko',             -- 誰がアップしたか
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 今つまずいていること（人ごとに1枠・常時見える化）
CREATE TABLE IF NOT EXISTS nurture_stuck (
  board_id    TEXT NOT NULL DEFAULT 'client1',
  owner       TEXT NOT NULL,                     -- 'kumiko' or 'client'
  content     TEXT DEFAULT '',
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (board_id, owner)
);

-- 4. ボード設定（クライアント名などの表示名）
CREATE TABLE IF NOT EXISTS nurture_meta (
  board_id      TEXT PRIMARY KEY,
  title         TEXT DEFAULT 'ナーチャリング共有ボード',
  client_label  TEXT DEFAULT 'クライアント',
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------
-- RLS（誰でも読める・誰でも書ける = 2人運用に十分。realize と同じ方針）
-- ------------------------------------------------------------
ALTER TABLE nurture_tasks  ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_stuck  ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_meta   ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['nurture_tasks','nurture_topics','nurture_stuck','nurture_meta']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "anon_select" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_insert" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_update" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_delete" ON %I;', t);
    EXECUTE format('CREATE POLICY "anon_select" ON %I FOR SELECT TO anon USING (true);', t);
    EXECUTE format('CREATE POLICY "anon_insert" ON %I FOR INSERT TO anon WITH CHECK (true);', t);
    EXECUTE format('CREATE POLICY "anon_update" ON %I FOR UPDATE TO anon USING (true);', t);
    EXECUTE format('CREATE POLICY "anon_delete" ON %I FOR DELETE TO anon USING (true);', t);
  END LOOP;
END $$;

-- 初期メタ行（無ければ作る）
INSERT INTO nurture_meta (board_id, title, client_label)
VALUES ('client1', 'ナーチャリング共有ボード', 'クライアント')
ON CONFLICT (board_id) DO NOTHING;

-- 完了！ index.html を開けば動きます。
