import React from 'react';
import {
  Box,
  Grid,
  Paper,
  Typography,
  List,
  ListItem,
  ListItemText,
  Divider,
} from '@mui/material';
import type { Employee } from '../types';

interface DashboardProps {
  // Add any props if needed
}

interface DashboardStats {
  totalEmployees: number;
  activeEmployees: number;
  totalSalaries: number;
  averageSalary: number;
  departmentCounts: Record<string, number>;
}

const calculateStats = (employees: Employee[]): DashboardStats => {
  const activeEmployees = employees.filter(emp => emp.status === 'active');
  const totalSalaries = employees.reduce((sum, emp) => sum + emp.basicSalary, 0);
  
  const departmentCounts = employees.reduce((acc, emp) => {
    acc[emp.department] = (acc[emp.department] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  return {
    totalEmployees: employees.length,
    activeEmployees: activeEmployees.length,
    totalSalaries,
    averageSalary: totalSalaries / employees.length || 0,
    departmentCounts,
  };
};

const Dashboard: React.FC<DashboardProps> = () => {
  // Mock data - in real app, this would come from props or context
  const mockEmployees: Employee[] = [
    {
      id: '1',
      name: 'أحمد محمد',
      position: 'كاشير',
      department: 'المبيعات',
      basicSalary: 3000,
      monthlyIncentives: 500,
      absenceDays: 0,
      penalties: 0,
      advances: 0,
      joinDate: '2023-01-01',
      status: 'active',
      nationalId: '29012345678901',
      phoneNumber: '01012345678',
      email: 'ahmed@example.com',
      address: 'القاهرة، مصر',
      bankAccount: '1234567890',
      bankName: 'البنك الأهلي المصري',
      insuranceNumber: '987654321',
      emergencyContact: {
        name: 'محمد أحمد',
        relation: 'أخ',
        phone: '01098765432'
      }
    }
  ];

  const stats = calculateStats(mockEmployees);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        لوحة التحكم
      </Typography>

      <Grid container spacing={3}>
        {/* Stats Cards */}
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6">إجمالي الموظفين</Typography>
            <Typography variant="h4">{stats.totalEmployees}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6">الموظفين النشطين</Typography>
            <Typography variant="h4">{stats.activeEmployees}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6">إجمالي الرواتب</Typography>
            <Typography variant="h4">{stats.totalSalaries} ج.م</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6">متوسط الراتب</Typography>
            <Typography variant="h4">{stats.averageSalary.toFixed(2)} ج.م</Typography>
          </Paper>
        </Grid>

        {/* Department Distribution */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              توزيع الموظفين حسب القسم
            </Typography>
            <List>
              {Object.entries(stats.departmentCounts).map(([dept, count]) => (
                <React.Fragment key={dept}>
                  <ListItem>
                    <ListItemText
                      primary={dept}
                      secondary={`عدد الموظفين: ${count}`}
                    />
                  </ListItem>
                  <Divider />
                </React.Fragment>
              ))}
            </List>
          </Paper>
        </Grid>

        {/* Recent Activities */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              النشاطات الأخيرة
            </Typography>
            <List>
              <ListItem>
                <ListItemText
                  primary="تم إضافة موظف جديد"
                  secondary="منذ 5 دقائق"
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="تم معالجة الرواتب"
                  secondary="منذ ساعة"
                />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText
                  primary="تحديث بيانات موظف"
                  secondary="منذ ساعتين"
                />
              </ListItem>
            </List>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
