import { Employee, Attendance } from '../types';

export interface AttendanceStats {
  date: string;
  present: number;
  absent: number;
  late: number;
}

export interface PayrollStats {
  month: string;
  salaries: number;
  advances: number;
  deductions: number;
}

export interface DepartmentStats {
  name: string;
  employeeCount: number;
  totalSalaries: number;
}

export const calculateAttendanceStats = (
  employees: Employee[],
  attendanceRecords: Attendance[],
  days: number = 7
): AttendanceStats[] => {
  const stats: AttendanceStats[] = [];
  const today = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const dateStr = date.toISOString().split('T')[0];

    const dayRecords = attendanceRecords.filter(record => 
      record.date.toString().split('T')[0] === dateStr
    );

    stats.push({
      date: dateStr,
      present: dayRecords.filter(record => record.status === 'present').length,
      absent: employees.length - dayRecords.length,
      late: dayRecords.filter(record => record.status === 'late').length
    });
  }

  return stats;
};

export const calculatePayrollStats = (
  employees: Employee[],
  months: number = 6
): PayrollStats[] => {
  const stats: PayrollStats[] = [];
  const today = new Date();

  for (let i = months - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setMonth(date.getMonth() - i);
    const monthStr = date.toLocaleString('ar-EG', { month: 'long', year: 'numeric' });

    const totalSalaries = employees.reduce((sum, emp) => sum + emp.basicSalary + emp.monthlyIncentives, 0);
    const totalAdvances = employees.reduce((sum, emp) => sum + emp.advances, 0);
    const totalDeductions = employees.reduce((sum, emp) => 
      sum + emp.penalties + emp.hourlyDeductions + (emp.absenceDays * (emp.basicSalary / 30)), 0);

    stats.push({
      month: monthStr,
      salaries: totalSalaries,
      advances: totalAdvances,
      deductions: totalDeductions
    });
  }

  return stats;
};

export const calculateDepartmentStats = (employees: Employee[]): DepartmentStats[] => {
  const departmentMap = new Map<string, { count: number; salaries: number }>();

  employees.forEach(employee => {
    const dept = employee.department || 'غير محدد';
    const current = departmentMap.get(dept) || { count: 0, salaries: 0 };
    
    departmentMap.set(dept, {
      count: current.count + 1,
      salaries: current.salaries + employee.basicSalary + employee.monthlyIncentives
    });
  });

  return Array.from(departmentMap.entries()).map(([name, stats]) => ({
    name,
    employeeCount: stats.count,
    totalSalaries: stats.salaries
  }));
};

export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP'
  }).format(amount);
};
