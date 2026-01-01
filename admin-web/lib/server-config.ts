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

// Determine which URL to use based on environment (called at runtime)
export function getApiBaseUrl(): string {
  // If explicitly set, use that
  if (process.env.NEXT_PUBLIC_API_BASE_URL) {
    return process.env.NEXT_PUBLIC_API_BASE_URL;
  }
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  
  // Get environment mode (evaluated at runtime)
  const ENV = process.env.NEXT_PUBLIC_ENV || process.env.NODE_ENV || 'production';
  
  // Otherwise, use environment-based selection
  const url = ENV === 'development' ? LOCAL_API_URL : RAILWAY_API_URL;
  
  // Log in development or if explicitly enabled
  if (process.env.DEBUG_API_CONFIG === 'true' || ENV === 'development') {
    console.log('[server-config] API_BASE_URL:', url, {
      NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
      NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    });
  }
  
  return url;
}

// Export a getter function that calls getApiBaseUrl() at runtime
// This ensures environment variables are read fresh on each request in serverless environments
export const API_BASE_URL = getApiBaseUrl();
