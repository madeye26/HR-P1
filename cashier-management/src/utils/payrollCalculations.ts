import { Employee } from '../types/employee';
import { PayrollSettings, PayrollRecord } from '../types/payroll';
import { defaultPayrollSettings } from '../config/payrollSettings';

/**
 * Calculate income tax based on annual salary and tax brackets
 */
export const calculateIncomeTax = (annualSalary: number, settings: PayrollSettings = defaultPayrollSettings): number => {
  if (!settings.deductions.enableIncomeTax) return 0;
  
  let tax = 0;
  let remainingSalary = annualSalary;

  for (const bracket of settings.taxBrackets) {
    if (remainingSalary <= 0) break;
    const taxableAmount = Math.min(remainingSalary, bracket.max - bracket.min);
    tax += taxableAmount * bracket.rate;
    remainingSalary -= taxableAmount;
  }

  return tax / 12; // Convert annual tax to monthly
};

/**
 * Calculate daily rate based on configuration
 */
export const calculateDailyRate = (basicSalary: number, settings: PayrollSettings = defaultPayrollSettings): number => {
  if (settings.rates.dailyRateCalculation === 'monthly') {
    return basicSalary / settings.rates.workingDaysPerMonth;
  } else {
    return (basicSalary / settings.rates.workingDaysPerMonth) / settings.rates.workingHoursPerDay;
  }
};

/**
 * Calculate overtime rate
 */
export const calculateOvertimeRate = (basicSalary: number, settings: PayrollSettings = defaultPayrollSettings): number => {
  const hourlyRate = (basicSalary / settings.rates.workingDaysPerMonth) / settings.rates.workingHoursPerDay;
  return hourlyRate * settings.rates.overtimeRate;
};

/**
 * Calculate social insurance deductions
 */
export const calculateSocialInsurance = (basicSalary: number, settings: PayrollSettings = defaultPayrollSettings): number => {
  return settings.deductions.enableSocialInsurance ? basicSalary * settings.rates.socialInsurance : 0;
};

/**
 * Calculate health insurance deductions
 */
export const calculateHealthInsurance = (basicSalary: number, settings: PayrollSettings = defaultPayrollSettings): number => {
  return settings.deductions.enableHealthInsurance ? basicSalary * settings.rates.healthInsurance : 0;
};

/**
 * Calculate overtime amount
 */
export const calculateOvertimeAmount = (
  basicSalary: number, 
  hours: number, 
  settings: PayrollSettings = defaultPayrollSettings
): number => {
  if (!settings.additions.enableOvertime) return 0;
  
  if (settings.additions.overtimeCalculation === 'hourly') {
    const overtimeRate = calculateOvertimeRate(basicSalary, settings);
    return hours * overtimeRate;
  } else {
    // Fixed overtime rate if configured
    return hours * settings.rates.overtimeRate;
  }
};

/**
 * Calculate absence deductions
 */
export const calculateAbsenceDeductions = (
  basicSalary: number, 
  days: number, 
  settings: PayrollSettings = defaultPayrollSettings
): number => {
  if (!settings.deductions.enableAbsenceDeductions) return 0;

  if (settings.deductions.absenceCalculation === 'daily') {
    const dailyRate = calculateDailyRate(basicSalary, settings);
    return days * dailyRate;
  } else {
    // Hourly calculation
    const hourlyRate = (basicSalary / settings.rates.workingDaysPerMonth) / settings.rates.workingHoursPerDay;
    return days * settings.rates.workingHoursPerDay * hourlyRate;
  }
};

/**
 * Calculate incentives
 */
export const calculateIncentives = (
  basicSalary: number,
  incentiveAmount: number,
  settings: PayrollSettings = defaultPayrollSettings
): number => {
  if (!settings.additions.enableIncentives) return 0;

  if (settings.rates.incentiveCalculation === 'percentage') {
    return basicSalary * (incentiveAmount / 100);
  } else {
    return incentiveAmount;
  }
};

/**
 * Calculate full payroll record for an employee
 */
