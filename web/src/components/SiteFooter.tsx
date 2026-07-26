export function SiteFooter() {
  return (
    <footer className="border-t border-line bg-white">
      <div className="mx-auto flex w-full max-w-site flex-col gap-6 px-5 py-12 sm:flex-row sm:items-end sm:justify-between sm:px-8">
        <div>
          <p className="font-display text-2xl font-bold tracking-tight text-ink">TechRen EDU</p>
          <p className="mt-2 text-sm text-ink-mute">Education center platform · All rights reserved.</p>
        </div>
        <nav className="flex flex-wrap gap-5 text-sm font-semibold text-ink" aria-label="Footer">
          <a href="#about" className="hover:text-brand">
            About
          </a>
          <a href="#learn" className="hover:text-brand">
            Learn
          </a>
          <a href="#campus" className="hover:text-brand">
            Campus
          </a>
          <a href="#download" className="hover:text-brand">
            Download
          </a>
        </nav>
      </div>
    </footer>
  );
}
