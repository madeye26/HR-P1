import { format as formatDate, formatDistance, formatRelative } from 'date-fns';
import { ar } from 'date-fns/locale';

// Currency formatter
export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

// Number formatter
export const formatNumber = (num: number): string => {
  return new Intl.NumberFormat('ar-EG').format(num);
};

// Percentage formatter
export const formatPercentage = (value: number): string => {
  return new Intl.NumberFormat('ar-EG', {
    style: 'percent',
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(value / 100);
};

// Date formatters
export const formatFullDate = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDate(dateObj, 'dd MMMM yyyy', { locale: ar });
};

export const formatShortDate = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDate(dateObj, 'dd/MM/yyyy', { locale: ar });
};

export const formatTime = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDate(dateObj, 'HH:mm', { locale: ar });
};

export const formatDateTime = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDate(dateObj, 'dd MMMM yyyy HH:mm', { locale: ar });
};

export const formatRelativeTime = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDistance(dateObj, new Date(), {
    addSuffix: true,
    locale: ar,
  });
};

export const formatRelativeDate = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatRelative(dateObj, new Date(), { locale: ar });
};

// Phone number formatter
export const formatPhoneNumber = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 11) { // Egyptian mobile number format
    return `${cleaned.slice(0, 3)} ${cleaned.slice(3, 7)} ${cleaned.slice(7)}`;
  }
  return phone;
};

// National ID formatter
export const formatNationalId = (id: string): string => {
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length === 14) { // Egyptian National ID format
    return `${cleaned.slice(0, 1)} ${cleaned.slice(1, 7)} ${cleaned.slice(7, 9)} ${cleaned.slice(9)}`;
  }
  return id;
};

// File size formatter
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 بايت';
  const k = 1024;
  const sizes = ['بايت', 'كيلوبايت', 'ميجابايت', 'جيجابايت', 'تيرابايت'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
};

// Duration formatter (in minutes)
export const formatDuration = (minutes: number): string => {
  if (minutes < 60) {
    return `${minutes} دقيقة`;
  }
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  if (remainingMinutes === 0) {
    return `${hours} ساعة`;
  }
  return `${hours} ساعة و ${remainingMinutes} دقيقة`;
};

// Status formatters
export const getEmployeeStatusText = (status: string): string => {
  const statusMap: { [key: string]: string } = {
    active: 'نشط',
    inactive: 'غير نشط',
    on_leave: 'في إجازة',
    suspended: 'موقوف',
    terminated: 'منتهي',
  };
  return statusMap[status] || status;
};

export const getEmployeeStatusColor = (status: string): string => {
  const colorMap: { [key: string]: string } = {
    active: 'success',
    inactive: 'error',
    on_leave: 'warning',
    suspended: 'error',
    terminated: 'error',
  };
  return colorMap[status] || 'default';
};

// Text truncation
export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return `${text.substring(0, maxLength)}...`;
};

// Amount in words (Arabic)
export const amountToArabicWords = (amount: number): string => {
  const formatter = new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP',
  });
  return `${formatter.format(amount)} فقط لا غير`;
};

// Working hours formatter
export const formatWorkingHours = (startTime: string, endTime: string): string => {
  return `من ${startTime} إلى ${endTime}`;
};

// Attendance status formatter
export const getAttendanceStatusText = (status: string): string => {
  const statusMap: { [key: string]: string } = {
    present: 'حاضر',
    absent: 'غائب',
    late: 'متأخر',
    early_leave: 'انصراف مبكر',
    on_leave: 'في إجازة',
  };
  return statusMap[status] || status;
};

// Leave type formatter
export const getLeaveTypeText = (type: string): string => {
  const typeMap: { [key: string]: string } = {
    annual: 'سنوية',
    sick: 'مرضية',
    casual: 'عارضة',
    unpaid: 'بدون راتب',
    emergency: 'طارئة',
  };
  return typeMap[type] || type;
};
