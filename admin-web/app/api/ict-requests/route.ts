import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/server-config';


export async function GET(req: NextRequest) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json([], { status: 200 });
  const API_BASE_URL = getApiBaseUrl(); // Call at runtime
  const res = await fetch(`${API_BASE_URL}/requests/ict`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  const data = await res.json();
  return NextResponse.json(res.ok ? data : [], { status: 200 });
}

