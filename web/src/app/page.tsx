import { CinematicLanding } from "@/components/cinematic/CinematicLanding";
import { CustomCursor } from "@/components/cinematic/CustomCursor";
import { SmoothScroll } from "@/components/cinematic/SmoothScroll";

export default function HomePage() {
  return (
    <SmoothScroll>
      <CustomCursor />
      <CinematicLanding />
    </SmoothScroll>
  );
}
