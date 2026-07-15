-- ============================================================
-- ナーチャリング共有ボード テーブル定義（認証必須・許可アドレス限定版）
-- Supabase ダッシュボード → SQL Editor に丸ごと貼って RUN するだけ
-- （Re:alize と同じプロジェクトに相乗り。既存テーブルには一切触れません）
-- ============================================================
-- ★このSQLを実行すると:
--   ・下の3アドレスでログインした人「だけ」が読み書きできる
--   ・ログインしていない人(anon)は 1文字も読めない・書けない
--   ・許可リスト外のアドレスは、ログインできてもデータが見えない
-- ============================================================

-- 1. タスク（ToDoリスト本体）
CREATE TABLE IF NOT EXISTS nurture_tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  title       TEXT NOT NULL,
  owner       TEXT NOT NULL DEFAULT 'kumiko',
  status      TEXT NOT NULL DEFAULT 'todo',
  memo        TEXT DEFAULT '',
  sort_order  BIGINT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  done_at     TIMESTAMPTZ
);

-- 2. 議題ログ
CREATE TABLE IF NOT EXISTS nurture_topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  content     TEXT NOT NULL,
  author      TEXT DEFAULT 'kumiko',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 今つまずいていること（人ごとに1枠）
CREATE TABLE IF NOT EXISTS nurture_stuck (
  board_id    TEXT NOT NULL DEFAULT 'client1',
  owner       TEXT NOT NULL,
  content     TEXT DEFAULT '',
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (board_id, owner)
);

-- 4. ボード設定
CREATE TABLE IF NOT EXISTS nurture_meta (
  board_id      TEXT PRIMARY KEY,
  title         TEXT DEFAULT 'ナーチャリング共有ボード',
  client_label  TEXT DEFAULT 'クライアント',
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 経営からの期待・注視指標（役員が記入、担当者が確認）
CREATE TABLE IF NOT EXISTS nurture_directives (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  title       TEXT NOT NULL,          -- 期待・方針の見出し
  body        TEXT DEFAULT '',        -- 詳細
  metric      TEXT DEFAULT '',        -- 追うべき数値／KPI
  status      TEXT DEFAULT 'active',  -- active / achieved
  author      TEXT DEFAULT 'executive',
  sort_order  BIGINT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 課題（ボトルネック）解決トラッカー
CREATE TABLE IF NOT EXISTS nurture_issues (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id    TEXT NOT NULL DEFAULT 'client1',
  title       TEXT NOT NULL,
  detail      TEXT DEFAULT '',
  status      TEXT DEFAULT 'open',    -- open / in_progress / resolved
  owner       TEXT DEFAULT '',        -- 主担当（kumiko/client/executive/任意）
  resolution  TEXT DEFAULT '',        -- どう解決したか
  opened_on   DATE DEFAULT CURRENT_DATE,
  resolved_on DATE,
  sort_order  BIGINT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 成果物ログ（弊社提出物）
CREATE TABLE IF NOT EXISTS nurture_deliverables (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id     TEXT NOT NULL DEFAULT 'client1',
  title        TEXT NOT NULL,
  category     TEXT DEFAULT '',       -- レポート/バナー/LP/配信文 等
  url          TEXT DEFAULT '',       -- Drive/Docs等のリンク
  summary      TEXT DEFAULT '',
  delivered_on DATE DEFAULT CURRENT_DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------
-- RLS：許可アドレスでログインした人だけ CRUD 可（anonは全拒否）
-- 許可アドレスを増減したい時は、下の ARRAY[...] の中身を編集して再RUN
-- ------------------------------------------------------------
ALTER TABLE nurture_tasks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_topics       ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_stuck        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_meta         ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_directives   ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_issues       ENABLE ROW LEVEL SECURITY;
ALTER TABLE nurture_deliverables ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  t TEXT;
  emails TEXT := '''4morikawa5@gmail.com'',''k.morikawa@merone.jp'',''anchidaietrieyoshida@gmail.com''';
BEGIN
  FOREACH t IN ARRAY ARRAY['nurture_tasks','nurture_topics','nurture_stuck','nurture_meta','nurture_directives','nurture_issues','nurture_deliverables']
  LOOP
    -- 旧anonポリシーを削除（前の公開版から作り替えるため）
    EXECUTE format('DROP POLICY IF EXISTS "anon_select" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_insert" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_update" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "anon_delete" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "allow_members" ON %I;', t);
    -- 許可アドレスでログイン済みの人だけ 全操作OK
    EXECUTE format(
      'CREATE POLICY "allow_members" ON %I FOR ALL TO authenticated '
      || 'USING ((auth.jwt() ->> ''email'') IN (%s)) '
      || 'WITH CHECK ((auth.jwt() ->> ''email'') IN (%s));',
      t, emails, emails);
  END LOOP;
END $$;

-- 初期メタ行
INSERT INTO nurture_meta (board_id, title, client_label)
VALUES ('client1', 'ナーチャリング共有ボード', 'クライアント')
ON CONFLICT (board_id) DO NOTHING;

-- 完了！ このあと Auth の URL 設定（setup.html の STEP参照）をして index.html を開く
