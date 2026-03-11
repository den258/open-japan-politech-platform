import { handleApiError, jsonResponse } from "@ojpp/api";
import type { NextRequest } from "next/server";
import { fetchCurrentDietAgenda } from "@/lib/diet-agenda";

export async function GET(request: NextRequest) {
  try {
    const url = new URL(request.url);
    const days = Number(url.searchParams.get("days") ?? "7");
    const maximumRecords = Number(url.searchParams.get("limit") ?? "30");
    const house = url.searchParams.get("house") ?? undefined;

    const data = await fetchCurrentDietAgenda({
      days: Number.isNaN(days) ? 7 : days,
      maximumRecords: Number.isNaN(maximumRecords) ? 30 : maximumRecords,
      house,
    });

    return jsonResponse(data);
  } catch (error) {
    return handleApiError(error);
  }
}
