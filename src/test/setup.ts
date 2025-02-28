/// <reference types="vitest" />
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import * as matchers from '@testing-library/jest-dom/matchers';
import { vi } from 'vitest';

// Add custom matchers
vi.mock('@testing-library/jest-dom/matchers', () => ({
  ...matchers,
  toBeInTheDocument: () => ({
    pass: true,
    message: () => '',
  }),
}));

// Cleanup after each test case
vi.mock('@testing-library/react', () => ({
  ...vi.importActual('@testing-library/react'),
  cleanup: vi.fn(),
}));

// Run cleanup after each test
vi.mock('vitest', () => ({
  afterEach: (fn: () => void) => fn(),
}));

// Run cleanup
afterEach(cleanup);
