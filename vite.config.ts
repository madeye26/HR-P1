/// <reference types="vite/client" />

import { defineConfig, UserConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

interface VitestUserConfig extends UserConfig {
  test?: {
    globals?: boolean;
    environment?: string;
    setupFiles?: string[];
    include?: string[];
    exclude?: string[];
    coverage?: {
      provider?: string;
      reporter?: string[];
      exclude?: string[];
      branches?: number;
      functions?: number;
      lines?: number;
      statements?: number;
    };
    reporters?: string[];
    watch?: boolean;
  };
}

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@components': resolve(__dirname, './src/components'),
      '@utils': resolve(__dirname, './src/utils'),
      '@styles': resolve(__dirname, './src/styles'),
      '@types': resolve(__dirname, './src/types'),
      '@config': resolve(__dirname, './src/config'),
      '@context': resolve(__dirname, './src/context'),
      '@hooks': resolve(__dirname, './src/hooks'),
      '@assets': resolve(__dirname, './src/assets'),
    },
  },
  build: {
    target: 'esnext',
    sourcemap: true,
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: [
            'react',
            'react-dom',
            'react-router-dom',
            '@mui/material',
            '@mui/icons-material',
            '@emotion/react',
            '@emotion/styled',
            'date-fns',
          ],
        },
      },
    },
  },
  server: {
    port: 3000,
    host: true,
    strictPort: true,
    watch: {
      ignored: ['**/coverage/**'],
    },
  },
  preview: {
    port: 3000,
    strictPort: true,
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['./src/**/*.{test,spec}.{ts,tsx}'],
    exclude: [
      '**/node_modules/**',
      '**/dist/**',
      '**/cypress/**',
      '**/.{idea,git,cache,output,temp}/**',
      './src/test/e2e/**',
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.test.{ts,tsx}',
        '**/*.spec.{ts,tsx}',
      ],
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    reporters: ['default'],
    watch: false,
  },
} as VitestUserConfig);
