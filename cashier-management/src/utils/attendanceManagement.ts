import { differenceInMinutes, format, parse, isWithinInterval, startOfMonth, endOfMonth } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Employee } from '../types';

interface AttendanceRecord {
  id: string;
  employeeId: string;
  date: string;
  checkIn: string;
  checkOut: string | null;
  status: 'present' | 'absent' | 'late' | 'early_leave' | 'on_leave';
  overtime: number;
  notes: string;
}

interface AttendanceSummary {
  totalDays: number;
  presentDays: number;
  absentDays: number;
  lateDays: number;
  earlyLeaveDays: number;
  leaveDays: number;
  totalOvertime: number;
  averageCheckIn: string;
  averageCheckOut: string;
  attendanceRate: number;
}

interface WorkingHours {
  start: string;
  end: string;
  graceMinutes: number;
  minHours: number;
  maxOvertime: number;
}

const DEFAULT_WORKING_HOURS: WorkingHours = {
  start: '09:00',
  end: '17:00',
  graceMinutes: 15,
  minHours: 8,
  maxOvertime: 4,
};

/**
 * Calculate if an employee is late based on check-in time
 */
export const isLate = (
  checkIn: string,
  workingHours: WorkingHours = DEFAULT_WORKING_HOURS
): boolean => {
  const checkInTime = parse(checkIn, 'HH:mm', new Date());
  const startTime = parse(workingHours.start, 'HH:mm', new Date());
  const graceTime = new Date(startTime.getTime() + workingHours.graceMinutes * 60000);
  
  return checkInTime > graceTime;
};

/**
 * Calculate if an employee left early
 */
export const isEarlyLeave = (
  checkOut: string,
  workingHours: WorkingHours = DEFAULT_WORKING_HOURS
): boolean => {
  const checkOutTime = parse(checkOut, 'HH:mm', new Date());
  const endTime = parse(workingHours.end, 'HH:mm', new Date());
  
  return checkOutTime < endTime;
};

/**
 * Calculate overtime hours
 */
export const calculateOvertime = (
  checkIn: string,
  checkOut: string,
  workingHours: WorkingHours = DEFAULT_WORKING_HOURS
): number => {
  const checkOutTime = parse(checkOut, 'HH:mm', new Date());
  const endTime = parse(workingHours.end, 'HH:mm', new Date());
  
  if (checkOutTime <= endTime) return 0;
  
  const overtimeMinutes = differenceInMinutes(checkOutTime, endTime);
  const overtimeHours = Math.min(overtimeMinutes / 60, workingHours.maxOvertime);
  
  return Math.max(0, overtimeHours);
};

/**
 * Calculate total working hours
 */
export const calculateWorkingHours = (
  checkIn: string,
  checkOut: string
): number => {
  const checkInTime = parse(checkIn, 'HH:mm', new Date());
  const checkOutTime = parse(checkOut, 'HH:mm', new Date());
  
  const minutes = differenceInMinutes(checkOutTime, checkInTime);
  return minutes / 60;
};

/**
 * Determine attendance status
 */
export const determineAttendanceStatus = (
  checkIn: string,
  checkOut: string | null,
  workingHours: WorkingHours = DEFAULT_WORKING_HOURS
): AttendanceRecord['status'] => {
  if (!checkIn) return 'absent';
  if (isLate(checkIn, workingHours)) return 'late';
  if (checkOut && isEarlyLeave(checkOut, workingHours)) return 'early_leave';
  return 'present';
};

/**
 * Calculate monthly attendance summary
 */
