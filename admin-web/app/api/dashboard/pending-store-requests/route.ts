import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(req: NextRequest) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json(0);
  const res = await fetch(`${API_BASE_URL}/requests/store`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  if (!res.ok) return NextResponse.json(0);
  const data = await res.json();
  const count = Array.isArray(data)
    ? data.filter((r: any) => r.status === 'store_pending').length
    : 0;
  return NextResponse.json(count);
}

