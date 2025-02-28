import { Employee } from './employee';

export interface PayrollSettings {
  rates: {
    socialInsurance: number;
    healthInsurance: number;
    overtimeRate: number;
    transportation: number;
    workingDaysPerMonth: number;
    workingHoursPerDay: number;
    dailyRateCalculation: 'monthly' | 'hourly';
    incentiveCalculation: 'percentage' | 'fixed';
  };
  taxBrackets: Array<{
    min: number;
    max: number;
    rate: number;
  }>;
  deductions: {
    enableSocialInsurance: boolean;
    enableHealthInsurance: boolean;
    enableIncomeTax: boolean;
    enableAbsenceDeductions: boolean;
    absenceCalculation: 'daily' | 'hourly';
    penaltyCalculation: 'fixed' | 'percentage';
  };
  additions: {
    enableOvertime: boolean;
    enableTransportation: boolean;
    enableBonus: boolean;
    enableIncentives: boolean;
    overtimeCalculation: 'hourly' | 'fixed';
    bonusCalculation: 'fixed' | 'percentage';
  };
  allowances: {
    transportation: boolean;
    meals: boolean;
    housing: boolean;
    phone: boolean;
  };
}

export interface PayrollRecord {
  id: string;
  employeeId: string;
  employeeCode: string;
  employeeName: string;
  position: string;
  month: number;
  year: number;
  
  // Basic salary components
  basicSalary: number;
  dailyRate: number;
  overtimeRate: number;
  
  // Work details
  workingDays: number;
  absentDays: number;
  overtimeHours: number;
  
  // Additions
  incentives: number;
  bonus: number;
  overtimeAmount: number;
  monthlyIncentives: number;
  
  // Gross calculations
  totalSalary: number;
  
  // Deductions
  purchases: number;
  advances: number;
  absenceDeductions: number;
  hourlyDeductions: number;
  penaltyDays: number;
  penalties: number;
  
  // Final calculations
  netSalary: number;
  dailyRateWithIncentives: number;
  
  // Status and metadata
  status: 'pending' | 'processed' | 'paid';
  processedAt?: string;
  paidAt?: string;
  notes?: string;
}

export interface PayrollCalculation {
  employeeId: string;
  month: number;
  year: number;
  basicSalary: number;
  incentives: number;
  deductions: number;
  netSalary: number;
}

export interface PayrollSummary {
  totalBasicSalary: number;
  totalIncentives: number;
  totalDeductions: number;
  totalNetSalary: number;
  employeeCount: number;
  processedCount: number;
  pendingCount: number;
}

export interface PayrollFilters {
  month?: number;
  year?: number;
  status?: PayrollRecord['status'];
  department?: string;
}

export interface PayrollReportOptions {
  includeDetails: boolean;
  includeSummary: boolean;
  groupByDepartment: boolean;
  format: 'pdf' | 'excel' | 'csv';
}

export interface PayrollManagementProps {
  employees: Employee[];
  settings: PayrollSettings;
  onProcessPayroll: (payroll: PayrollRecord[]) => void;
  onUpdateSettings: (settings: PayrollSettings) => void;
}
