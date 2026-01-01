import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(
  req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) {
    return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  }

  const { id } = await context.params;
  const res = await fetch(`${API_BASE_URL}/vehicles/drivers/${id}/assignments`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    cache: 'no-store',
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({ message: 'Failed to fetch driver assignments' }));
    return NextResponse.json(errorData, { status: res.status });
  }

  const data = await res.json().catch(() => []);
  return NextResponse.json(Array.isArray(data) ? data : [], { status: 200 });
}

