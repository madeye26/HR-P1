import * as yup from 'yup';
import { formatPhoneNumber, formatNationalId } from './formatters';

// Common validation messages
const messages = {
  required: 'هذا الحقل مطلوب',
  email: 'البريد الإلكتروني غير صالح',
  phone: 'رقم الهاتف غير صالح',
  nationalId: 'الرقم القومي غير صالح',
  minLength: (min: number) => `يجب أن يكون الطول على الأقل ${min} حروف`,
  maxLength: (max: number) => `يجب أن لا يتجاوز الطول ${max} حروف`,
  min: (min: number) => `يجب أن تكون القيمة أكبر من أو تساوي ${min}`,
  max: (max: number) => `يجب أن تكون القيمة أقل من أو تساوي ${max}`,
  positiveNumber: 'يجب أن تكون القيمة رقماً موجباً',
  integer: 'يجب أن تكون القيمة عدداً صحيحاً',
  date: 'التاريخ غير صالح',
  futureDate: 'يجب أن يكون التاريخ في المستقبل',
  pastDate: 'يجب أن يكون التاريخ في الماضي',
};

// Regular expressions
const patterns = {
  egyptianPhone: /^01[0125][0-9]{8}$/,
  egyptianNationalId: /^[2-3][0-9]{13}$/,
  password: /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/,
  name: /^[\u0600-\u06FF\s]{2,}$/,  // Arabic characters and spaces
  bankAccount: /^\d{10,16}$/,
};

// Employee Schema
export const employeeSchema = yup.object().shape({
  name: yup
    .string()
    .required(messages.required)
    .matches(patterns.name, 'يجب أن يحتوي الاسم على حروف عربية فقط')
    .min(2, messages.minLength(2))
    .max(50, messages.maxLength(50)),
  
  position: yup
    .string()
    .required(messages.required)
    .min(2, messages.minLength(2))
    .max(50, messages.maxLength(50)),
  
  department: yup
    .string()
    .required(messages.required),
  
  basicSalary: yup
    .number()
    .required(messages.required)
    .positive(messages.positiveNumber)
    .min(1000, messages.min(1000))
    .max(100000, messages.max(100000)),
  
  monthlyIncentives: yup
    .number()
    .min(0, messages.min(0))
    .max(50000, messages.max(50000))
    .default(0),
  
  joinDate: yup
    .date()
    .required(messages.required)
    .max(new Date(), messages.pastDate),
  
  nationalId: yup
    .string()
    .required(messages.required)
    .matches(patterns.egyptianNationalId, messages.nationalId)
    .transform(formatNationalId),
  
  phoneNumber: yup
    .string()
    .required(messages.required)
    .matches(patterns.egyptianPhone, messages.phone)
    .transform(formatPhoneNumber),
  
  email: yup
    .string()
    .email(messages.email)
    .required(messages.required),
  
  address: yup
    .string()
    .required(messages.required)
    .min(5, messages.minLength(5))
    .max(200, messages.maxLength(200)),
  
  bankAccount: yup
    .string()
    .matches(patterns.bankAccount, 'رقم الحساب البنكي غير صالح')
    .nullable(),
  
  bankName: yup
    .string()
    .test('bank-name-required', 'اسم البنك مطلوب عند إدخال رقم الحساب', function(value) {
      return !this.parent.bankAccount || (this.parent.bankAccount && value);
    }),
  
  insuranceNumber: yup
    .string()
    .nullable(),
  
  emergencyContact: yup.object().shape({
    name: yup
      .string()
      .required(messages.required)
      .matches(patterns.name, 'يجب أن يحتوي الاسم على حروف عربية فقط'),
    
    relation: yup
      .string()
      .required(messages.required),
    
    phone: yup
      .string()
      .required(messages.required)
      .matches(patterns.egyptianPhone, messages.phone)
      .transform(formatPhoneNumber),
  }),
});

