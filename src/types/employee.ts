export interface Position {
  title: string;
  department: string;
  code: string;
}

export interface Employee {
  id: string;
  code: string;
  name: string;
  position: Position;
  department: string;
  
  // Salary Components
  basicSalary: number;
  monthlyIncentives: number;
  overtimeHours: number;
  bonus: number;
  
  // Deductions
  absenceDays: number;
  penalties: number;
  advances: number;
  purchases: number;
  penaltyDays: number;
  hourlyDeductions: number;
  
  // Work Details
  joinDate: string;
  status: 'active' | 'inactive' | 'on_leave';
  workSchedule?: {
    startTime: string;
    endTime: string;
    workingDays: number[];
  };
  
  // Personal Information
  nationalId: string;
  phoneNumber: string;
  email: string;
  address: string;
  
  // Banking & Insurance
  bankAccount?: string;
  bankName?: string;
  insuranceNumber?: string;
  
  // Emergency Contact
  emergencyContact: {
    name: string;
    relation: string;
    phone: string;
  };
  
  // Payroll History
  lastPayrollDate?: string;
  lastPayrollAmount?: number;
}

export interface EmployeeListProps {
  employees: Employee[];
  onUpdateEmployee: (employee: Employee) => void;
}

export interface PayrollManagementProps {
  employees: Employee[];
  onProcessPayroll: (data: {
    employeeId: string;
    month: number;
    year: number;
    basicSalary: number;
    incentives: number;
    deductions: number;
    netSalary: number;
  }) => void;
}