export const calculatePayrollRecord = (
  employee: Employee,
  month: number,
  year: number,
  settings: PayrollSettings = defaultPayrollSettings
): PayrollRecord => {
  // Calculate rates
  const dailyRate = calculateDailyRate(employee.basicSalary, settings);
  const overtimeRate = calculateOvertimeRate(employee.basicSalary, settings);

  // Calculate additions
  const overtimeAmount = calculateOvertimeAmount(employee.basicSalary, employee.overtimeHours || 0, settings);
  const incentives = calculateIncentives(employee.basicSalary, employee.monthlyIncentives || 0, settings);
  
  // Calculate deductions
  const socialInsurance = calculateSocialInsurance(employee.basicSalary, settings);
  const healthInsurance = calculateHealthInsurance(employee.basicSalary, settings);
  const absenceDeductions = calculateAbsenceDeductions(employee.basicSalary, employee.absenceDays || 0, settings);
  const incomeTax = calculateIncomeTax(employee.basicSalary * 12, settings);

  // Calculate totals
  const totalSalary = employee.basicSalary + incentives + overtimeAmount + (employee.bonus || 0);
  const totalDeductions = socialInsurance + healthInsurance + incomeTax + absenceDeductions + 
                         (employee.penalties || 0) + (employee.advances || 0);

  return {
    id: `${employee.id}-${year}-${month}`,
    employeeId: employee.id,
    employeeCode: employee.code || '',
    employeeName: employee.name,
    position: employee.position?.title || '',
    month,
    year,
    
    // Basic salary components
    basicSalary: employee.basicSalary,
    dailyRate,
    overtimeRate,
    
    // Work details
    workingDays: settings.rates.workingDaysPerMonth - (employee.absenceDays || 0),
    absentDays: employee.absenceDays || 0,
    overtimeHours: employee.overtimeHours || 0,
    
    // Additions
    incentives,
    bonus: employee.bonus || 0,
    overtimeAmount,
    monthlyIncentives: employee.monthlyIncentives || 0,
    
    // Gross calculations
    totalSalary,
    
    // Deductions
    purchases: employee.purchases || 0,
    advances: employee.advances || 0,
    absenceDeductions,
    hourlyDeductions: 0, // This should be calculated based on attendance records
    penaltyDays: employee.penaltyDays || 0,
    penalties: employee.penalties || 0,
    
    // Final calculations
    netSalary: totalSalary - totalDeductions,
    dailyRateWithIncentives: dailyRate + (incentives / settings.rates.workingDaysPerMonth),
    
    // Status
    status: 'pending',
  };
};

/**
 * Calculate department payroll summary
 */
export const calculateDepartmentPayroll = (
  employees: Employee[], 
  settings: PayrollSettings = defaultPayrollSettings
): {
  totalBasicSalary: number;
  totalIncentives: number;
  totalDeductions: number;
  totalNetSalary: number;
  employeeCount: number;
} => {
  const month = new Date().getMonth() + 1;
  const year = new Date().getFullYear();

  return employees.reduce((acc, employee) => {
    const payroll = calculatePayrollRecord(employee, month, year, settings);
    return {
      totalBasicSalary: acc.totalBasicSalary + payroll.basicSalary,
      totalIncentives: acc.totalIncentives + payroll.incentives,
      totalDeductions: acc.totalDeductions + (payroll.totalSalary - payroll.netSalary),
      totalNetSalary: acc.totalNetSalary + payroll.netSalary,
      employeeCount: acc.employeeCount + 1,
    };
  }, {
    totalBasicSalary: 0,
    totalIncentives: 0,
    totalDeductions: 0,
    totalNetSalary: 0,
    employeeCount: 0,
  });
};

/**
 * Format salary components for display
 */
export const formatSalaryComponents = (record: PayrollRecord): { [key: string]: string } => {
  return {
    'كود الموظف': record.employeeCode,
    'اسم الموظف': record.employeeName,
    'الوظيفة': record.position,
    'قيمه وحده اليوم': record.dailyRate.toLocaleString('ar-EG'),
    'قيمة وحدة الاوفر تايم': record.overtimeRate.toLocaleString('ar-EG'),
    'عدد ساعات الاوفرتايم': record.overtimeHours.toLocaleString('ar-EG'),
    'الراتب': record.basicSalary.toLocaleString('ar-EG'),
    'الحوافز': record.incentives.toLocaleString('ar-EG'),
    'مكافأة': record.bonus.toLocaleString('ar-EG'),
    'قيمة الاوفر تايم': record.overtimeAmount.toLocaleString('ar-EG'),
    'اجمالي الراتب': record.totalSalary.toLocaleString('ar-EG'),
    'المشتريات': record.purchases.toLocaleString('ar-EG'),
    'السلف': record.advances.toLocaleString('ar-EG'),
    'غيابات': record.absentDays.toString(),
    'خصومات/ساعات': record.hourlyDeductions.toLocaleString('ar-EG'),
    'ايام الجزاءات': record.penaltyDays.toString(),
    'الجزاءات': record.penalties.toLocaleString('ar-EG'),
    'صافي الراتب': record.netSalary.toLocaleString('ar-EG'),
    'الحوافز الشهريه': record.monthlyIncentives.toLocaleString('ar-EG'),
    'قيمه وحده اليوم بالحوافز': record.dailyRateWithIncentives.toLocaleString('ar-EG'),
  };
};
