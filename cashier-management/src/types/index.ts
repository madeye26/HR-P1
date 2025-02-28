import { Employee } from './employee';
import { PayrollRecord } from './payroll';
import { Advance, AdvanceInstallment } from './advance';

export interface LeaveRequest {
  id: string;
  employeeId: string;
  startDate: string;
  endDate: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  type: 'annual' | 'sick' | 'unpaid' | 'other';
  approvedBy?: string;
  approvalDate?: string;
  notes?: string;
}

export interface Attendance {
  id: string;
  employeeId: string;
  date: string;
  checkIn: string;
  checkOut: string | null;
  status: 'present' | 'absent' | 'late' | 'early_leave';
  overtimeHours: number;
  notes: string | null;
}

export interface Notification {
  id: string;
  type: 'payroll' | 'advance' | 'leave' | 'attendance' | 'system';
  title: string;
  message: string;
  status: 'read' | 'unread';
  createdAt: string;
  targetId?: string;
  targetType?: string;
}

export interface Department {
  id: string;
  name: string;
  code: string;
  managerId?: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Position {
  id: string;
  title: string;
  departmentId: string;
  level: number;
  minSalary: number;
  maxSalary: number;
  description?: string;
}

export interface SystemSettings {
  companyName: string;
  workingDays: number;
  workingHours: number;
  overtimeRate: number;
  currency: string;
  dateFormat: string;
  autoBackupInterval: number;
  theme: 'light' | 'dark';
  language: 'ar' | 'en';
}

export type {
  Employee,
  PayrollRecord,
  Advance,
  AdvanceInstallment
};
