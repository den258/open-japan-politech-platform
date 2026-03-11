import { ScrollReveal, SmoothScrollProvider } from "@ojpp/ui";
import type { Metadata } from "next";
import { Inter, Noto_Sans_JP } from "next/font/google";
import "./globals.css";
import { DarkNavigationBar } from "@/components/dark-navigation-bar";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const notoSansJP = Noto_Sans_JP({ subsets: ["latin"], variable: "--font-noto-sans-jp" });

export const metadata: Metadata = {
  title: "ParliScope - 議会を、すべての人とエージェントに開く",
  description:
    "国会・地方議会の全データをAPI化。AIエージェントが法案を要約・分析し、誰もが議会の動きをリアルタイムに把握できる。",
  openGraph: {
    title: "ParliScope - 議会を、すべての人とエージェントに開く",
    description:
      "国会・地方議会の全データをAPI化。AIエージェントが法案を要約・分析し、誰もが議会の動きをリアルタイムに把握できる。",
    siteName: "Open Japan PoliTech Platform",
    locale: "ja_JP",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "ParliScope - 議会を、すべての人とエージェントに開く",
    description:
      "国会・地方議会の全データをAPI化。AIエージェントが法案を要約・分析し、誰もが議会の動きをリアルタイムに把握できる。",
  },
};

const NAV_ITEMS = [
  { href: "/", label: "ダッシュボード" },
  { href: "/agenda", label: "現在の議題" },
  { href: "/bills", label: "法案" },
  { href: "/sessions", label: "会期" },
  { href: "/politicians", label: "議員" },
  { href: "/api-docs", label: "API" },
  { href: "/about", label: "About" },
];

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja" className={`${inter.variable} ${notoSansJP.variable}`}>
      <body className="min-h-screen bg-[#0f0f23] font-sans text-white antialiased">
        <DarkNavigationBar items={NAV_ITEMS} />
        <div className="border-b border-amber-500/20 bg-amber-500/5 px-6 py-2 text-center text-xs text-amber-400/90">
          v0.1 デモ版 —
          議員名は実在しますが、法案データには実在・架空が混在しています。投票記録はサンプルデータです。
        </div>
        <SmoothScrollProvider>
          <main>{children}</main>
        </SmoothScrollProvider>
        <ScrollReveal>
          <footer className="border-t border-white/5 bg-[#0a0a1a] px-6 py-12 text-center text-sm text-[#8b949e]">
            <div className="mx-auto max-w-7xl">
              <p>AIエージェント時代の議会監視 — エージェントが全法案を読み、あなたに届ける</p>
              <p className="mt-2 text-[#6b7280]">
                政党にも企業にもよらない、完全オープンな政治テクノロジー基盤
              </p>
              <p className="mt-1 text-[#6b7280]">Open Japan PoliTech Platform v0.1 | AGPL-3.0</p>
            </div>
          </footer>
        </ScrollReveal>
      </body>
    </html>
  );
}
