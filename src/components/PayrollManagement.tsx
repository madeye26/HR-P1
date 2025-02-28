import React, { useState } from 'react';
import {
  Box,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  Typography,
  Toolbar,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
} from '@mui/material';
import type { Employee, PayrollRecord } from '../types';

interface PayrollManagementProps {
  employees: Employee[];
  onProcessPayroll: (payroll: PayrollRecord[]) => void;
}

const PayrollManagement: React.FC<PayrollManagementProps> = ({
  employees,
  onProcessPayroll,
}) => {
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  const calculatePayroll = () => {
    const payrollRecords: PayrollRecord[] = employees.map(employee => ({
      id: `PR${Date.now()}${employee.id}`,
      employeeId: employee.id,
      month: selectedMonth,
      year: selectedYear,
      basicSalary: employee.basicSalary,
      incentives: employee.monthlyIncentives,
      deductions: (employee.absenceDays * (employee.basicSalary / 30)) + employee.penalties + employee.advances,
      netSalary: employee.basicSalary + employee.monthlyIncentives - 
        ((employee.absenceDays * (employee.basicSalary / 30)) + employee.penalties + employee.advances),
      status: 'pending',
      processedAt: undefined,
      paidAt: undefined
    }));

    onProcessPayroll(payrollRecords);
  };

  const months = [
    { value: 1, label: 'يناير' },
    { value: 2, label: 'فبراير' },
    { value: 3, label: 'مارس' },
    { value: 4, label: 'أبريل' },
    { value: 5, label: 'مايو' },
    { value: 6, label: 'يونيو' },
    { value: 7, label: 'يوليو' },
    { value: 8, label: 'أغسطس' },
    { value: 9, label: 'سبتمبر' },
    { value: 10, label: 'أكتوبر' },
    { value: 11, label: 'نوفمبر' },
    { value: 12, label: 'ديسمبر' },
  ];

  const years = Array.from({ length: 5 }, (_, i) => selectedYear - 2 + i);

  const totalBasicSalary = employees.reduce((sum, emp) => sum + emp.basicSalary, 0);
  const totalIncentives = employees.reduce((sum, emp) => sum + emp.monthlyIncentives, 0);
  const totalDeductions = employees.reduce((sum, emp) => 
    sum + ((emp.absenceDays * (emp.basicSalary / 30)) + emp.penalties + emp.advances), 0);
  const totalNetSalary = totalBasicSalary + totalIncentives - totalDeductions;

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6" component="div">
          إدارة الرواتب
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>الشهر</InputLabel>
            <Select
              value={selectedMonth}
              label="الشهر"
              onChange={(e) => setSelectedMonth(e.target.value as number)}
            >
              {months.map(month => (
                <MenuItem key={month.value} value={month.value}>
                  {month.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>السنة</InputLabel>
            <Select
              value={selectedYear}
              label="السنة"
              onChange={(e) => setSelectedYear(e.target.value as number)}
            >
              {years.map(year => (
                <MenuItem key={year} value={year}>
                  {year}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <Button
            variant="contained"
            onClick={calculatePayroll}
          >
            معالجة الرواتب
          </Button>
        </Box>
      </Toolbar>

      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الرواتب الأساسية</Typography>
            <Typography variant="h6">{totalBasicSalary.toFixed(2)} ج.م</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الحوافز</Typography>
            <Typography variant="h6">{totalIncentives.toFixed(2)} ج.م</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الخصومات</Typography>
            <Typography variant="h6">{totalDeductions.toFixed(2)} ج.م</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي صافي الرواتب</Typography>
            <Typography variant="h6">{totalNetSalary.toFixed(2)} ج.م</Typography>
          </Paper>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>الموظف</TableCell>
              <TableCell>الراتب الأساسي</TableCell>
              <TableCell>الحوافز</TableCell>
              <TableCell>أيام الغياب</TableCell>
              <TableCell>الخصومات</TableCell>
              <TableCell>السلف</TableCell>
              <TableCell>صافي الراتب</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {employees.map((employee) => {
              const deductions = (employee.absenceDays * (employee.basicSalary / 30)) + 
                employee.penalties + employee.advances;
              const netSalary = employee.basicSalary + employee.monthlyIncentives - deductions;

              return (
                <TableRow key={employee.id}>
                  <TableCell>{employee.name}</TableCell>
                  <TableCell>{employee.basicSalary.toFixed(2)}</TableCell>
                  <TableCell>{employee.monthlyIncentives.toFixed(2)}</TableCell>
                  <TableCell>{employee.absenceDays}</TableCell>
                  <TableCell>{deductions.toFixed(2)}</TableCell>
                  <TableCell>{employee.advances.toFixed(2)}</TableCell>
                  <TableCell>{netSalary.toFixed(2)}</TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default PayrollManagement;
