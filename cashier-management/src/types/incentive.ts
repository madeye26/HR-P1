export type IncentiveType = 'monthly' | 'daily' | 'yearly';
export type IncentiveCategory = 'performance' | 'attendance' | 'sales' | 'other';

export interface Incentive {
  id: string;
  employeeId: string;
  type: IncentiveType;
  category: IncentiveCategory;
  amount: number;
  date: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected' | 'paid';
  approvedBy?: string;
  approvalDate?: string;
  notes?: string;
  criteria?: {
    targetAmount?: number;
    achievedAmount?: number;
    targetDays?: number;
    achievedDays?: number;
    otherMetrics?: Record<string, number>;
  };
}

export interface IncentiveRule {
  id: string;
  name: string;
  type: IncentiveType;
  category: IncentiveCategory;
  description: string;
  formula: string; // e.g., "salesAmount * 0.02" for 2% commission
  minAmount?: number;
  maxAmount?: number;
  conditions?: {
    minDays?: number;
    minSales?: number;
    otherConditions?: Record<string, any>;
  };
  isActive: boolean;
}

export interface IncentiveCalculation {
  employeeId: string;
  ruleId: string;
  period: {
    startDate: string;
    endDate: string;
  };
  metrics: {
    salesAmount?: number;
    attendanceDays?: number;
    performanceScore?: number;
    otherMetrics?: Record<string, number>;
  };
  result: {
    baseAmount: number;
    adjustments: {
      reason: string;
      amount: number;
    }[];
    finalAmount: number;
  };
}

export interface IncentiveReport {
  period: {
    startDate: string;
    endDate: string;
  };
  summary: {
    totalAmount: number;
    byType: Record<IncentiveType, number>;
    byCategory: Record<IncentiveCategory, number>;
    employeeCount: number;
  };
  details: {
    employeeId: string;
    employeeName: string;
    department: string;
    incentives: Incentive[];
    totalAmount: number;
  }[];
}

export interface IncentiveSettings {
  approvalRequired: boolean;
  autoCalculate: boolean;
  calculationDay: number; // Day of month for monthly calculations
  notifyEmployees: boolean;
  notifyApprovers: boolean;
  maxMonthlyPercentage: number; // Maximum percentage of base salary
  defaultRules: {
    attendance: {
      fullAttendanceBonus: number;
      noLateBonus: number;
    };
    performance: {
      excellentBonus: number;
      goodBonus: number;
    };
    sales: {
      commissionRate: number;
      bonusThresholds: {
        amount: number;
        bonus: number;
      }[];
    };
  };
}
