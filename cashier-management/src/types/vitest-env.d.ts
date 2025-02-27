/// <reference types="vite/client" />

import type { TestingLibraryMatchers } from '@testing-library/jest-dom/matchers';

declare global {
  namespace Vi {
    interface JestAssertion<T = any>
      extends jest.Matchers<void, T>,
        TestingLibraryMatchers<T, void> {}
  }

  interface Window {
    matchMedia: (query: string) => MediaQueryList;
    IntersectionObserver: new () => IntersectionObserver;
    ResizeObserver: new () => ResizeObserver;
    MutationObserver: new () => MutationObserver;
  }
}

declare module 'vitest' {
  interface Assertion<T = any> extends TestingLibraryMatchers<T, void> {}
  interface AsymmetricMatchersContaining extends TestingLibraryMatchers<void, void> {}
}

interface CustomMatchers<R = unknown> {
  toBeWithinRange(floor: number, ceiling: number): R;
}

declare module 'vitest' {
  interface Assertion extends CustomMatchers {}
  interface AsymmetricMatchersContaining extends CustomMatchers {}
}

declare const expect: Vi.ExpectStatic;
declare const vi: typeof import('vitest').vi;
declare const beforeAll: typeof import('vitest').beforeAll;
declare const afterAll: typeof import('vitest').afterAll;
declare const beforeEach: typeof import('vitest').beforeEach;
declare const afterEach: typeof import('vitest').afterEach;
declare const describe: typeof import('vitest').describe;
declare const it: typeof import('vitest').it;
declare const test: typeof import('vitest').test;

export {};
