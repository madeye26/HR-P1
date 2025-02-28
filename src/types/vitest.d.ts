/// <reference types="vite/client" />

declare module 'vitest' {
  interface Suite {
    name: string;
    mode: 'run' | 'skip' | 'only' | 'todo';
    test(name: string, fn?: Function): void;
    it(name: string, fn?: Function): void;
    describe(name: string, fn: Function): void;
    beforeAll(fn: Function): void;
    afterAll(fn: Function): void;
    beforeEach(fn: Function): void;
    afterEach(fn: Function): void;
  }

  interface TestContext {
    skip(): void;
    only(): void;
    todo(): void;
    fails(): void;
    timeout(ms: number): void;
    retry(times: number): void;
  }

  interface ExpectStatic {
    extend(matchers: Record<string, Function>): void;
  }

  interface TestAPI {
    test: Suite['test'] & TestContext;
    it: Suite['it'] & TestContext;
    describe: Suite['describe'] & TestContext;
    beforeAll: Suite['beforeAll'];
    afterAll: Suite['afterAll'];
    beforeEach: Suite['beforeEach'];
    afterEach: Suite['afterEach'];
    expect: ExpectStatic;
    vi: {
      fn(): Function;
      spyOn(obj: object, method: string): object;
      mock(path: string): object;
      unmock(path: string): void;
      clearAllMocks(): void;
      resetAllMocks(): void;
      restoreAllMocks(): void;
      useFakeTimers(): void;
      useRealTimers(): void;
      runAllTimers(): void;
      runOnlyPendingTimers(): void;
      advanceTimersByTime(ms: number): void;
      setSystemTime(time: number | Date): void;
      getMockFunction(): Function;
      importActual(path: string): Promise<any>;
      importMock(path: string): Promise<any>;
    };
  }

  interface VitestConfig {
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
      alias?: Record<string, string>;
      reporters?: string[];
      watch?: boolean;
      maxConcurrency?: number;
      maxWorkers?: number;
      minWorkers?: number;
      isolate?: boolean;
      bail?: number;
      sequence?: {
        shuffle?: boolean;
        concurrent?: boolean;
      };
      typecheck?: {
        enabled?: boolean;
        tsconfig?: string;
        include?: string[];
        exclude?: string[];
      };
      mockReset?: boolean;
      restoreMocks?: boolean;
      clearMocks?: boolean;
    };
  }

  export function defineConfig(config: VitestConfig): VitestConfig;
}

declare module 'vite' {
  interface UserConfig {
    test?: import('vitest').VitestConfig['test'];
  }
}
