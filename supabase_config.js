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

  // このボードの識別子。URLの ?board=xxx で切り替え（例 ?board=riet / famm / abcash）。
  // 未指定時は client1（開発・デモ用）。
  boardId: (function(){ try{ return (new URLSearchParams(location.search).get('board') || 'client1').toLowerCase(); }catch(e){ return 'client1'; } })(),

  get enabled(){ return !!(this.url && this.anonKey); }
};
