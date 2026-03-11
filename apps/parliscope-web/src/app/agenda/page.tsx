import Link from "next/link";
import { fetchCurrentDietAgenda } from "@/lib/diet-agenda";

export const dynamic = "force-dynamic";

interface PageProps {
  searchParams: Promise<{
    days?: string;
    house?: string;
  }>;
}

const FILTERS = [
  { value: 3, label: "3日" },
  { value: 7, label: "7日" },
  { value: 14, label: "14日" },
];

const HOUSES = [
  { value: "", label: "衆参すべて" },
  { value: "衆議院", label: "衆議院" },
  { value: "参議院", label: "参議院" },
];

export default async function AgendaPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const days = Math.max(1, Number(params.days) || 7);
  const house = params.house || "";

  const agenda = await fetchCurrentDietAgenda({
    days,
    maximumRecords: 50,
    house: house || undefined,
  });

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#0f0f23] to-[#1a1033]">
      <div className="mx-auto max-w-7xl px-6 py-12">
        <div className="mb-3">
          <h2 className="mb-2 text-3xl font-bold tracking-tight text-white">現在の国会議題（直近会議）</h2>
          <p className="text-[#8b949e]">
            国会会議録APIの会議一覧をもとに、直近の審議情報を表示しています。
            <span className="ml-1">対象期間: {agenda.from} 〜 {agenda.until}</span>
          </p>
        </div>

        <div className="mb-6 rounded-xl border border-amber-500/20 bg-amber-500/5 p-4 text-sm text-amber-300">
          この画面は会議録ベースです。厳密な当日「議事日程」そのものではなく、直近に開催された会議を議題情報として表示します。
        </div>

        <div className="mb-8 flex flex-wrap gap-3 rounded-xl border border-white/[0.06] bg-white/[0.03] p-4">
          <div className="flex items-center gap-2">
            <span className="text-xs text-[#6b7280]">期間</span>
            {FILTERS.map((f) => (
              <Link
                key={f.value}
                href={`/agenda?days=${f.value}&house=${house}`}
                className={`rounded-full border px-3 py-1.5 text-sm transition-all ${
                  days === f.value
                    ? "border-indigo-500/40 bg-indigo-500/20 text-indigo-300"
                    : "border-white/[0.1] text-[#8b949e] hover:border-white/[0.2] hover:text-white"
                }`}
              >
                {f.label}
              </Link>
            ))}
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-[#6b7280]">院</span>
            {HOUSES.map((h) => (
              <Link
                key={h.label}
                href={`/agenda?days=${days}&house=${h.value}`}
                className={`rounded-full border px-3 py-1.5 text-sm transition-all ${
                  house === h.value
                    ? "border-indigo-500/40 bg-indigo-500/20 text-indigo-300"
                    : "border-white/[0.1] text-[#8b949e] hover:border-white/[0.2] hover:text-white"
                }`}
              >
                {h.label}
              </Link>
            ))}
          </div>
        </div>

        <p className="mb-4 text-sm text-[#6b7280]">{agenda.records.length}件表示</p>

        <div className="space-y-3">
          {agenda.records.map((meeting) => (
            <article
              key={meeting.issueID}
              className="rounded-xl border border-white/[0.06] bg-white/[0.03] p-4 transition-all hover:border-white/[0.12] hover:bg-white/[0.05]"
            >
              <div className="mb-2 flex flex-wrap items-center gap-2 text-xs">
                <span className="rounded-full bg-indigo-500/20 px-2 py-1 text-indigo-300">第{meeting.session}回国会</span>
                <span className="rounded-full bg-white/[0.06] px-2 py-1 text-[#9aa4b2]">{meeting.nameOfHouse}</span>
                <span className="text-[#6b7280]">{meeting.date}</span>
              </div>

              <h3 className="text-lg font-semibold text-white">{meeting.nameOfMeeting}</h3>
              <p className="mt-1 text-sm text-[#8b949e]">{meeting.issue}</p>

              {meeting.meetingURL && (
                <a
                  href={meeting.meetingURL}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-3 inline-block text-sm text-cyan-300 hover:text-cyan-200"
                >
                  会議録を開く →
                </a>
              )}
            </article>
          ))}

          {agenda.records.length === 0 && (
            <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-8 text-center text-[#8b949e]">
              条件に一致する会議データがありません。
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
