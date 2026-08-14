import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { animateThemeTransition } from '../animations/pageAnimations';

const ThemeContext = createContext(null);

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(() => {
    if (typeof window === 'undefined') return 'dark';
    return localStorage.getItem('techren-theme') || 'dark';
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('techren-theme', theme);
    const color = theme === 'dark' ? '#050506' : '#f4f4f1';
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', color);
  }, [theme]);

  const toggleTheme = useCallback(
    (originEl) => {
      const next = theme === 'dark' ? 'light' : 'dark';
      animateThemeTransition(originEl, () => setTheme(next));
    },
    [theme]
  );

  return <ThemeContext.Provider value={{ theme, toggleTheme }}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
