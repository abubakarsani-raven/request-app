import { NextRequest, NextResponse } from 'next/server';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:4000';

export async function GET(req: NextRequest, context: { params: Promise<{ id: string }> }) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  const { id } = await context.params;
  const res = await fetch(`${API_BASE}/vehicles/requests/${id}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
  });
  if (!res.ok) {
    const errorData = await res.json().catch(() => ({ message: 'Failed to fetch request' }));
    return NextResponse.json(errorData, { status: res.status });
  }
  const data = await res.json();
  return NextResponse.json(data, { status: 200 });
}

