import React, { createContext, useContext, useReducer, useEffect } from 'react';
import {
  Employee,
  PayrollRecord,
  LeaveRequest,
  Attendance,
  Notification,
  SystemSettings,
  Department,
  Position
} from '../types';

interface State {
  employees: Employee[];
  departments: Department[];
  positions: Position[];
  payrollRecords: PayrollRecord[];
  leaveRequests: LeaveRequest[];
  attendanceRecords: Attendance[];
  notifications: Notification[];
  settings: SystemSettings;
  loading: boolean;
  error: string | null;
}

// Initial system settings
const defaultSettings: SystemSettings = {
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

// Initial state
const initialState: State = {
  employees: [],
  departments: [],
  positions: [],
  payrollRecords: [],
  leaveRequests: [],
  attendanceRecords: [],
  notifications: [],
  settings: defaultSettings,
  loading: false,
  error: null
};

// Context
const EmployeeContext = createContext<{
  state: State;
  dispatch: React.Dispatch<Action>;
} | undefined>(undefined);

// Custom hook to use the employee context
export function useEmployee() {
  const context = useContext(EmployeeContext);
  if (context === undefined) {
    throw new Error('useEmployee must be used within an EmployeeProvider');
  }
  return context;
}

export { EmployeeContext };
