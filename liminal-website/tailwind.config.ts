import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        background: "var(--bg-primary)",
        foreground: "var(--text-primary)",
        amber: {
          DEFAULT: "var(--text-amber)",
          dim: "var(--text-amber-dim)",
        },
        stone: {
          card: "var(--bg-card)",
          accent: "var(--accent-stone)",
        },
        danger: {
          DEFAULT: "var(--accent-red)",
          bright: "var(--accent-red-bright)",
        },
        muted: "var(--text-muted)",
        secondary: "var(--text-secondary)",
      },
      fontFamily: {
        mono: ["var(--font-jetbrains-mono)", "Courier New", "monospace"],
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
        "noto-sc": ["var(--font-noto-sans-sc)", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
