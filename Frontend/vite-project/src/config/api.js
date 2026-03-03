/**
 * API Configuration
 *
 * This file centralizes all API URL configuration.
 * - Development: defaults to http://localhost:5000
 * - Production: set VITE_API_URL environment variable
 */

// Default to localhost for development (port 5001 to avoid macOS AirPlay conflict)
const DEFAULT_API_URL = 'http://localhost:5001';

// Get API URL from environment or use default
const API_URL = import.meta.env.VITE_API_URL || DEFAULT_API_URL;

// Runtime validation - prevent shipping with bad URLs
function validateApiUrl(url) {
  // Block the old hardcoded IP
  if (url.includes('104.35.175.95')) {
    throw new Error(
      `[NoFlame] Invalid API URL: ${url}\n` +
      `The IP 104.35.175.95 is no longer valid.\n` +
      `Set VITE_API_URL in your .env file or use the default localhost.`
    );
  }

  // Warn about https with raw IP addresses (usually a mistake)
  const httpsIpPattern = /^https:\/\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;
  if (httpsIpPattern.test(url)) {
    console.warn(
      `[NoFlame] Warning: Using HTTPS with an IP address (${url}).\n` +
      `This usually requires a valid SSL certificate. ` +
      `Consider using HTTP for development or a domain name for production.`
    );
  }

  return url;
}

// Validate and export
export const BASE_URL = validateApiUrl(API_URL);

// Log the API URL in development for debugging
if (import.meta.env.DEV) {
  console.log(`[NoFlame] API URL: ${BASE_URL}`);
}
