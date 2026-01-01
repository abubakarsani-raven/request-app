import { NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/server-config';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const API_BASE_URL = getApiBaseUrl(); // Call at runtime
    const backendUrl = `${API_BASE_URL}/auth/login`;
    
    // Log in development
    if (process.env.NODE_ENV === 'development') {
      console.log('[login] Calling backend:', backendUrl);
    }
    
    const res = await fetch(backendUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      cache: 'no-store',
    });

    const data = await res.json();
    if (!res.ok) {
      // Log error details in development
      if (process.env.NODE_ENV === 'development') {
        console.error('[login] Backend error:', {
          status: res.status,
          statusText: res.statusText,
          message: data?.message,
          backendUrl,
        });
      }
      return NextResponse.json({ message: data?.message || 'Login failed' }, { status: res.status });
    }

    const token = data?.access_token as string | undefined;
    if (!token) {
      return NextResponse.json({ message: 'No token in response' }, { status: 500 });
    }

    const response = NextResponse.json({ user: data.user }, { status: 200 });
    response.cookies.set('access_token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });
    return response;
  } catch (err: any) {
    // Enhanced error logging
    const API_BASE_URL = getApiBaseUrl();
    console.error('[login] Unexpected error:', {
      error: err.message,
      stack: err.stack,
      backendUrl: `${API_BASE_URL}/auth/login`,
      env: {
        NODE_ENV: process.env.NODE_ENV,
        NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
        NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
      },
    });
    return NextResponse.json({ 
      message: err.message || 'Unexpected error',
      // Include backend URL in error for debugging (only in development)
      ...(process.env.NODE_ENV === 'development' && { 
        debug: { backendUrl: `${API_BASE_URL}/auth/login` } 
      })
    }, { status: 500 });
  }
}


