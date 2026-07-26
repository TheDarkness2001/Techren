import type { Metadata } from "next";
import { Outfit, Syne } from "next/font/google";
import "./globals.css";

const display = Syne({
  subsets: ["latin"],
  variable: "--font-display",
  weight: ["600", "700", "800"],
});

const body = Outfit({
  subsets: ["latin"],
  variable: "--font-body",
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "TechRen EDU — Education center",
  description:
    "TechRen EDU — native learning app for our education center. Words, sentences, listening, attendance, and progress.",
  icons: { icon: "/favicon.png" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${display.variable} ${body.variable} bg-paper text-ink antialiased`}>
        <div className="grain" aria-hidden />
        {children}
      </body>
    </html>
  );
}
