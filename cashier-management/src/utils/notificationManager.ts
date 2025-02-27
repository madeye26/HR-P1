import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Employee } from '../types';

export type NotificationType = 'info' | 'warning' | 'error' | 'success';
export type NotificationCategory = 'attendance' | 'payroll' | 'leave' | 'system';
export type NotificationPriority = 'low' | 'medium' | 'high' | 'urgent';

export interface Notification {
  id: string;
  title: string;
  message: string;
  type: NotificationType;
  category: NotificationCategory;
  priority: NotificationPriority;
  timestamp: string;
  isRead: boolean;
  isUrgent: boolean;
  actionUrl?: string;
  metadata?: Record<string, any>;
  recipients?: string[];
}

interface NotificationPreferences {
  email: boolean;
  push: boolean;
  sms: boolean;
  categories: {
    attendance: boolean;
    payroll: boolean;
    leave: boolean;
    system: boolean;
  };
}

const DEFAULT_PREFERENCES: NotificationPreferences = {
  email: true,
  push: true,
  sms: false,
  categories: {
    attendance: true,
    payroll: true,
    leave: true,
    system: true,
  },
};

/**
 * Create a new notification
 */
export const createNotification = (
  title: string,
  message: string,
  type: NotificationType,
  category: NotificationCategory,
  priority: NotificationPriority = 'medium',
  actionUrl?: string,
  metadata?: Record<string, any>,
  recipients?: string[]
): Notification => {
  return {
    id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    title,
    message,
    type,
    category,
    priority,
    timestamp: new Date().toISOString(),
    isRead: false,
    isUrgent: priority === 'urgent',
    actionUrl,
    metadata,
    recipients,
  };
};

/**
 * Create attendance-related notifications
 */
export const createAttendanceNotification = (
  employee: Employee,
  status: 'late' | 'absent' | 'early_leave',
  date: Date = new Date()
): Notification => {
  const formattedDate = format(date, 'dd MMMM yyyy', { locale: ar });
  
  const messages = {
    late: `تأخر الموظف ${employee.name} عن موعد الحضور يوم ${formattedDate}`,
    absent: `تغيب الموظف ${employee.name} عن العمل يوم ${formattedDate}`,
    early_leave: `غادر الموظف ${employee.name} قبل موعد الانصراف يوم ${formattedDate}`,
  };

  const titles = {
    late: 'تأخر في الحضور',
    absent: 'غياب موظف',
    early_leave: 'مغادرة مبكرة',
  };

  return createNotification(
    titles[status],
    messages[status],
    'warning',
    'attendance',
    'medium',
    `/attendance?employee=${employee.id}&date=${format(date, 'yyyy-MM-dd')}`,
    { employeeId: employee.id, status, date: date.toISOString() }
  );
};

/**
 * Create leave request notifications
 */
export const createLeaveRequestNotification = (
  employee: Employee,
  startDate: Date,
  endDate: Date,
  type: string
): Notification => {
  const formattedStartDate = format(startDate, 'dd MMMM yyyy', { locale: ar });
  const formattedEndDate = format(endDate, 'dd MMMM yyyy', { locale: ar });

  return createNotification(
    'طلب إجازة جديد',
    `قدم الموظف ${employee.name} طلب إجازة ${type} من ${formattedStartDate} إلى ${formattedEndDate}`,
    'info',
    'leave',
    'medium',
    `/leave/requests`,
    { employeeId: employee.id, startDate: startDate.toISOString(), endDate: endDate.toISOString(), type }
  );
};

/**
 * Create payroll notifications
 */
export const createPayrollNotification = (
  type: 'processed' | 'pending' | 'overdue',
  month: number,
  year: number,
  count?: number
): Notification => {
  const formattedDate = format(new Date(year, month - 1), 'MMMM yyyy', { locale: ar });
  
  const messages = {
    processed: `تم معالجة رواتب ${formattedDate} بنجاح`,
    pending: `يجب معالجة رواتب ${formattedDate} قبل نهاية الشهر`,
    overdue: `تأخر معالجة رواتب ${formattedDate}`,
  };

  const titles = {
    processed: 'تم معالجة الرواتب',
    pending: 'رواتب معلقة',
    overdue: 'رواتب متأخرة',
  };

  const priorities: Record<typeof type, NotificationPriority> = {
    processed: 'low',
    pending: 'medium',
    overdue: 'high',
  };

  return createNotification(
    titles[type],
    count ? `${messages[type]} (${count} موظف)` : messages[type],
    type === 'processed' ? 'success' : 'warning',
    'payroll',
    priorities[type],
    '/payroll',
    { type, month, year, count }
  );
};

/**
 * Create system notifications
 */
export const createSystemNotification = (
  title: string,
  message: string,
  priority: NotificationPriority = 'medium',
  actionUrl?: string
): Notification => {
  return createNotification(
    title,
    message,
    'info',
    'system',
    priority,
    actionUrl
  );
};

/**
 * Create backup notifications
 */
export const createBackupNotification = (
  status: 'success' | 'failed',
  size?: number,
  error?: string
): Notification => {
  const formatSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  if (status === 'success') {
    return createNotification(
      'نسخ احتياطي ناجح',
      `تم إنشاء نسخة احتياطية جديدة بحجم ${size ? formatSize(size) : 'غير معروف'}`,
      'success',
      'system',
      'low',
      '/backup'
    );
  }

  return createNotification(
    'فشل النسخ الاحتياطي',
    `فشل إنشاء النسخة الاحتياطية: ${error || 'خطأ غير معروف'}`,
    'error',
    'system',
    'high',
    '/backup'
  );
};

/**
 * Filter notifications based on preferences
 */
export const filterNotifications = (
  notifications: Notification[],
  preferences: NotificationPreferences = DEFAULT_PREFERENCES
): Notification[] => {
  return notifications.filter(notification => 
    preferences.categories[notification.category]
  );
};

/**
 * Sort notifications by priority and date
 */
export const sortNotifications = (notifications: Notification[]): Notification[] => {
  const priorityWeight = {
    urgent: 4,
    high: 3,
    medium: 2,
    low: 1,
  };

  return [...notifications].sort((a, b) => {
    // First sort by read status
    if (!a.isRead && b.isRead) return -1;
    if (a.isRead && !b.isRead) return 1;

    // Then by priority
    const priorityDiff = priorityWeight[b.priority] - priorityWeight[a.priority];
    if (priorityDiff !== 0) return priorityDiff;

    // Finally by date
    return new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime();
  });
};

/**
 * Get notification color based on type
 */
export const getNotificationColor = (type: NotificationType): string => {
  const colorMap: Record<NotificationType, string> = {
    info: 'primary',
    warning: 'warning',
    error: 'error',
    success: 'success',
  };
  return colorMap[type];
};

/**
 * Format notification timestamp
 */
export const formatNotificationTime = (timestamp: string): string => {
  const date = new Date(timestamp);
  const now = new Date();
  const diffInHours = Math.abs(now.getTime() - date.getTime()) / 36e5;

  if (diffInHours < 24) {
    return format(date, 'hh:mm a', { locale: ar });
  }
  if (diffInHours < 48) {
    return 'أمس';
  }
  return format(date, 'dd MMMM yyyy', { locale: ar });
};
