/// <reference types="vitest" />
import { renderHook, act } from '@testing-library/react';
import { useNotificationManager } from '../notificationManager';
import { useEmployee } from '../../context/EmployeeContext';
import type { Mock } from 'vitest';

declare module 'vitest' {
  interface TestContext {
    mockAddNotification: Mock;
  }
}

vi.mock('../../context/EmployeeContext', () => ({
  useEmployee: vi.fn(),
}));

describe('useNotificationManager', () => {
  const mockAddNotification = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    (useEmployee as Mock).mockReturnValue({
      addNotification: mockAddNotification,
    });
  });

  it('should create a basic notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.createNotification({
        type: 'system',
        title: 'Test Title',
        message: 'Test Message',
      });
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
    });
    expect(notification.id).toBeDefined();
  });

  it('should create an employee added notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.notifyEmployeeAdded('John Doe', 'emp-123');
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'system',
      title: 'إضافة موظف جديد',
      message: expect.stringContaining('John Doe'),
      targetId: 'emp-123',
      targetType: 'employee',
    });
  });

  it('should create a payroll processed notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.notifyPayrollProcessed('John Doe', 'pay-123', 5000);
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'payroll',
      title: 'معالجة الراتب',
      message: expect.stringContaining('5000'),
      targetId: 'pay-123',
      targetType: 'payroll',
    });
  });

  it('should create a leave request notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.notifyLeaveRequested('John Doe', 'leave-123', 5);
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'leave',
      title: 'طلب إجازة جديد',
      message: expect.stringContaining('5'),
      targetId: 'leave-123',
      targetType: 'leave',
    });
  });

  it('should create an attendance issue notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.notifyAttendanceIssue(
        'John Doe',
        'att-123',
        'تأخر في الحضور'
      );
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'attendance',
      title: 'مشكلة في الحضور',
      message: expect.stringContaining('تأخر في الحضور'),
      targetId: 'att-123',
      targetType: 'attendance',
    });
  });

  it('should create a system update notification', () => {
    const { result } = renderHook(() => useNotificationManager());

    act(() => {
      result.current.notifySystemUpdate(
        'تحديث النظام',
        'تم تحديث النظام بنجاح'
      );
    });

    expect(mockAddNotification).toHaveBeenCalledTimes(1);
    const notification = mockAddNotification.mock.calls[0][0];
    expect(notification).toMatchObject({
      type: 'system',
      title: 'تحديث النظام',
      message: 'تم تحديث النظام بنجاح',
    });
    expect(notification.targetId).toBeUndefined();
    expect(notification.targetType).toBeUndefined();
  });

  it('should generate unique IDs for each notification', () => {
    const { result } = renderHook(() => useNotificationManager());
    const ids = new Set();

    // Create multiple notifications
    for (let i = 0; i < 10; i++) {
      act(() => {
        result.current.createNotification({
          type: 'system',
          title: `Test ${i}`,
          message: `Message ${i}`,
        });
      });

      const notification = mockAddNotification.mock.calls[i][0];
      expect(ids.has(notification.id)).toBeFalsy();
      ids.add(notification.id);
    }

    expect(ids.size).toBe(10);
  });
});
