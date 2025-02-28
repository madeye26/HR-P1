import { Employee } from './employee';

export interface EmployeeListProps {
  employees: Employee[];
  onUpdateEmployee: (id: string, data: Partial<Employee>) => void;
}

export interface EmployeeFilters {
  department?: string;
  status?: Employee['status'];
  searchTerm?: string;
}

export interface EmployeeSort {
  field: keyof Employee;
  direction: 'asc' | 'desc';
}

export interface EmployeeListState {
  filters: EmployeeFilters;
  sort: EmployeeSort;
  page: number;
  rowsPerPage: number;
}

export interface EmployeeAction {
  type: 'edit' | 'delete' | 'view' | 'attendance' | 'payroll' | 'leave';
  employeeId: string;
}

export interface EmployeeStats {
  totalEmployees: number;
  activeEmployees: number;
  onLeaveEmployees: number;
  inactiveEmployees: number;
  byDepartment: {
    [department: string]: number;
  };
}

export interface EmployeeExportOptions {
  format: 'pdf' | 'excel' | 'csv';
  includePersonalInfo: boolean;
  includeSalaryInfo: boolean;
  includeAttendance: boolean;
  selectedEmployees?: string[];
}

export interface EmployeeBulkAction {
  action: 'update' | 'delete' | 'export';
  employeeIds: string[];
  data?: Partial<Employee>;
  exportOptions?: EmployeeExportOptions;
}
