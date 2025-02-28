import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Chip,
  Toolbar,
} from '@mui/material';
import {
  Download as DownloadIcon,
  Print as PrintIcon,
  Email as EmailIcon,
} from '@mui/icons-material';
import type { Employee } from '../types';

interface DailyReportProps {
  employees: Employee[];
  date?: string;
}

interface AttendanceSummary {
  total: number;
  present: number;
  absent: number;
  late: number;
  onLeave: number;
}

interface PayrollSummary {
  totalSalaries: number;
  totalOvertime: number;
  totalDeductions: number;
  netPayable: number;
}

interface DepartmentSummary {
  name: string;
  employeeCount: number;
  presentCount: number;
  absentCount: number;
}

const DailyReport: React.FC<DailyReportProps> = ({
  employees,
  date = new Date().toISOString().split('T')[0],
}) => {
  const [selectedDate, setSelectedDate] = useState(date);
  const [selectedDepartment, setSelectedDepartment] = useState<string>('all');

  // Mock data - in real app, this would be calculated from actual data
  const attendanceSummary: AttendanceSummary = {
    total: employees.length,
    present: Math.floor(employees.length * 0.8),
    absent: Math.floor(employees.length * 0.1),
    late: Math.floor(employees.length * 0.05),
    onLeave: Math.floor(employees.length * 0.05),
  };

  const payrollSummary: PayrollSummary = {
    totalSalaries: employees.reduce((sum, emp) => sum + emp.basicSalary, 0),
    totalOvertime: 2500,
    totalDeductions: 1500,
    netPayable: employees.reduce((sum, emp) => sum + emp.basicSalary, 0) + 2500 - 1500,
  };

  const departmentSummary: DepartmentSummary[] = [
    {
      name: 'المبيعات',
      employeeCount: 5,
      presentCount: 4,
      absentCount: 1,
    },
    // Add more departments as needed
  ];

  const handleExport = (format: 'pdf' | 'excel' | 'email') => {
    console.log(`Exporting report as ${format}`);
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">
          التقرير اليومي
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<DownloadIcon />}
            onClick={() => handleExport('pdf')}
          >
            PDF
          </Button>
          <Button
            variant="outlined"
            startIcon={<DownloadIcon />}
            onClick={() => handleExport('excel')}
          >
            Excel
          </Button>
          <Button
            variant="outlined"
            startIcon={<EmailIcon />}
            onClick={() => handleExport('email')}
          >
            إرسال بالبريد
          </Button>
          <Button
            variant="outlined"
            startIcon={<PrintIcon />}
            onClick={() => window.print()}
          >
            طباعة
          </Button>
        </Box>
      </Toolbar>

      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6}>
          <FormControl fullWidth>
            <InputLabel>التاريخ</InputLabel>
            <Select
              value={selectedDate}
              label="التاريخ"
              onChange={(e) => setSelectedDate(e.target.value)}
            >
              <MenuItem value={date}>{new Date(date).toLocaleDateString('ar-EG')}</MenuItem>
            </Select>
          </FormControl>
        </Grid>
        <Grid item xs={12} sm={6}>
          <FormControl fullWidth>
            <InputLabel>القسم</InputLabel>
            <Select
              value={selectedDepartment}
              label="القسم"
              onChange={(e) => setSelectedDepartment(e.target.value)}
            >
              <MenuItem value="all">جميع الأقسام</MenuItem>
              <MenuItem value="sales">المبيعات</MenuItem>
              <MenuItem value="hr">الموارد البشرية</MenuItem>
            </Select>
          </FormControl>
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        {/* Attendance Summary */}
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              ملخص الحضور
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6} sm={2.4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">إجمالي الموظفين</Typography>
                  <Typography variant="h4">{attendanceSummary.total}</Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={2.4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">الحاضرون</Typography>
                  <Typography variant="h4" color="success.main">
                    {attendanceSummary.present}
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={2.4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">الغائبون</Typography>
                  <Typography variant="h4" color="error.main">
                    {attendanceSummary.absent}
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={2.4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">المتأخرون</Typography>
                  <Typography variant="h4" color="warning.main">
                    {attendanceSummary.late}
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={2.4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">في إجازة</Typography>
                  <Typography variant="h4" color="info.main">
                    {attendanceSummary.onLeave}
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Payroll Summary */}
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              ملخص الرواتب
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6} sm={3}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">إجمالي الرواتب</Typography>
                  <Typography variant="h6">
                    {payrollSummary.totalSalaries.toLocaleString()} ج.م
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">العمل الإضافي</Typography>
                  <Typography variant="h6">
                    {payrollSummary.totalOvertime.toLocaleString()} ج.م
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">الخصومات</Typography>
                  <Typography variant="h6">
                    {payrollSummary.totalDeductions.toLocaleString()} ج.م
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="subtitle2">صافي المستحق</Typography>
                  <Typography variant="h6">
                    {payrollSummary.netPayable.toLocaleString()} ج.م
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Department Summary */}
        <Grid item xs={12}>
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>القسم</TableCell>
                  <TableCell>عدد الموظفين</TableCell>
                  <TableCell>الحاضرون</TableCell>
                  <TableCell>الغائبون</TableCell>
                  <TableCell>نسبة الحضور</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {departmentSummary.map((dept) => (
                  <TableRow key={dept.name}>
                    <TableCell>{dept.name}</TableCell>
                    <TableCell>{dept.employeeCount}</TableCell>
                    <TableCell>{dept.presentCount}</TableCell>
                    <TableCell>{dept.absentCount}</TableCell>
                    <TableCell>
                      <Chip
                        label={`${((dept.presentCount / dept.employeeCount) * 100).toFixed(1)}%`}
                        color={dept.presentCount / dept.employeeCount > 0.8 ? 'success' : 'warning'}
                        size="small"
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DailyReport;
