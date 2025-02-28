import { ErrorInfo } from 'react';

interface ErrorReport {
  error: Error;
  errorInfo?: {
    componentStack: string | null;
  };
  timestamp: number;
  userAgent: string;
  url: string;
  context?: Record<string, unknown>;
}

// Error severity levels
export enum ErrorSeverity {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

// Configuration for error reporting
const ERROR_CONFIG = {
  MAX_ERRORS_PER_MINUTE: 10,
  ERROR_WINDOW_MS: 60000, // 1 minute
  DEBOUNCE_TIME_MS: 1000, // 1 second
};

class ErrorTracker {
  private static instance: ErrorTracker;
  private errorCount: number = 0;
  private lastResetTime: number = Date.now();
  private lastErrorTime: number = 0;

  private constructor() {
    // Reset error count every minute
    setInterval(() => {
      this.errorCount = 0;
      this.lastResetTime = Date.now();
    }, ERROR_CONFIG.ERROR_WINDOW_MS);
  }

  public static getInstance(): ErrorTracker {
    if (!ErrorTracker.instance) {
      ErrorTracker.instance = new ErrorTracker();
    }
    return ErrorTracker.instance;
  }

  public canReportError(): boolean {
    const now = Date.now();
    
    // Check if we're within the debounce period
    if (now - this.lastErrorTime < ERROR_CONFIG.DEBOUNCE_TIME_MS) {
      return false;
    }

    // Reset count if we're in a new window
    if (now - this.lastResetTime >= ERROR_CONFIG.ERROR_WINDOW_MS) {
      this.errorCount = 0;
      this.lastResetTime = now;
    }

    // Check if we've exceeded the rate limit
    if (this.errorCount >= ERROR_CONFIG.MAX_ERRORS_PER_MINUTE) {
      console.warn('Error reporting rate limit exceeded');
      return false;
    }

    this.lastErrorTime = now;
    this.errorCount++;
    return true;
  }
}

export const getSeverity = (error: Error): ErrorSeverity => {
  if (error.name === 'TypeError' || error.name === 'ReferenceError') {
    return ErrorSeverity.HIGH;
  }
  if (error.name === 'SyntaxError') {
    return ErrorSeverity.CRITICAL;
  }
  if (error.message.toLowerCase().includes('network') || 
      error.message.toLowerCase().includes('fetch')) {
    return ErrorSeverity.MEDIUM;
  }
  return ErrorSeverity.LOW;
};

export const reportError = async (
  error: Error, 
  errorInfo?: ErrorInfo,
  context?: Record<string, unknown>
): Promise<void> => {
  const errorTracker = ErrorTracker.getInstance();
  
  if (!errorTracker.canReportError()) {
    return;
  }

  const errorReport: ErrorReport = {
    error,
    errorInfo: errorInfo ? {
      componentStack: errorInfo.componentStack || null
    } : undefined,
    timestamp: Date.now(),
    userAgent: navigator.userAgent,
    url: window.location.href,
    context,
  };

  const severity = getSeverity(error);
  const formattedError = {
    name: error.name,
    message: error.message,
    stack: error.stack,
    componentStack: errorInfo?.componentStack || null,
    severity,
    timestamp: new Date(errorReport.timestamp).toISOString(),
    userAgent: errorReport.userAgent,
    url: errorReport.url,
    context: errorReport.context,
  };

  // Log to console in development
  if (process.env.NODE_ENV === 'development') {
    console.error('Error Report:', formattedError);
  }

  // In production, we would send to an error tracking service
  if (process.env.NODE_ENV === 'production') {
    try {
      // Example of sending to a hypothetical error tracking endpoint
      // await fetch('/api/error-tracking', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(formattedError)
      // });

      // For now, just log to console in a structured way
      console.error('Production Error:', formattedError);
    } catch (sendError) {
      // Fallback to console if sending fails
      console.error('Failed to send error report:', sendError);
      console.error('Original error:', formattedError);
    }
  }
};

export const logWarning = (
  message: string,
  context?: Record<string, unknown>
): void => {
  const warning = {
    message,
    context,
    timestamp: new Date().toISOString(),
    url: window.location.href,
  };

  console.warn('Warning:', warning);
};

export const logInfo = (
  message: string,
  context?: Record<string, unknown>
): void => {
  const info = {
    message,
    context,
    timestamp: new Date().toISOString(),
    url: window.location.href,
  };

  console.info('Info:', info);
};