export const calculateMonthlySummary = (
  records: AttendanceRecord[],
  month: Date
): AttendanceSummary => {
  const monthStart = startOfMonth(month);
  const monthEnd = endOfMonth(month);
  
  const monthRecords = records.filter(record => {
    const recordDate = new Date(record.date);
    return isWithinInterval(recordDate, { start: monthStart, end: monthEnd });
  });
  
  const totalDays = monthRecords.length;
  const presentDays = monthRecords.filter(r => r.status === 'present').length;
  const absentDays = monthRecords.filter(r => r.status === 'absent').length;
  const lateDays = monthRecords.filter(r => r.status === 'late').length;
  const earlyLeaveDays = monthRecords.filter(r => r.status === 'early_leave').length;
  const leaveDays = monthRecords.filter(r => r.status === 'on_leave').length;
  
  const totalOvertime = monthRecords.reduce((sum, record) => sum + record.overtime, 0);
  
  // Calculate average check-in/out times
  const checkInTimes = monthRecords
    .filter(r => r.checkIn)
    .map(r => parse(r.checkIn, 'HH:mm', new Date()));
  
  const checkOutTimes = monthRecords
    .filter(r => r.checkOut)
    .map(r => parse(r.checkOut!, 'HH:mm', new Date()));
  
  const averageCheckIn = checkInTimes.length
    ? format(
        new Date(
          checkInTimes.reduce((sum, time) => sum + time.getTime(), 0) / checkInTimes.length
        ),
        'HH:mm'
      )
    : '--:--';
  
  const averageCheckOut = checkOutTimes.length
    ? format(
        new Date(
          checkOutTimes.reduce((sum, time) => sum + time.getTime(), 0) / checkOutTimes.length
        ),
        'HH:mm'
      )
    : '--:--';
  
  const attendanceRate = (presentDays / totalDays) * 100;
  
  return {
    totalDays,
    presentDays,
    absentDays,
    lateDays,
    earlyLeaveDays,
    leaveDays,
    totalOvertime,
    averageCheckIn,
    averageCheckOut,
    attendanceRate,
  };
};

/**
 * Format attendance status for display
 */
export const formatAttendanceStatus = (status: AttendanceRecord['status']): string => {
  const statusMap: Record<AttendanceRecord['status'], string> = {
    present: 'حاضر',
    absent: 'غائب',
    late: 'متأخر',
    early_leave: 'انصراف مبكر',
    on_leave: 'إجازة',
  };
  
  return statusMap[status] || status;
};

/**
 * Get status color for display
 */
export const getStatusColor = (status: AttendanceRecord['status']): string => {
  const colorMap: Record<AttendanceRecord['status'], string> = {
    present: 'success',
    absent: 'error',
    late: 'warning',
    early_leave: 'warning',
    on_leave: 'info',
  };
  
  return colorMap[status] || 'default';
};

/**
 * Format attendance time for display
 */
export const formatAttendanceTime = (time: string | null): string => {
  if (!time) return '--:--';
  return format(parse(time, 'HH:mm', new Date()), 'hh:mm a', { locale: ar });
};

/**
 * Calculate department attendance statistics
 */
export const calculateDepartmentAttendance = (
  records: AttendanceRecord[],
  employees: Employee[],
  department: string
): {
  totalEmployees: number;
  presentToday: number;
  absentToday: number;
  lateToday: number;
  onLeaveToday: number;
  attendanceRate: number;
} => {
  const departmentEmployees = employees.filter(emp => emp.department === department);
  const today = format(new Date(), 'yyyy-MM-dd');
  const todayRecords = records.filter(
    record => record.date === today && 
    departmentEmployees.some(emp => emp.id === record.employeeId)
  );
  
  const presentToday = todayRecords.filter(r => r.status === 'present').length;
  const absentToday = todayRecords.filter(r => r.status === 'absent').length;
  const lateToday = todayRecords.filter(r => r.status === 'late').length;
  const onLeaveToday = todayRecords.filter(r => r.status === 'on_leave').length;
  
  return {
    totalEmployees: departmentEmployees.length,
    presentToday,
    absentToday,
    lateToday,
    onLeaveToday,
    attendanceRate: (presentToday / departmentEmployees.length) * 100,
  };
};

/**
 * Generate attendance report data
 */
export const generateAttendanceReport = (
  records: AttendanceRecord[],
  employee: Employee,
  startDate: Date,
  endDate: Date
): {
  records: AttendanceRecord[];
  summary: AttendanceSummary;
  workingHoursCompliance: number;
  punctualityRate: number;
} => {
  const employeeRecords = records.filter(
    record => 
      record.employeeId === employee.id &&
      isWithinInterval(new Date(record.date), { start: startDate, end: endDate })
  );
  
  const summary = calculateMonthlySummary(employeeRecords, startDate);
  
  const workingHoursCompliance = employeeRecords.reduce((sum, record) => {
    if (!record.checkOut) return sum;
    const hours = calculateWorkingHours(record.checkIn, record.checkOut);
    return sum + (hours >= DEFAULT_WORKING_HOURS.minHours ? 1 : 0);
  }, 0) / employeeRecords.length * 100;
  
  const punctualityRate = (
    (employeeRecords.length - summary.lateDays - summary.earlyLeaveDays) /
    employeeRecords.length
  ) * 100;
  
  return {
    records: employeeRecords,
    summary,
    workingHoursCompliance,
    punctualityRate,
  };
};