// Leave Request Schema
export const leaveRequestSchema = yup.object().shape({
  employeeId: yup
    .string()
    .required(messages.required),
  
  type: yup
    .string()
    .oneOf(['annual', 'sick', 'casual', 'unpaid', 'emergency'], 'نوع الإجازة غير صالح')
    .required(messages.required),
  
  startDate: yup
    .date()
    .required(messages.required)
    .min(new Date(), messages.futureDate),
  
  endDate: yup
    .date()
    .required(messages.required)
    .min(yup.ref('startDate'), 'يجب أن يكون تاريخ النهاية بعد تاريخ البداية'),
  
  reason: yup
    .string()
    .required(messages.required)
    .min(10, messages.minLength(10))
    .max(500, messages.maxLength(500)),
  
  attachments: yup
    .array()
    .of(yup.mixed())
    .nullable(),
});

// Attendance Record Schema
export const attendanceRecordSchema = yup.object().shape({
  employeeId: yup
    .string()
    .required(messages.required),
  
  date: yup
    .date()
    .required(messages.required)
    .max(new Date(), messages.pastDate),
  
  checkIn: yup
    .string()
    .required(messages.required)
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, 'وقت غير صالح'),
  
  checkOut: yup
    .string()
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, 'وقت غير صالح')
    .nullable(),
  
  status: yup
    .string()
    .oneOf(['present', 'absent', 'late', 'early_leave', 'on_leave'], 'حالة غير صالحة')
    .required(messages.required),
  
  notes: yup
    .string()
    .max(200, messages.maxLength(200))
    .nullable(),
});

// Department Schema
export const departmentSchema = yup.object().shape({
  name: yup
    .string()
    .required(messages.required)
    .min(2, messages.minLength(2))
    .max(50, messages.maxLength(50)),
  
  code: yup
    .string()
    .required(messages.required)
    .matches(/^[A-Z0-9]{2,10}$/, 'الكود يجب أن يحتوي على حروف إنجليزية كبيرة وأرقام فقط'),
  
  managerId: yup
    .string()
    .nullable(),
  
  budget: yup
    .number()
    .positive(messages.positiveNumber)
    .required(messages.required),
  
  description: yup
    .string()
    .max(500, messages.maxLength(500))
    .nullable(),
});

// Backup Settings Schema
export const backupSettingsSchema = yup.object().shape({
  autoBackup: yup
    .boolean()
    .required(messages.required),
  
  frequency: yup
    .string()
    .oneOf(['daily', 'weekly', 'monthly'], 'تكرار غير صالح')
    .test('frequency-required', 'التكرار مطلوب عند تفعيل النسخ الاحتياطي التلقائي', function(value) {
      return !this.parent.autoBackup || (this.parent.autoBackup && value);
    }),
  
  time: yup
    .string()
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, 'وقت غير صالح')
    .test('time-required', 'الوقت مطلوب عند تفعيل النسخ الاحتياطي التلقائي', function(value) {
      return !this.parent.autoBackup || (this.parent.autoBackup && value);
    }),
  
  retentionDays: yup
    .number()
    .integer(messages.integer)
    .min(1, messages.min(1))
    .max(365, messages.max(365))
    .required(messages.required),
  
  compressionLevel: yup
    .string()
    .oneOf(['low', 'medium', 'high'], 'مستوى ضغط غير صالح')
    .required(messages.required),
  
  includeAttachments: yup
    .boolean()
    .required(messages.required),
  
  encryptBackups: yup
    .boolean()
    .required(messages.required),
});

// User Settings Schema
export const userSettingsSchema = yup.object().shape({
  language: yup
    .string()
    .oneOf(['ar', 'en'], 'لغة غير صالحة')
    .required(messages.required),
  
  theme: yup
    .string()
    .oneOf(['light', 'dark'], 'سمة غير صالحة')
    .required(messages.required),
  
  notifications: yup.object().shape({
    email: yup.boolean().required(messages.required),
    push: yup.boolean().required(messages.required),
    sms: yup.boolean().required(messages.required),
  }),
  
  defaultView: yup
    .string()
    .required(messages.required),
  
  pageSize: yup
    .number()
    .integer(messages.integer)
    .min(10, messages.min(10))
    .max(100, messages.max(100))
    .required(messages.required),
});
