import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Include la copia .native nel bundle serverless (Vercel) per fs.readFile sulle API
    outputFileTracingIncludes: {
      "/api/files": [path.join(__dirname, ".native", "fullio", "**", "*")],
      "/api/files/[...path]": [path.join(__dirname, ".native", "fullio", "**", "*")],
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
