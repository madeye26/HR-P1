import React, { createContext, useContext, useEffect, useState } from 'react';
import { ThemeOptions } from '@mui/material/styles';

interface ThemeContextType {
  themeMode: 'light' | 'dark';
  primaryColor: string;
  secondaryColor: string;
  fontFamily: string;
  fontSize: 'small' | 'medium' | 'large';
  toggleTheme: () => void;
  updateThemeColors: (primary: string, secondary: string) => void;
  updateFontSettings: (family: string, size: 'small' | 'medium' | 'large') => void;
}

const defaultTheme = {
  themeMode: 'light',
  primaryColor: '#1976d2',
  secondaryColor: '#dc004e',
  fontFamily: 'Cairo, sans-serif',
  fontSize: 'medium',
} as const;

const ThemeContext = createContext<ThemeContextType>({
  ...defaultTheme,
  toggleTheme: () => {},
  updateThemeColors: () => {},
  updateFontSettings: () => {},
});

export const useTheme = () => useContext(ThemeContext);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [themeSettings, setThemeSettings] = useState(() => {
    const savedTheme = localStorage.getItem('appTheme');
    return savedTheme ? JSON.parse(savedTheme) : defaultTheme;
  });

  useEffect(() => {
    localStorage.setItem('appTheme', JSON.stringify(themeSettings));
  }, [themeSettings]);

  const toggleTheme = () => {
    setThemeSettings((prev: typeof defaultTheme) => ({
      ...prev,
      themeMode: prev.themeMode === 'light' ? 'dark' : 'light'
    }));
  };

  const updateThemeColors = (primary: string, secondary: string) => {
    setThemeSettings((prev: typeof defaultTheme) => ({
      ...prev,
      primaryColor: primary,
      secondaryColor: secondary
    }));
  };

  const updateFontSettings = (family: string, size: 'small' | 'medium' | 'large') => {
    setThemeSettings((prev: typeof defaultTheme) => ({
      ...prev,
      fontFamily: family,
      fontSize: size
    }));
  };

  const value = {
    ...themeSettings,
    toggleTheme,
    updateThemeColors,
    updateFontSettings,
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

export default ThemeProvider;
