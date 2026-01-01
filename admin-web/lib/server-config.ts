/**
 * Server-side configuration for API routes
 * Uses the same logic as config.ts but optimized for server-side usage
 * 
 * IMPORTANT: This function is called at runtime to ensure environment variables
 * are available in serverless environments like Vercel
 */

// Railway Production Backend URL
const RAILWAY_API_URL = 'https://request-app-production.up.railway.app';

// Local Development URLs
const LOCAL_API_URL = 'http://localhost:4000';

// Helper to normalize URL (remove trailing slash)
function normalizeUrl(url: string): string {
  if (!url) return url;
  return url.replace(/\/+$/, ''); // Remove trailing slashes
}

// Determine which URL to use based on environment (called at runtime)
export function getApiBaseUrl(): string {
  // Get environment mode (evaluated at runtime) - needed for logging
  const ENV = process.env.NEXT_PUBLIC_ENV || process.env.NODE_ENV || 'production';
  
  let url: string;
  
  // If explicitly set, use that
  if (process.env.NEXT_PUBLIC_API_BASE_URL) {
    url = process.env.NEXT_PUBLIC_API_BASE_URL;
    console.log('[server-config] Using NEXT_PUBLIC_API_BASE_URL:', url);
  } else if (process.env.NEXT_PUBLIC_API_URL) {
    url = process.env.NEXT_PUBLIC_API_URL;
    console.log('[server-config] Using NEXT_PUBLIC_API_URL:', url);
  } else {
    // Otherwise, use environment-based selection
    url = ENV === 'development' ? LOCAL_API_URL : RAILWAY_API_URL;
  }
  
  // Normalize URL (remove trailing slash to prevent // in path construction)
  url = normalizeUrl(url);
  
  // Validate URL
  if (!url || url.trim() === '') {
    console.error('[server-config] ❌ ERROR: API_BASE_URL is empty or undefined!');
    throw new Error('API_BASE_URL is not configured');
  }
  
  // Check for double slashes in the base URL itself (except http:// or https://)
  if (url.includes('//') && !url.match(/^https?:\/\//)) {
    console.error('[server-config] ❌ ERROR: Invalid URL format (contains //):', url);
    throw new Error(`Invalid API_BASE_URL format: ${url}`);
  }
  
  // ALWAYS log the resolved URL (including production) for debugging
  console.log('[server-config] Resolved API_BASE_URL:', {
    url,
    source: ENV === 'development' ? 'LOCAL (development)' : 'RAILWAY (production default)',
    env: {
      NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL || '(not set)',
      NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '(not set)',
      VERCEL_URL: process.env.VERCEL_URL || '(not set)',
    },
  });
  
  // Warn if we're in production but URL looks wrong
  if (ENV === 'production' && (url.includes('localhost') || url.includes('127.0.0.1'))) {
    console.error('[server-config] ⚠️  WARNING: Production environment but using localhost URL!');
  }
  
  // Warn if URL points to Vercel frontend instead of backend
  if (url.includes('vercel.app') && !url.includes('railway')) {
    console.error('[server-config] ⚠️  WARNING: URL appears to point to Vercel frontend, not Railway backend!');
    console.error('[server-config] Expected Railway URL, got:', url);
  }
  
  return url;
}

// Export a getter function that calls getApiBaseUrl() at runtime
// This ensures environment variables are read fresh on each request in serverless environments
export const API_BASE_URL = getApiBaseUrl();
