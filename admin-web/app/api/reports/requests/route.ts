import { NextRequest, NextResponse } from "next/server";
import { getApiBaseUrl } from "@/lib/server-config";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const token = request.cookies.get("access_token")?.value;

    if (!token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const params = new URLSearchParams();
    searchParams.forEach((value, key) => {
      if (value && value !== "__all__") {
        params.append(key, value);
      }
    });
    // Ensure reportType is set for the backend
    if (!params.has("reportType")) {
      params.append("reportType", "REQUESTS");
    }

    const API_BASE_URL = getApiBaseUrl(); // Call at runtime
    const response = await fetch(`${API_BASE_URL}/reports/requests?${params.toString()}`, {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      let errorMessage = "Failed to fetch report";
      try {
        const errorData = await response.json();
        errorMessage = errorData.message || errorData.error || errorMessage;
      } catch {
        const errorText = await response.text();
        errorMessage = errorText || errorMessage;
      }
      console.error("Reports API error:", errorMessage, response.status);
      return NextResponse.json({ error: errorMessage }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error: any) {
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
