// ============================================================
// ナーチャリング共有ボード Supabase 設定
// ============================================================
// Re:alize と同じ Supabase プロジェクトを再利用しています。
// くみこがやることは「setup.html の SQL を1回貼るだけ」。
// URL / anonKey はそのままで OK（別クライアント用に分けたくなったら差し替え）。
// ============================================================

const SUPABASE_CONFIG = {
  url: 'https://inrvprlyobghviklulcv.supabase.co',
  anonKey: 'sb_publishable_ZrCNcsRHMci-l7Fns8QtIA_X22XZGJp',

  // このボードの識別子。クライアントごとに分けたくなったら変えるだけで別ボードになる。
  boardId: 'client1',

  get enabled(){ return !!(this.url && this.anonKey); }
};
