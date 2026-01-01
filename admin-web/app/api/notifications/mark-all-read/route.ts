import { NextRequest, NextResponse } from "next/server";
import { getApiBaseUrl } from '@/lib/server-config';


export async function PUT(request: NextRequest) {
  try {
    const token = request.cookies.get("access_token")?.value;

    if (!token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const API_BASE_URL = getApiBaseUrl(); // Call at runtime
    const response = await fetch(`${API_BASE_URL}/notifications/mark-all-read`, {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: error || "Failed to mark all notifications as read" }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error: any) {
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
