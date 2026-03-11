const KOKKAI_BASE = "https://kokkai.ndl.go.jp/api";

export interface DietMeetingRecord {
  issueID: string;
  session: number;
  nameOfHouse: string;
  nameOfMeeting: string;
  issue: string;
  date: string;
  meetingURL: string | null;
}

interface KokkaiMeetingListResponse {
  numberOfRecords: number;
  numberOfReturn: number;
  startRecord: number;
  nextRecordPosition: number | null;
  meetingRecord?: DietMeetingRecord[];
}

function formatJstDate(date: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function buildUrl(params: {
  from: string;
  until: string;
  maximumRecords: number;
  nameOfHouse?: string;
}): string {
  const url = new URL(`${KOKKAI_BASE}/meeting_list`);
  url.searchParams.set("recordPacking", "json");
  url.searchParams.set("from", params.from);
  url.searchParams.set("until", params.until);
  url.searchParams.set("maximumRecords", String(params.maximumRecords));
  if (params.nameOfHouse) {
    url.searchParams.set("nameOfHouse", params.nameOfHouse);
  }
  return url.toString();
}

export async function fetchCurrentDietAgenda(options?: {
  days?: number;
  maximumRecords?: number;
  house?: string;
}) {
  const days = Math.min(Math.max(options?.days ?? 7, 1), 31);
  const maximumRecords = Math.min(Math.max(options?.maximumRecords ?? 30, 1), 100);

  const now = new Date();
  const fromDate = new Date(now.getTime() - (days - 1) * 24 * 60 * 60 * 1000);
  const from = formatJstDate(fromDate);
  const until = formatJstDate(now);

  const url = buildUrl({
    from,
    until,
    maximumRecords,
    nameOfHouse: options?.house,
  });

  const res = await fetch(url, {
    cache: "no-store",
    headers: {
      "User-Agent": "open-japan-politech-platform/parliscope",
    },
  });

  if (!res.ok) {
    throw new Error(`Kokkai API error: ${res.status} ${res.statusText}`);
  }

  const json = (await res.json()) as KokkaiMeetingListResponse;
  const records = (json.meetingRecord ?? []).sort((a, b) => {
    if (a.date !== b.date) {
      return a.date < b.date ? 1 : -1;
    }
    return a.session < b.session ? 1 : -1;
  });

  return {
    from,
    until,
    total: json.numberOfRecords ?? records.length,
    records,
  };
}
