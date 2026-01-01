import { NextRequest, NextResponse } from 'next/server';
import { API_BASE_URL } from '@/lib/server-config';


export async function GET(req: NextRequest) {
  const token = req.cookies.get('access_token')?.value;
  if (!token) {
    return NextResponse.json([], { status: 200 });
  }
  
  // Use /vehicles/requests endpoint - returns all vehicle requests
  // For admin users, this should return all vehicle requests they can see
  const res = await fetch(`${API_BASE_URL}/vehicles/requests`, {
    headers: { 
      Authorization: `Bearer ${token}`,
    },
    cache: 'no-store',
  });
  
  if (!res.ok) {
    console.error(`Failed to fetch vehicle requests: ${res.status} ${res.statusText}`);
    return NextResponse.json([], { status: 200 });
  }
  
  const data = await res.json();
  return NextResponse.json(Array.isArray(data) ? data : [], { status: 200 });
}

