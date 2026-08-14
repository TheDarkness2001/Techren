import { useEffect, useMemo, useState } from 'react';

const DEFAULTS = {
  android: 'https://github.com/TheDarkness2001/Techren/releases/latest/download/techren-edu.apk',
  windows: 'https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-setup.exe',
  macos: 'https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-macos.zip',
  ios: 'https://github.com/TheDarkness2001/Techren/releases/latest',
};

function detectPlatform() {
  if (typeof navigator === 'undefined') return 'other';
  const ua = navigator.userAgent || '';
  if (/Android/i.test(ua)) return 'android';
  if (/iPhone|iPad|iPod/i.test(ua)) return 'ios';
  if (/Windows/i.test(ua)) return 'windows';
  if (/Mac OS X|Macintosh/i.test(ua) && !/iPhone|iPad|iPod/i.test(ua)) return 'macos';
  return 'other';
}

function platformLabel(platform) {
  switch (platform) {
    case 'android':
      return 'Android';
    case 'windows':
      return 'Windows';
    case 'macos':
      return 'Mac';
    case 'ios':
      return 'iPhone';
    default:
      return 'your device';
  }
}

/**
 * One Download button — picks Android / Windows / Mac installer from the visitor’s device.
 */
export default function DownloadAppButton({
  className = 'btn btn-primary magnetic',
  label = 'Download App',
  showPlatformHint = true,
}) {
  const [platform, setPlatform] = useState('other');
  const [urls, setUrls] = useState(DEFAULTS);
  const [version, setVersion] = useState('');

  useEffect(() => {
    setPlatform(detectPlatform());

    let cancelled = false;
    (async () => {
      try {
        const res = await fetch('/downloads/status.json', { cache: 'no-store' });
        if (!res.ok) return;
        const data = await res.json();
        if (cancelled) return;
        setUrls({
          android: data.androidUrl || DEFAULTS.android,
          windows: data.windowsUrl || DEFAULTS.windows,
          macos: data.macosUrl || DEFAULTS.macos,
          ios: data.iosUrl || DEFAULTS.ios,
        });
        if (data.version) setVersion(String(data.version));
      } catch {
        /* keep GitHub defaults */
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  const href = useMemo(() => {
    if (platform === 'android') return urls.android;
    if (platform === 'windows') return urls.windows;
    if (platform === 'macos') return urls.macos;
    if (platform === 'ios') return urls.ios;
    // Desktops / unknown: prefer Windows installer (most school PCs).
    return urls.windows;
  }, [platform, urls]);

  const hint = useMemo(() => {
    const device = platformLabel(platform);
    if (platform === 'ios') {
      return 'iPhone build is limited — opens the latest release page.';
    }
    if (platform === 'other') {
      return 'Windows installer · switch device for Android / Mac';
    }
    return version ? `${device} · v${version}` : `For ${device}`;
  }, [platform, version]);

  return (
    <span className="download-app">
      <a className={className} href={href} download={platform !== 'ios' ? true : undefined}>
        {label}
      </a>
      {showPlatformHint ? <span className="download-app-hint">{hint}</span> : null}
    </span>
  );
}
