import { createRequire } from "module";
import type { NextConfig } from "next";
import createMDX from "@next/mdx";

const require = createRequire(import.meta.url);

const nextConfig: NextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
  serverExternalPackages: [],

  webpack: (config) => {
    config.resolve.alias["next-intl/config"] = require.resolve(
      "./src/i18n/request.ts"
    );
    return config;
  },
};

const withMDX = createMDX({});

export default withMDX(nextConfig);
