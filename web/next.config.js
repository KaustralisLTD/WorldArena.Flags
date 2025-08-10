const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
  // Exclude problematic files from precaching
  buildExcludes: [
    /Logo-WorldArena\.Games-2-58x58-old\.png$/,
    /\.map$/,
    /manifest$/,
    /build-manifest\.json$/,
    /react-loadable-manifest\.json$/
  ],
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/restcountries\.com\/.*$/i,
      handler: 'CacheFirst',
      options: {
        cacheName: 'countries-api',
        expiration: {
          maxEntries: 1,
          maxAgeSeconds: 24 * 60 * 60, // 24 hours
        },
      },
    },
    {
      urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/i,
      handler: 'CacheFirst',
      options: {
        cacheName: 'images',
        expiration: {
          maxEntries: 200,
          maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
        },
      },
    },
    {
      urlPattern: /^https:\/\/flags\.worldarena\.games\/.*$/i,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'api-cache',
        expiration: {
          maxEntries: 50,
          maxAgeSeconds: 5 * 60, // 5 minutes
        },
        networkTimeoutSeconds: 10,
      },
    },
  ],
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Trailing slash for better compatibility
  trailingSlash: true,
  
  // Image optimization
  images: {
    domains: [
      'flagcdn.com',
      'upload.wikimedia.org',
      'restcountries.com',
    ],
    formats: ['image/webp', 'image/avif'],
    unoptimized: true, // Required for static export
  },

  // Compression
  compress: true,

  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
  
  // Static export configuration
  output: 'export',
  distDir: 'out',
  
  // Disable type checking during build to speed up
  typescript: {
    ignoreBuildErrors: true,
  },
  
  // Disable ESLint during build to speed up
  eslint: {
    ignoreDuringBuilds: true,
  },
};

module.exports = withPWA(nextConfig); 