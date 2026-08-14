import { useCallback, useEffect, useState } from 'react';
import { ThemeProvider } from './hooks/theme.jsx';
import Loader from './components/Loader';
import CustomCursor from './components/CustomCursor';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Founder from './components/Founder';
import Programming from './components/Programming';
import Projects from './components/Projects';
import English from './components/English';
import TechRenApp from './components/TechRenApp';
import ParentConnection from './components/ParentConnection';
import WhyTechRen from './components/WhyTechRen';
import CTA from './components/CTA';
import Footer from './components/Footer';
import { bindMagnetics } from './animations/hoverAnimations';

function Page() {
  const [ready, setReady] = useState(false);
  const onLoaded = useCallback(() => setReady(true), []);

  useEffect(() => {
    document.body.style.overflow = ready ? '' : 'hidden';
    return () => {
      document.body.style.overflow = '';
    };
  }, [ready]);

  useEffect(() => {
    if (!ready) return undefined;
    return bindMagnetics(document);
  }, [ready]);

  return (
    <>
      {!ready && <Loader onComplete={onLoaded} />}
      <CustomCursor />
      <Navbar />
      <main id="main">
        <Hero start={ready} />
        <Founder />
        <Programming />
        <Projects />
        <English />
        <TechRenApp />
        <ParentConnection />
        <WhyTechRen />
        <CTA />
      </main>
      <Footer />
    </>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <Page />
    </ThemeProvider>
  );
}
