import { NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/server-config';

export async function POST(request: Request) {
  // Always log the request start (including production for debugging)
  const requestId = Date.now().toString(36);
  const startTime = Date.now();
  
  try {
    const body = await request.json();
    const API_BASE_URL = getApiBaseUrl(); // Call at runtime
    
    // Ensure proper URL construction
    // API_BASE_URL is normalized (no trailing slash), so we can safely append /auth/login
    let backendUrl = `${API_BASE_URL}/auth/login`;
    
    // Remove any accidental double slashes (but preserve http:// and https://)
    // This handles cases where API_BASE_URL might have a trailing slash despite normalization
    backendUrl = backendUrl.replace(/([^:]\/)\/+/g, '$1');
    
    // Final validation - ensure URL is valid
    try {
      new URL(backendUrl); // This will throw if URL is invalid
    } catch (e) {
      console.error(`[login:${requestId}] ❌ ERROR: Invalid URL construction: ${backendUrl}`);
      console.error(`[login:${requestId}] API_BASE_URL was: ${API_BASE_URL}`);
      throw new Error(`Invalid backend URL: ${backendUrl}`);
    }
    
    // Comprehensive logging - ALWAYS log in production too for debugging
    console.log(`[login:${requestId}] ===== LOGIN REQUEST START =====`);
    console.log(`[login:${requestId}] Frontend URL (Next.js API route): /api/auth/login`);
    console.log(`[login:${requestId}] Backend URL (Railway/NestJS): ${backendUrl}`);
    console.log(`[login:${requestId}] Environment:`, {
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
      NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
      NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
      VERCEL_URL: process.env.VERCEL_URL,
      API_BASE_URL_RESOLVED: API_BASE_URL,
    });
    console.log(`[login:${requestId}] Request body (email only):`, { 
      email: body.email,
      hasPassword: !!body.password 
    });
    
    // Verify we're not accidentally calling the frontend
    if (backendUrl.includes('vercel.app') || backendUrl.includes('localhost:3000')) {
      console.error(`[login:${requestId}] ⚠️  ERROR: Backend URL points to frontend! This is wrong!`);
      console.error(`[login:${requestId}] Backend URL should be Railway, not: ${backendUrl}`);
    }
    
    console.log(`[login:${requestId}] Making fetch request to backend...`);
    const res = await fetch(backendUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      cache: 'no-store',
    });
    
    console.log(`[login:${requestId}] Backend response status: ${res.status} ${res.statusText}`);
    console.log(`[login:${requestId}] Backend response URL: ${res.url}`);

    const data = await res.json();
    const duration = Date.now() - startTime;
    
    if (!res.ok) {
      // Always log errors (including production)
      console.error(`[login:${requestId}] ❌ Backend error response:`, {
        status: res.status,
        statusText: res.statusText,
        message: data?.message,
        backendUrl,
        responseUrl: res.url,
        duration: `${duration}ms`,
        errorData: data,
      });
      
      return NextResponse.json({ 
        message: data?.message || 'Login failed',
        // Include debug info in production for troubleshooting
        ...(process.env.NODE_ENV === 'production' && {
          debug: {
            backendUrl,
            responseUrl: res.url,
            requestId,
          }
        })
      }, { status: res.status });
    }
    
    console.log(`[login:${requestId}] ✅ Backend success response:`, {
      hasToken: !!data?.access_token,
      hasUser: !!data?.user,
      userEmail: data?.user?.email,
      duration: `${duration}ms`,
    });

    const token = data?.access_token as string | undefined;
    if (!token) {
      console.error(`[login:${requestId}] ❌ No token in backend response:`, data);
      return NextResponse.json({ message: 'No token in response' }, { status: 500 });
    }

    console.log(`[login:${requestId}] Setting HTTP-only cookie and returning success`);
    const response = NextResponse.json({ user: data.user }, { status: 200 });
    response.cookies.set('access_token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });
    
    const totalDuration = Date.now() - startTime;
    console.log(`[login:${requestId}] ===== LOGIN REQUEST SUCCESS (${totalDuration}ms) =====`);
    return response;
  } catch (err: any) {
    // Enhanced error logging - ALWAYS log in production too
    const API_BASE_URL = getApiBaseUrl();
    const duration = Date.now() - startTime;
    
    console.error(`[login:${requestId}] ❌❌❌ UNEXPECTED ERROR ❌❌❌`);
    console.error(`[login:${requestId}] Error details:`, {
      error: err.message,
      errorName: err.name,
      stack: err.stack,
      backendUrl: `${API_BASE_URL}/auth/login`,
      duration: `${duration}ms`,
      env: {
        NODE_ENV: process.env.NODE_ENV,
        NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
        NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
        NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
        VERCEL_URL: process.env.VERCEL_URL,
      },
    });
    
    // Check if it's a network error (backend unreachable)
    if (err.message?.includes('fetch failed') || err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND') {
      console.error(`[login:${requestId}] ⚠️  Network error - Backend may be unreachable at: ${API_BASE_URL}`);
    }
    
    return NextResponse.json({ 
      message: err.message || 'Unexpected error',
      // Include debug info in production for troubleshooting
      ...(process.env.NODE_ENV === 'production' && { 
        debug: { 
          backendUrl: `${API_BASE_URL}/auth/login`,
          requestId,
          errorType: err.name,
        } 
      })
    }, { status: 500 });
  }
}


