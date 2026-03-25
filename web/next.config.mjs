/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Path relativi alla root del progetto (cartella `web/`). Gli assoluti con __dirname
    // su Vercel si concatenano di nuovo alla root → doppio `.../web/.../web/.native/...` (ENOENT).
    outputFileTracingIncludes: {
      "/api/files": ["./.native/fullio/**/*"],
      "/api/files/[...path]": ["./.native/fullio/**/*"],
    },
  },
  async headers() {
    return [
      {
        source: "/api/:path*",
        headers: [
          { key: "Access-Control-Allow-Origin", value: "*" },
          { key: "Access-Control-Allow-Methods", value: "GET, POST, PUT, OPTIONS" },
          { key: "Access-Control-Allow-Headers", value: "Content-Type, Authorization" },
        ],
      },
    ];
  },
};

export default nextConfig;
