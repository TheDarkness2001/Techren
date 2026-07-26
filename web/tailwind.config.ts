import type { Config } from "tailwindcss";

export default {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        void: "#050816",
        primary: "#6C63FF",
        secondary: "#00D4FF",
        accent: "#7C3AED",
        glass: "rgba(255,255,255,0.08)",
        line: "rgba(255,255,255,0.15)",
      },
      fontFamily: {
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        body: ["var(--font-body)", "system-ui", "sans-serif"],
      },
      maxWidth: {
        site: "80rem",
      },
      boxShadow: {
        glow: "0 0 40px rgba(108,99,255,0.45)",
        "glow-cyan": "0 0 40px rgba(0,212,255,0.35)",
      },
    },
  },
  plugins: [],
} satisfies Config;
