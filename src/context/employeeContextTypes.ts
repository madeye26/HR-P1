import {
  Employee,
  PayrollRecord,
  LeaveRequest,
  Attendance,
  Notification,
  SystemSettings,
  Department,
  Position,
  Advance,
  AdvanceInstallment
} from '../types';

export interface State {
  employees: Employee[];
  departments: Department[];
  positions: Position[];
  payrollRecords: PayrollRecord[];
  leaveRequests: LeaveRequest[];
  attendanceRecords: Attendance[];
  notifications: Notification[];
  advances: Advance[];
  advanceInstallments: AdvanceInstallment[];
  settings: SystemSettings;
  loading: boolean;
  error: string | null;
}

export type Action =
  // Employee actions
  | { type: 'SET_EMPLOYEES'; payload: Employee[] }
  | { type: 'ADD_EMPLOYEE'; payload: Employee }
  | { type: 'UPDATE_EMPLOYEE'; payload: { id: string; data: Partial<Employee> } }
  | { type: 'DELETE_EMPLOYEE'; payload: string }
  
  // Department & Position actions
  | { type: 'SET_DEPARTMENTS'; payload: Department[] }
  | { type: 'ADD_DEPARTMENT'; payload: Department }
  | { type: 'UPDATE_DEPARTMENT'; payload: { id: string; data: Partial<Department> } }
  | { type: 'SET_POSITIONS'; payload: Position[] }
  | { type: 'ADD_POSITION'; payload: Position }
  | { type: 'UPDATE_POSITION'; payload: { id: string; data: Partial<Position> } }
  
  // Payroll actions
  | { type: 'ADD_PAYROLL_RECORD'; payload: PayrollRecord }
  | { type: 'UPDATE_PAYROLL_STATUS'; payload: { id: string; status: PayrollRecord['status'] } }
  | { type: 'PROCESS_PAYROLL'; payload: { id: string; processedBy: string } }
  | { type: 'MARK_PAYROLL_PAID'; payload: { id: string; paidBy: string } }
  
  // Advance actions
  | { type: 'ADD_ADVANCE'; payload: { advance: Advance; installments: AdvanceInstallment[] } }
  | { type: 'UPDATE_ADVANCE'; payload: Advance }
  | { type: 'DELETE_ADVANCE'; payload: string }
  | { type: 'UPDATE_ADVANCE_INSTALLMENT'; payload: AdvanceInstallment }
  
  // Leave & Attendance actions
  | { type: 'ADD_LEAVE_REQUEST'; payload: LeaveRequest }
  | { type: 'UPDATE_LEAVE_REQUEST'; payload: { id: string; data: Partial<LeaveRequest> } }
  | { type: 'ADD_ATTENDANCE_RECORD'; payload: Attendance }
  | { type: 'UPDATE_ATTENDANCE'; payload: { id: string; data: Partial<Attendance> } }
  
  // Notification actions
  | { type: 'ADD_NOTIFICATION'; payload: Omit<Notification, 'status' | 'createdAt'> }
  | { type: 'MARK_NOTIFICATION_READ'; payload: string }
  | { type: 'MARK_ALL_NOTIFICATIONS_READ' }
  | { type: 'CLEAR_NOTIFICATIONS' }
  
  // Settings actions
  | { type: 'UPDATE_SETTINGS'; payload: Partial<SystemSettings> }
  
  // System actions
  | { type: 'SET_ERROR'; payload: string }
  | { type: 'CLEAR_ERROR' }
  | { type: 'SET_LOADING'; payload: boolean };

export const defaultSettings: SystemSettings = {
  companyName: 'شركة نظام إدارة الرواتب',
  workingDays: 30,
  workingHours: 8,
  overtimeRate: 1.5,
  currency: 'SAR',
  dateFormat: 'DD/MM/YYYY',
  autoBackupInterval: 24,
  theme: 'light',
  language: 'ar'
};

export const initialState: State = {
  employees: [],
  departments: [],
  positions: [],
  payrollRecords: [],
  leaveRequests: [],
  attendanceRecords: [],
  notifications: [],
  advances: [],
  advanceInstallments: [],
  settings: defaultSettings,
  loading: false,
  error: null
};
