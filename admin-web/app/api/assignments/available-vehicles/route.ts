import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(req: NextRequest) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json([]);
  const res = await fetch(`${API_BASE_URL}/assignments/available-vehicles`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  const data = await res.json().catch(() => []);
  return NextResponse.json(res.ok ? data : []);
}


