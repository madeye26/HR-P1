import React, { useMemo } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { ThemeProvider as MuiThemeProvider, CssBaseline, createTheme } from '@mui/material';
import { prefixer } from 'stylis';
import rtlPlugin from 'stylis-plugin-rtl';
import { CacheProvider } from '@emotion/react';
import createCache from '@emotion/cache';
import MainApp from './components/MainApp';
import ErrorBoundary from './components/ErrorBoundary';
import ThemeProvider, { useTheme } from './context/ThemeContext';

// Create RTL cache
const cacheRtl = createCache({
  key: 'muirtl',
  stylisPlugins: [prefixer, rtlPlugin],
});

// Add Cairo font
const linkElement = document.createElement('link');
linkElement.rel = 'stylesheet';
linkElement.href = 'https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700&display=swap';
document.head.appendChild(linkElement);

const ThemedApp: React.FC = () => {
  const { themeMode, primaryColor, secondaryColor, fontFamily, fontSize } = useTheme();

  const theme = useMemo(() => createTheme({
    direction: 'rtl',
    palette: {
      mode: themeMode,
      primary: {
        main: primaryColor,
      },
      secondary: {
        main: secondaryColor,
      },
    },
    typography: {
      fontFamily,
      fontSize: fontSize === 'small' ? 14 : fontSize === 'large' ? 16 : 15,
    },
  }), [themeMode, primaryColor, secondaryColor, fontFamily, fontSize]);

  return (
    <MuiThemeProvider theme={theme}>
      <CssBaseline />
      <ErrorBoundary>
        <BrowserRouter>
          <MainApp />
        </BrowserRouter>
      </ErrorBoundary>
    </MuiThemeProvider>
  );
};

const App: React.FC = () => {
  return (
    <CacheProvider value={cacheRtl}>
      <ThemeProvider>
        <ThemedApp />
      </ThemeProvider>
    </CacheProvider>
  );
};

export default App;
