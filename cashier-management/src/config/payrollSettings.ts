import { PayrollSettings } from '../types/payroll';

// Default payroll settings that can be modified through the UI
export const defaultPayrollSettings: PayrollSettings = {
  rates: {
    socialInsurance: 0.11, // 11% of basic salary
    healthInsurance: 0.03, // 3% of basic salary
    overtimeRate: 1.5, // 150% of hourly rate
    transportation: 300, // Fixed transportation allowance
    workingDaysPerMonth: 22,
    workingHoursPerDay: 8,
    dailyRateCalculation: 'monthly', // 'monthly' or 'hourly'
    incentiveCalculation: 'percentage', // 'percentage' or 'fixed'
  },
  
  taxBrackets: [
    { min: 0, max: 15000, rate: 0 }, // 0%
    { min: 15000, max: 30000, rate: 0.025 }, // 2.5%
    { min: 30000, max: 45000, rate: 0.10 }, // 10%
    { min: 45000, max: 60000, rate: 0.15 }, // 15%
    { min: 60000, max: 200000, rate: 0.20 }, // 20%
    { min: 200000, max: 400000, rate: 0.225 }, // 22.5%
    { min: 400000, max: Infinity, rate: 0.25 }, // 25%
  ],

  deductions: {
    enableSocialInsurance: true,
    enableHealthInsurance: true,
    enableIncomeTax: true,
    enableAbsenceDeductions: true,
    absenceCalculation: 'daily', // 'daily' or 'hourly'
    penaltyCalculation: 'fixed', // 'fixed' or 'percentage'
  },

  additions: {
    enableOvertime: true,
    enableTransportation: true,
    enableBonus: true,
    enableIncentives: true,
    overtimeCalculation: 'hourly', // 'hourly' or 'fixed'
    bonusCalculation: 'fixed', // 'fixed' or 'percentage'
  },

  allowances: {
    transportation: true,
    meals: false,
    housing: false,
    phone: false,
  },
};
