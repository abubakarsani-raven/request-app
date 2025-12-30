/**
 * Application configuration
 * Centralized configuration for API and WebSocket URLs
 * 
 * Environment selection:
 * - Set NEXT_PUBLIC_ENV to 'development' for local backend
 * - Set NEXT_PUBLIC_ENV to 'production' for Railway backend
 * - Or set NEXT_PUBLIC_API_BASE_URL directly to override
 */

// Railway Production Backend URL
const RAILWAY_API_URL = 'https://request-app-production.up.railway.app';
const RAILWAY_WS_URL = 'wss://request-app-production.up.railway.app';

// Local Development URLs
const LOCAL_API_URL = 'http://localhost:4000';
const LOCAL_WS_URL = 'ws://localhost:4000';

// Get environment mode (development or production)
const ENV = process.env.NEXT_PUBLIC_ENV || process.env.NODE_ENV || 'production';

// Determine which URLs to use based on environment
const getApiUrl = () => {
  // If explicitly set, use that
  if (process.env.NEXT_PUBLIC_API_BASE_URL) {
    return process.env.NEXT_PUBLIC_API_BASE_URL;
  }
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  
  // Otherwise, use environment-based selection
  return ENV === 'development' ? LOCAL_API_URL : RAILWAY_API_URL;
};

const getWsUrl = () => {
  // If explicitly set, use that
  if (process.env.NEXT_PUBLIC_WS_URL) {
    return process.env.NEXT_PUBLIC_WS_URL;
  }
  
  // Otherwise, use environment-based selection
  return ENV === 'development' ? LOCAL_WS_URL : RAILWAY_WS_URL;
};

// Export the configured URLs
export const API_BASE_URL = getApiUrl();
export const WS_URL = getWsUrl();

// Export environment info
export const isDevelopment = ENV === 'development';
export const isProduction = ENV === 'production';
export const currentEnv = ENV;

// Log configuration in development
if (typeof window !== 'undefined' && isDevelopment) {
  console.log('🔧 API Configuration:', {
    environment: ENV,
    apiUrl: API_BASE_URL,
    wsUrl: WS_URL,
  });
}
