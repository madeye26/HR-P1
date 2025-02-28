import React from 'react';
import {
  Box,
  Grid,
  Paper,
  Typography,
  useTheme,
  Card,
  CardContent,
} from '@mui/material';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import { useEmployee } from '../context/EmployeeContext';
import {
  calculateAttendanceStats,
  calculatePayrollStats,
  calculateDepartmentStats,
  formatCurrency,
} from '../utils/dashboardUtils';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

const Dashboard: React.FC = () => {
  const { state } = useEmployee();
  const theme = useTheme();

  const attendanceStats = calculateAttendanceStats(state.employees, state.attendanceRecords);
  const payrollStats = calculatePayrollStats(state.employees);
  const departmentStats = calculateDepartmentStats(state.employees);

  const totalEmployees = state.employees.length;
  const activeEmployees = state.employees.filter(emp => emp.status === 'active').length;
  const totalSalaries = state.employees.reduce((sum, emp) => sum + emp.basicSalary + emp.monthlyIncentives, 0);

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                إجمالي الموظفين
              </Typography>
              <Typography variant="h4">{totalEmployees}</Typography>
              <Typography variant="body2" color="textSecondary">
                {activeEmployees} موظف نشط
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                إجمالي الرواتب الشهرية
              </Typography>
              <Typography variant="h4">
                {formatCurrency(totalSalaries)}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                متوسط {formatCurrency(totalSalaries / totalEmployees)} للموظف
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                معدل الحضور اليوم
              </Typography>
              <Typography variant="h4">
                {Math.round((attendanceStats[attendanceStats.length - 1]?.present || 0) / totalEmployees * 100)}%
              </Typography>
              <Typography variant="body2" color="textSecondary">
                {attendanceStats[attendanceStats.length - 1]?.present || 0} موظف حاضر
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3}>
        {/* Attendance Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              إحصائيات الحضور
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={attendanceStats}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="present" name="حاضر" stroke="#8884d8" />
                <Line type="monotone" dataKey="absent" name="غائب" stroke="#ff7043" />
                <Line type="monotone" dataKey="late" name="متأخر" stroke="#ffa726" />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Payroll Chart */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              إحصائيات الرواتب
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={payrollStats}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="salaries" name="الرواتب" fill="#8884d8" />
                <Bar dataKey="advances" name="السلف" fill="#82ca9d" />
                <Bar dataKey="deductions" name="الخصومات" fill="#ff7043" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Department Distribution */}
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              توزيع الموظفين حسب الأقسام
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={departmentStats}
                  dataKey="employeeCount"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label
                >
                  {departmentStats.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
