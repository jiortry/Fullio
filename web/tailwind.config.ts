import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        fullio: {
          dark: "#0F3D2E",
          green: "#5FAF8F",
          beige: "#F5F1E8",
          black: "#1C1C1C",
          warning: "#E57373",
          neutral: "#B8B0A2",
          "light-green": "#E8F5EE",
          "light-warning": "#FFF0F0",
          "light-beige": "#FAF8F4",
          "secondary-text": "#8A8278",
        },
      },
    },
  },
  plugins: [],
};

export default config;
