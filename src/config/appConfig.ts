import { SystemConfig } from '../types';

// Application version
export const APP_VERSION = '1.0.0';

// Default system configuration
export const DEFAULT_SYSTEM_CONFIG: SystemConfig = {
  companyName: 'نظام إدارة الكاشير',
  companyLogo: undefined,
  currency: 'EGP',
  timezone: 'Africa/Cairo',
  dateFormat: 'dd/MM/yyyy',
  timeFormat: 'HH:mm',
  language: 'ar',
  theme: 'light',
};

// API Configuration
export const API_CONFIG = {
  baseUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000/api',
  timeout: 30000, // 30 seconds
  retryAttempts: 3,
  retryDelay: 1000, // 1 second
};

// Authentication Configuration
export const AUTH_CONFIG = {
  tokenKey: 'cashier_auth_token',
  refreshTokenKey: 'cashier_refresh_token',
  tokenExpiry: 8 * 60 * 60, // 8 hours
  refreshTokenExpiry: 7 * 24 * 60 * 60, // 7 days
  loginPath: '/auth/login',
  logoutPath: '/auth/logout',
  refreshPath: '/auth/refresh',
};

// Working Hours Configuration
export const WORKING_HOURS = {
  start: '09:00',
  end: '17:00',
  graceMinutes: 15,
  minHours: 8,
  maxOvertime: 4,
  workingDaysPerMonth: 22,
};

// Payroll Configuration
export const PAYROLL_CONFIG = {
  salaryDay: 25, // Day of month for salary payment
  overtimeRate: 1.5,
  transportationAllowance: 300,
  mealAllowance: 200,
  socialInsuranceRate: 0.11, // 11%
  healthInsuranceRate: 0.03, // 3%
  taxBrackets: [
    { min: 0, max: 15000, rate: 0 }, // 0%
    { min: 15000, max: 30000, rate: 0.025 }, // 2.5%
    { min: 30000, max: 45000, rate: 0.10 }, // 10%
    { min: 45000, max: 60000, rate: 0.15 }, // 15%
    { min: 60000, max: 200000, rate: 0.20 }, // 20%
    { min: 200000, max: 400000, rate: 0.225 }, // 22.5%
    { min: 400000, max: Infinity, rate: 0.25 }, // 25%
  ],
};

// Leave Configuration
export const LEAVE_CONFIG = {
  annualLeaveEntitlement: 21, // days per year
  sickLeaveEntitlement: 14, // days per year
  casualLeaveEntitlement: 7, // days per year
  maxConsecutiveLeave: 14,
  minServiceForLeave: 3, // months
  carryOverLimit: 5, // days
  carryOverValidity: 3, // months
};

// Backup Configuration
export const BACKUP_CONFIG = {
  autoBackup: true,
  frequency: 'daily' as const,
  time: '00:00',
  retentionDays: 30,
  compressionLevel: 'medium' as const,
  includeAttachments: true,
  encryptBackups: true,
  backupPath: './backups',
};

// Notification Configuration
export const NOTIFICATION_CONFIG = {
  defaultDuration: 5000,
  position: 'top-right' as const,
  maxNotifications: 5,
  soundEnabled: true,
  emailEnabled: true,
  pushEnabled: true,
  categories: {
    attendance: true,
    payroll: true,
    leave: true,
    system: true,
  },
};

// Validation Rules
export const VALIDATION_RULES = {
  password: {
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
  },
  phone: {
    pattern: /^01[0125][0-9]{8}$/,
    length: 11,
  },
  nationalId: {
    pattern: /^[2-3][0-9]{13}$/,
    length: 14,
  },
  email: {
    pattern: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
  },
  bankAccount: {
    minLength: 10,
    maxLength: 16,
  },
};

// File Upload Configuration
export const UPLOAD_CONFIG = {
  maxFileSize: 5 * 1024 * 1024, // 5MB
  allowedImageTypes: ['image/jpeg', 'image/png', 'image/gif'],
  allowedDocumentTypes: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  maxFiles: 5,
  imageDimensions: {
    maxWidth: 2000,
    maxHeight: 2000,
    minWidth: 100,
    minHeight: 100,
  },
};

// Report Configuration
export const REPORT_CONFIG = {
  defaultFormat: 'pdf' as const,
  pageSize: 'A4' as const,
  defaultOrientation: 'portrait' as const,
  headerHeight: 50,
  footerHeight: 30,
  margin: {
    top: 40,
    right: 30,
    bottom: 40,
    left: 30,
  },
  fontSize: {
    title: 18,
    subtitle: 14,
    heading: 12,
    body: 10,
    footer: 8,
  },
};

// Cache Configuration
export const CACHE_CONFIG = {
  ttl: 60 * 60 * 1000, // 1 hour
  maxItems: 100,
  prefix: 'cashier_',
  version: '1',
};

// Pagination Configuration
export const PAGINATION_CONFIG = {
  defaultPageSize: 10,
  pageSizeOptions: [10, 20, 50, 100],
  maxPageSize: 100,
};

// Date Formats
export const DATE_FORMATS = {
  display: {
    full: 'EEEE، d MMMM yyyy',
    short: 'd/M/yyyy',
    month: 'MMMM yyyy',
    time: 'h:mm a',
    datetime: 'EEEE، d MMMM yyyy h:mm a',
  },
  parse: {
    date: 'yyyy-MM-dd',
    time: 'HH:mm',
    datetime: 'yyyy-MM-dd HH:mm:ss',
  },
};

// Error Messages
export const ERROR_MESSAGES = {
  network: 'حدث خطأ في الاتصال بالخادم',
  auth: {
    invalidCredentials: 'اسم المستخدم أو كلمة المرور غير صحيحة',
    sessionExpired: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
    unauthorized: 'غير مصرح لك بالوصول إلى هذه الصفحة',
  },
  validation: {
    required: 'هذا الحقل مطلوب',
    email: 'البريد الإلكتروني غير صالح',
    phone: 'رقم الهاتف غير صالح',
    nationalId: 'الرقم القومي غير صالح',
    password: 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل',
  },
  upload: {
    size: 'حجم الملف يتجاوز الحد المسموح به',
    type: 'نوع الملف غير مدعوم',
    dimensions: 'أبعاد الصورة غير مناسبة',
  },
};

// Success Messages
export const SUCCESS_MESSAGES = {
  save: 'تم الحفظ بنجاح',
  update: 'تم التحديث بنجاح',
  delete: 'تم الحذف بنجاح',
  upload: 'تم رفع الملف بنجاح',
  backup: 'تم إنشاء نسخة احتياطية بنجاح',
  restore: 'تم استعادة النسخة الاحتياطية بنجاح',
};

// Export all configurations
export const appConfig = {
  APP_VERSION,
  DEFAULT_SYSTEM_CONFIG,
  API_CONFIG,
  AUTH_CONFIG,
  WORKING_HOURS,
  PAYROLL_CONFIG,
  LEAVE_CONFIG,
  BACKUP_CONFIG,
  NOTIFICATION_CONFIG,
  VALIDATION_RULES,
  UPLOAD_CONFIG,
  REPORT_CONFIG,
  CACHE_CONFIG,
  PAGINATION_CONFIG,
  DATE_FORMATS,
  ERROR_MESSAGES,
  SUCCESS_MESSAGES,
};

export default appConfig;
