import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(req: NextRequest, context: { params: Promise<{ department: string }> }) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json([], { status: 401 });
  const { department } = await context.params;
  const res = await fetch(`${API_BASE_URL}/users/supervisors/${encodeURIComponent(department)}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  const data = await res.json().catch(() => []);
  return NextResponse.json(res.ok ? data : []);
}












