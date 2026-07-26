import { AboutSection } from "@/components/AboutSection";
import { CampusSection } from "@/components/CampusSection";
import { DownloadSection } from "@/components/DownloadSection";
import { Hero } from "@/components/Hero";
import { LearnSection } from "@/components/LearnSection";
import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <AboutSection />
        <LearnSection />
        <CampusSection />
        <DownloadSection />
      </main>
      <SiteFooter />
    </>
  );
}
