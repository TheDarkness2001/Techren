import { CinematicLanding } from "@/components/cinematic/CinematicLanding";
import { SiteLoader } from "@/components/cinematic/SiteLoader";
import { SmoothScroll } from "@/components/cinematic/SmoothScroll";

export default function HomePage() {
  return (
    <SiteLoader>
      <SmoothScroll>
        <CinematicLanding />
      </SmoothScroll>
    </SiteLoader>
  );
}
