/**
 * Server-side configuration for API routes
 * Uses the same logic as config.ts but optimized for server-side usage
 */

// Railway Production Backend URL
const RAILWAY_API_URL = 'https://request-app-production.up.railway.app';

// Local Development URLs
const LOCAL_API_URL = 'http://localhost:4000';

// Get environment mode (development or production)
const ENV = process.env.NEXT_PUBLIC_ENV || process.env.NODE_ENV || 'production';

// Determine which URL to use based on environment
export function getApiBaseUrl(): string {
  // If explicitly set, use that
  if (process.env.NEXT_PUBLIC_API_BASE_URL) {
    return process.env.NEXT_PUBLIC_API_BASE_URL;
  }
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  
  // Otherwise, use environment-based selection
  return ENV === 'development' ? LOCAL_API_URL : RAILWAY_API_URL;
}

// Export the configured URL (computed once)
export const API_BASE_URL = getApiBaseUrl();
