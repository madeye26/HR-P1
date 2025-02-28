import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Employee } from '../types';
import { calculatePayroll } from './payrollCalculations';
import { calculateMonthlySummary } from './attendanceManagement';
import { formatCurrency, formatNumber, formatPercentage } from './formatters';

interface ReportOptions {
  format: 'pdf' | 'excel' | 'csv';
  includeHeader: boolean;
  includeFooter: boolean;
  orientation: 'portrait' | 'landscape';
  language: 'ar' | 'en';
  watermark?: string;
  password?: string;
}

interface ReportMetadata {
  title: string;
  subtitle?: string;
  date: string;
  generatedBy: string;
  department?: string;
  period?: {
    start: string;
    end: string;
  };
}

const DEFAULT_OPTIONS: ReportOptions = {
  format: 'pdf',
  includeHeader: true,
  includeFooter: true,
  orientation: 'portrait',
  language: 'ar',
};

/**
 * Generate employee list report
 */
export const generateEmployeeListReport = (
  employees: Employee[],
  options: Partial<ReportOptions> = {}
): {
  metadata: ReportMetadata;
  data: any[];
  summary: {
    totalEmployees: number;
    activeEmployees: number;
    departmentCounts: Record<string, number>;
    averageSalary: number;
  };
} => {
  const mergedOptions = { ...DEFAULT_OPTIONS, ...options };
  
  const departmentCounts = employees.reduce((acc, emp) => {
    acc[emp.department] = (acc[emp.department] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const activeEmployees = employees.filter(emp => emp.status === 'active');
  const totalSalaries = employees.reduce((sum, emp) => sum + emp.basicSalary, 0);

  return {
    metadata: {
      title: 'تقرير الموظفين',
      date: format(new Date(), 'dd MMMM yyyy', { locale: ar }),
      generatedBy: 'النظام',
    },
    data: employees.map(emp => ({
      id: emp.id,
      name: emp.name,
      position: emp.position,
      department: emp.department,
      salary: formatCurrency(emp.basicSalary),
      joinDate: format(new Date(emp.joinDate), 'dd/MM/yyyy'),
      status: emp.status,
    })),
    summary: {
      totalEmployees: employees.length,
      activeEmployees: activeEmployees.length,
      departmentCounts,
      averageSalary: totalSalaries / employees.length,
    },
  };
};

/**
 * Generate payroll report
 */
export const generatePayrollReport = (
  employees: Employee[],
  month: number,
  year: number,
  options: Partial<ReportOptions> = {}
): {
  metadata: ReportMetadata;
  data: any[];
  summary: {
    totalBasicSalary: number;
    totalDeductions: number;
    totalAdditions: number;
    totalNetSalary: number;
    averageSalary: number;
  };
} => {
  const payrollData = employees.map(emp => {
    const payroll = calculatePayroll(emp);
    return {
      employeeId: emp.id,
      name: emp.name,
      department: emp.department,
      basicSalary: payroll.grossSalary,
      deductions: payroll.deductions.total,
      additions: payroll.additions.total,
      netSalary: payroll.netSalary,
    };
  });

  const summary = payrollData.reduce((acc, curr) => ({
    totalBasicSalary: acc.totalBasicSalary + curr.basicSalary,
    totalDeductions: acc.totalDeductions + curr.deductions,
    totalAdditions: acc.totalAdditions + curr.additions,
    totalNetSalary: acc.totalNetSalary + curr.netSalary,
    averageSalary: 0, // Calculated below
  }), {
    totalBasicSalary: 0,
    totalDeductions: 0,
    totalAdditions: 0,
    totalNetSalary: 0,
    averageSalary: 0,
  });

  summary.averageSalary = summary.totalNetSalary / employees.length;

  return {
    metadata: {
      title: 'تقرير الرواتب',
      subtitle: format(new Date(year, month - 1), 'MMMM yyyy', { locale: ar }),
      date: format(new Date(), 'dd MMMM yyyy', { locale: ar }),
      generatedBy: 'النظام',
    },
    data: payrollData,
    summary,
  };
};

/**
 * Generate attendance report
 */
export const generateAttendanceReport = (
  employees: Employee[],
  attendanceRecords: any[],
  startDate: Date,
  endDate: Date,
  options: Partial<ReportOptions> = {}
): {
  metadata: ReportMetadata;
  data: any[];
  summary: {
    totalEmployees: number;
    averageAttendanceRate: number;
    lateCount: number;
    absentCount: number;
    onLeaveCount: number;
  };
} => {
  const employeeAttendance = employees.map(emp => {
    const employeeRecords = attendanceRecords.filter(record => 
      record.employeeId === emp.id
    );
    const summary = calculateMonthlySummary(employeeRecords, startDate);

    return {
      employeeId: emp.id,
      name: emp.name,
      department: emp.department,
      presentDays: summary.presentDays,
      absentDays: summary.absentDays,
      lateDays: summary.lateDays,
      leaveDays: summary.leaveDays,
      attendanceRate: summary.attendanceRate,
    };
  });

  const summary = employeeAttendance.reduce((acc, curr) => ({
    totalEmployees: acc.totalEmployees + 1,
    averageAttendanceRate: acc.averageAttendanceRate + curr.attendanceRate,
    lateCount: acc.lateCount + curr.lateDays,
    absentCount: acc.absentCount + curr.absentDays,
    onLeaveCount: acc.onLeaveCount + curr.leaveDays,
  }), {
    totalEmployees: 0,
    averageAttendanceRate: 0,
    lateCount: 0,
    absentCount: 0,
    onLeaveCount: 0,
  });

  summary.averageAttendanceRate /= employees.length;

  return {
    metadata: {
      title: 'تقرير الحضور والانصراف',
      date: format(new Date(), 'dd MMMM yyyy', { locale: ar }),
      generatedBy: 'النظام',
      period: {
        start: format(startDate, 'dd/MM/yyyy'),
        end: format(endDate, 'dd/MM/yyyy'),
      },
    },
    data: employeeAttendance,
    summary,
  };
};

/**
 * Generate department performance report
 */
export const generateDepartmentReport = (
  department: string,
  employees: Employee[],
  attendanceRecords: any[],
  options: Partial<ReportOptions> = {}
): {
  metadata: ReportMetadata;
  data: {
    employees: any[];
    attendance: any;
    payroll: any;
  };
  summary: {
    employeeCount: number;
    totalSalaries: number;
    attendanceRate: number;
    performanceScore: number;
  };
} => {
  const departmentEmployees = employees.filter(emp => emp.department === department);
  
  // Calculate department metrics
  const totalSalaries = departmentEmployees.reduce((sum, emp) => sum + emp.basicSalary, 0);
  const avgAttendance = departmentEmployees.reduce((sum, emp) => {
    const records = attendanceRecords.filter(record => record.employeeId === emp.id);
    const summary = calculateMonthlySummary(records, new Date());
    return sum + summary.attendanceRate;
  }, 0) / departmentEmployees.length;

  // Simple performance score calculation (example)
  const performanceScore = (avgAttendance * 0.4) + 
    ((departmentEmployees.length / employees.length) * 0.3) +
    ((totalSalaries / (employees.length * 3000)) * 0.3); // Assuming 3000 is base salary

  return {
    metadata: {
      title: 'تقرير أداء القسم',
      subtitle: department,
      date: format(new Date(), 'dd MMMM yyyy', { locale: ar }),
      generatedBy: 'النظام',
      department,
    },
    data: {
      employees: departmentEmployees.map(emp => ({
        id: emp.id,
        name: emp.name,
        position: emp.position,
        salary: emp.basicSalary,
        joinDate: emp.joinDate,
      })),
      attendance: {
        rate: avgAttendance,
        records: attendanceRecords.filter(record => 
          departmentEmployees.some(emp => emp.id === record.employeeId)
        ),
      },
      payroll: {
        totalSalaries,
        averageSalary: totalSalaries / departmentEmployees.length,
      },
    },
    summary: {
      employeeCount: departmentEmployees.length,
      totalSalaries,
      attendanceRate: avgAttendance,
      performanceScore,
    },
  };
};

/**
 * Format report data based on options
 */
export const formatReportData = (
  data: any[],
  options: ReportOptions
): string => {
  switch (options.format) {
    case 'csv':
      return formatAsCSV(data);
    case 'excel':
      return formatAsExcel(data);
    case 'pdf':
    default:
      return formatAsPDF(data);
  }
};

// Helper functions for different formats
const formatAsCSV = (data: any[]): string => {
  if (data.length === 0) return '';
  
  const headers = Object.keys(data[0]);
  const rows = data.map(item => 
    headers.map(header => item[header]).join(',')
  );
  
  return [headers.join(','), ...rows].join('\n');
};

const formatAsExcel = (data: any[]): string => {
  // Implementation would depend on Excel library being used
  return JSON.stringify(data);
};

const formatAsPDF = (data: any[]): string => {
  // Implementation would depend on PDF library being used
  return JSON.stringify(data);
};
