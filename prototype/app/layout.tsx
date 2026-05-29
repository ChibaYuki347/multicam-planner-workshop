import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Multi-Camera Capture Planner",
  description:
    "Spec-Driven Development Workshop プロトタイプ — マルチカメラ撮影プランナー",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
