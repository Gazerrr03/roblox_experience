import type { Metadata } from "next";
import { JetBrains_Mono, Inter } from "next/font/google";
import { Noto_Sans_SC } from "next/font/google";
import "./globals.css";

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const notoSansSC = Noto_Sans_SC({
  variable: "--font-noto-sans-sc",
  subsets: ["latin"],
  weight: ["400", "500", "700"],
});

export const metadata: Metadata = {
  title: {
    default: "LIMINAL — Mission-driven horror expedition",
    template: "%s | LIMINAL",
  },
  description:
    "You are sent to recover pages from a lethal maze. You are fragile. If you want to come back alive, you must learn faster than the place kills you.",
  metadataBase: new URL("https://liminal-game.vercel.app"),
  openGraph: {
    title: "LIMINAL",
    description:
      "A mission-driven horror game where fragile players are forced into the Maze to complete assigned work. Only knowledge lets you survive.",
    type: "website",
    siteName: "LIMINAL",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "LIMINAL",
    description:
      "A mission-driven horror game. You are fragile. Learn or die.",
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: {
    languages: {
      en: "/en",
      zh: "/zh",
    },
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${jetbrainsMono.variable} ${inter.variable} ${notoSansSC.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
