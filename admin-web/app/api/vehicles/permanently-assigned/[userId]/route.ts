import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(req: NextRequest, context: { params: Promise<{ userId: string }> }) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  const { userId } = await context.params;
  const res = await fetch(`${API_BASE_URL}/vehicles/permanently-assigned/${userId}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  const data = await res.json().catch(() => null);
  return NextResponse.json(data, { status: res.status });
}












