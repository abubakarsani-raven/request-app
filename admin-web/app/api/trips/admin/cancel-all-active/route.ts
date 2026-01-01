import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function POST(req: NextRequest) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const res = await fetch(`${API_BASE_URL}/trips/admin/cancel-all-active`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    cache: 'no-store',
  });

  if (!res.ok) {
    const errorText = await res.text().catch(() => 'Failed to cancel active trips');
    return NextResponse.json({ error: errorText || 'Failed to cancel active trips' }, { status: 500 });
  }

  const data = await res.json().catch(() => ({ cancelledTrips: 0 }));
  return NextResponse.json(data);
}









