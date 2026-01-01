import { NextRequest, NextResponse } from "next/server";
import { API_BASE_URL } from '@/lib/server-config';


export async function POST(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const token = request.cookies.get("access_token")?.value;

    if (!token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const params = new URLSearchParams();
    searchParams.forEach((value, key) => {
      params.append(key, value);
    });

    const response = await fetch(`${API_BASE_URL}/reports/export?${params.toString()}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: error || "Failed to export report" }, { status: response.status });
    }

    // Get the blob from the response
    const blob = await response.blob();
    
    // Return the blob with appropriate headers
    return new NextResponse(blob, {
      headers: {
        "Content-Type": response.headers.get("Content-Type") || "application/octet-stream",
        "Content-Disposition": response.headers.get("Content-Disposition") || "attachment",
      },
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
