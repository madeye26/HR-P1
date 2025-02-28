/// <reference types="vitest/globals" />
/// <reference types="@testing-library/jest-dom" />

import type { SpyInstance } from 'vitest';

declare global {
  interface Window {
    vi: typeof import('vitest').vi;
  }
}

const { vi } = window;

// Mock window.matchMedia
const mockMatchMedia = vi.fn().mockImplementation((query: string) => ({
  matches: false,
  media: query,
  onchange: null,
  addListener: vi.fn(),
  removeListener: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
  dispatchEvent: vi.fn(),
}));

Object.defineProperty(window, 'matchMedia', { value: mockMatchMedia });

// Mock IntersectionObserver
const mockIntersectionObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
  takeRecords: vi.fn().mockReturnValue([]),
}));

Object.defineProperty(window, 'IntersectionObserver', { value: mockIntersectionObserver });

// Mock ResizeObserver
const mockResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

Object.defineProperty(window, 'ResizeObserver', { value: mockResizeObserver });

// Mock MutationObserver
const mockMutationObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  disconnect: vi.fn(),
  takeRecords: vi.fn().mockReturnValue([]),
}));

Object.defineProperty(window, 'MutationObserver', { value: mockMutationObserver });

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  key: vi.fn(),
  length: 0,
};

Object.defineProperty(window, 'localStorage', { value: localStorageMock });

// Mock sessionStorage
const sessionStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  key: vi.fn(),
  length: 0,
};

Object.defineProperty(window, 'sessionStorage', { value: sessionStorageMock });

// Mock fetch
global.fetch = vi.fn();

// Mock date
vi.setSystemTime(new Date('2023-01-01T00:00:00.000Z'));

// Mock random
Math.random = vi.fn(() => 0.5);

// Mock console methods
console.error = vi.fn();
console.warn = vi.fn();
console.log = vi.fn();

// Mock window.URL
window.URL.createObjectURL = vi.fn();
window.URL.revokeObjectURL = vi.fn();

// Mock window.crypto
const mockCrypto = {
  getRandomValues: (arr: Uint8Array) => arr,
  subtle: {
    digest: vi.fn(),
    encrypt: vi.fn(),
    decrypt: vi.fn(),
    sign: vi.fn(),
    verify: vi.fn(),
  },
};

Object.defineProperty(window, 'crypto', { value: mockCrypto });

// Mock window.performance
const mockPerformance = {
  now: vi.fn(() => 0),
  mark: vi.fn(),
  measure: vi.fn(),
  getEntriesByName: vi.fn(),
  getEntriesByType: vi.fn(),
  clearMarks: vi.fn(),
  clearMeasures: vi.fn(),
};

Object.defineProperty(window, 'performance', { value: mockPerformance });

// Mock requestAnimationFrame
window.requestAnimationFrame = vi.fn((cb: FrameRequestCallback) => setTimeout(cb, 0));
window.cancelAnimationFrame = vi.fn();

// Mock getComputedStyle
window.getComputedStyle = vi.fn(() => ({
  getPropertyValue: vi.fn(),
}));

// Mock Intl
const mockIntl = {
  ...global.Intl,
  NumberFormat: vi.fn().mockImplementation(() => ({
    format: (num: number) => num.toString(),
  })),
  DateTimeFormat: vi.fn().mockImplementation(() => ({
    format: (date: Date) => date.toISOString(),
  })),
};

Object.defineProperty(global, 'Intl', { value: mockIntl });

// Set environment variables
process.env.VITE_API_URL = 'http://localhost:3000';
process.env.VITE_ENV = 'test';

// Add custom matchers
expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () => 
        pass
          ? `expected ${received} not to be within range ${floor} - ${ceiling}`
          : `expected ${received} to be within range ${floor} - ${ceiling}`,
    };
  },
});
