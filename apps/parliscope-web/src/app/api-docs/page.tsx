interface Endpoint {
  method: string;
  path: string;
  description: string;
  params?: string[];
}

const ENDPOINTS: Endpoint[] = [
  {
    method: "GET",
    path: "/api/sessions",
    description: "会期一覧を取得（ページネーション対応）",
    params: ["page", "limit"],
  },
  {
    method: "GET",
    path: "/api/sessions/:id",
    description: "会期詳細を取得（法案一覧含む）",
  },
  {
    method: "GET",
    path: "/api/bills",
    description: "法案一覧を取得（フィルタ・ページネーション対応）",
    params: ["page", "limit", "status", "sessionId", "category"],
  },
  {
    method: "GET",
    path: "/api/bills/:id",
    description: "法案詳細を取得（投票・議論含む）",
  },
  {
    method: "GET",
    path: "/api/politicians",
    description: "議員一覧を取得（フィルタ・ページネーション対応）",
    params: ["page", "limit", "party", "chamber", "prefecture"],
  },
  {
    method: "GET",
    path: "/api/politicians/:id",
    description: "議員詳細を取得（投票履歴含む）",
  },
  {
    method: "GET",
    path: "/api/stats",
    description: "ダッシュボード統計データを取得",
  },
  {
    method: "GET",
    path: "/api/agenda/current",
    description: "現在の国会議題（直近会議一覧）を取得",
    params: ["days", "limit", "house"],
  },
];

export default function ApiDocsPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#0f0f23] to-[#1a1033]">
      <div className="mx-auto max-w-4xl px-6 py-12">
        <div className="mb-8">
          <h2 className="mb-2 text-3xl font-bold tracking-tight text-white">API ドキュメント</h2>
          <p className="text-[#8b949e]">
            ParliScope APIはRESTful設計で、JSON形式でデータを返します。認証不要で自由に利用できます。
          </p>
        </div>

        <div className="mb-8">
          <div className="rounded-xl border border-white/[0.06] bg-white/[0.03] p-6">
            <h3 className="mb-3 text-lg font-semibold text-white">共通レスポンス形式（ページネーション）</h3>
            <pre className="overflow-x-auto rounded-lg bg-[#0d1117] p-4 text-sm text-emerald-400">
              {`{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}`}
            </pre>
          </div>
        </div>

        <div className="space-y-4">
          {ENDPOINTS.map((ep) => (
            <div
              key={ep.path}
              className="rounded-xl border border-white/[0.06] bg-white/[0.03] p-5 transition-all duration-300 hover:border-white/[0.12] hover:bg-white/[0.05]"
            >
              <div className="flex items-center gap-3">
                <span className="rounded-md bg-emerald-500/15 px-2.5 py-1 text-xs font-bold text-emerald-400">
                  {ep.method}
                </span>
                <code className="text-sm font-medium text-white">{ep.path}</code>
              </div>
              <p className="mt-2.5 text-sm text-[#8b949e]">{ep.description}</p>
              {ep.params && (
                <div className="mt-3">
                  <span className="text-xs text-[#6b7280]">パラメータ: </span>
                  {ep.params.map((p) => (
                    <code
                      key={p}
                      className="mr-1.5 rounded-md bg-white/[0.06] px-2 py-0.5 text-xs text-indigo-300"
                    >
                      {p}
                    </code>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
