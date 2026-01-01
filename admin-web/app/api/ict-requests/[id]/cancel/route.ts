import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function PUT(req: NextRequest, context: { params: Promise<{ id: string }> }) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  const { id } = await context.params;
  const body = await req.json().catch(() => ({}));
  const res = await fetch(`${API_BASE_URL}/requests/ict/${id}/cancel`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ reason: body?.reason ?? null }),
  });
  const data = await res.json().catch(() => ({}));
  return NextResponse.json(data, { status: res.status });
}

