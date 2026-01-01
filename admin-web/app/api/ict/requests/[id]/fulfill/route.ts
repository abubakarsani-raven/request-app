import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function PUT(
  req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) return NextResponse.json({ message: 'Unauthorized' }, { status: 401 });
  
  const { id } = await context.params;
  const body = await req.json();
  
  const res = await fetch(`${API_BASE_URL}/ict/requests/${id}/fulfill`, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    cache: 'no-store',
  });
  
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}

