import { NextRequest, NextResponse } from "next/server";
import { getApiBaseUrl } from '@/lib/server-config';


export async function GET(request: NextRequest) {
  try {
    const token = request.cookies.get("access_token")?.value;
    if (!token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const API_BASE_URL = getApiBaseUrl(); // Call at runtime
    const res = await fetch(`${API_BASE_URL}/ict/items/low-stock/all`, {
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
    });

    if (!res.ok) {
      return NextResponse.json({ error: "Failed to fetch low stock items" }, { status: res.status });
    }

    const data = await res.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

