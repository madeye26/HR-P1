import { Notification } from '../types';
import { useEmployee } from '../context/EmployeeContext';

type CreateNotificationParams = {
  type: Notification['type'];
  title: string;
  message: string;
  targetId?: string;
  targetType?: string;
};

export const useNotificationManager = () => {
  const { addNotification } = useEmployee();

  const createNotification = ({
    type,
    title,
    message,
    targetId,
    targetType,
  }: CreateNotificationParams) => {
    const notification = {
      id: `notification-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      type,
      title,
      message,
      ...(targetId && { targetId }),
      ...(targetType && { targetType }),
    };

    addNotification(notification);
    return notification.id;
  };

  const notifyEmployeeAdded = (employeeName: string, employeeId: string) => {
    createNotification({
      type: 'system',
      title: 'إضافة موظف جديد',
      message: `تم إضافة الموظف ${employeeName} بنجاح`,
      targetId: employeeId,
      targetType: 'employee',
    });
  };

  const notifyEmployeeUpdated = (employeeName: string, employeeId: string) => {
    createNotification({
      type: 'system',
      title: 'تحديث بيانات موظف',
      message: `تم تحديث بيانات الموظف ${employeeName} بنجاح`,
      targetId: employeeId,
      targetType: 'employee',
    });
  };

  const notifyPayrollProcessed = (employeeName: string, payrollId: string, amount: number) => {
    createNotification({
      type: 'payroll',
      title: 'معالجة الراتب',
      message: `تم معالجة راتب ${employeeName} بمبلغ ${amount} جنيه`,
      targetId: payrollId,
      targetType: 'payroll',
    });
  };

  const notifyAdvanceRequested = (employeeName: string, advanceId: string, amount: number) => {
    createNotification({
      type: 'advance',
      title: 'طلب سلفة جديد',
      message: `قدم الموظف ${employeeName} طلب سلفة بمبلغ ${amount} جنيه`,
      targetId: advanceId,
      targetType: 'advance',
    });
  };

  const notifyLeaveRequested = (employeeName: string, leaveId: string, days: number) => {
    createNotification({
      type: 'leave',
      title: 'طلب إجازة جديد',
      message: `قدم الموظف ${employeeName} طلب إجازة لمدة ${days} يوم`,
      targetId: leaveId,
      targetType: 'leave',
    });
  };

  const notifyAttendanceIssue = (employeeName: string, attendanceId: string, issue: string) => {
    createNotification({
      type: 'attendance',
      title: 'مشكلة في الحضور',
      message: `${issue} للموظف ${employeeName}`,
      targetId: attendanceId,
      targetType: 'attendance',
    });
  };

  const notifySystemUpdate = (title: string, message: string) => {
    createNotification({
      type: 'system',
      title,
      message,
    });
  };

  return {
    createNotification,
    notifyEmployeeAdded,
    notifyEmployeeUpdated,
    notifyPayrollProcessed,
    notifyAdvanceRequested,
    notifyLeaveRequested,
    notifyAttendanceIssue,
    notifySystemUpdate,
  };
};
