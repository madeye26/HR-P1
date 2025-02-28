import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  TextField,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Toolbar,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Person as PersonIcon,
} from '@mui/icons-material';

interface Department {
  id: string;
  name: string;
  code: string;
  managerId: string | null;
  budget: {
    annual: number;
    remaining: number;
    year: number;
  };
  employeeCount: number;
  status: 'active' | 'inactive';
  description: string;
  createdAt: string;
  updatedAt: string;
}

interface DepartmentFormData {
  name: string;
  code: string;
  managerId: string;
  budget: number;
  description: string;
}

const DepartmentsManager: React.FC = () => {
  const [departments, setDepartments] = useState<Department[]>([
    {
      id: 'DEPT1',
      name: 'المبيعات',
      code: 'SALES',
      managerId: '1',
      budget: {
        annual: 500000,
        remaining: 350000,
        year: 2023
      },
      employeeCount: 5,
      status: 'active',
      description: 'قسم المبيعات والتسويق',
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z'
    }
  ]);

  const [openDialog, setOpenDialog] = useState(false);
  const [editingDepartment, setEditingDepartment] = useState<Department | null>(null);
  const [formData, setFormData] = useState<DepartmentFormData>({
    name: '',
    code: '',
    managerId: '',
    budget: 0,
    description: ''
  });

  const handleOpenDialog = (department?: Department) => {
    if (department) {
      setEditingDepartment(department);
      setFormData({
        name: department.name,
        code: department.code,
        managerId: department.managerId || '',
        budget: department.budget.annual,
        description: department.description
      });
    } else {
      setEditingDepartment(null);
      setFormData({
        name: '',
        code: '',
        managerId: '',
        budget: 0,
        description: ''
      });
    }
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingDepartment(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingDepartment) {
      // Update existing department
      setDepartments(prev => prev.map(dept => 
        dept.id === editingDepartment.id
          ? {
              ...dept,
              name: formData.name,
              code: formData.code,
              managerId: formData.managerId || null,
              budget: {
                ...dept.budget,
                annual: formData.budget
              },
              description: formData.description,
              updatedAt: new Date().toISOString()
            }
          : dept
      ));
    } else {
      // Add new department
      const newDepartment: Department = {
        id: `DEPT${Date.now()}`,
        name: formData.name,
        code: formData.code,
        managerId: formData.managerId || null,
        budget: {
          annual: formData.budget,
          remaining: formData.budget,
          year: new Date().getFullYear()
        },
        employeeCount: 0,
        status: 'active',
        description: formData.description,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      setDepartments(prev => [...prev, newDepartment]);
    }
    handleCloseDialog();
  };

  const handleDelete = (id: string) => {
    setDepartments(prev => prev.filter(dept => dept.id !== id));
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">
          إدارة الأقسام
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          إضافة قسم جديد
        </Button>
      </Toolbar>

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">عدد الأقسام</Typography>
            <Typography variant="h4">{departments.length}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">الأقسام النشطة</Typography>
            <Typography variant="h4">
              {departments.filter(d => d.status === 'active').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الميزانيات</Typography>
            <Typography variant="h4">
              {departments.reduce((sum, dept) => sum + dept.budget.annual, 0).toLocaleString()} ج.م
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الموظفين</Typography>
            <Typography variant="h4">
              {departments.reduce((sum, dept) => sum + dept.employeeCount, 0)}
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>القسم</TableCell>
              <TableCell>الكود</TableCell>
              <TableCell>عدد الموظفين</TableCell>
              <TableCell>الميزانية السنوية</TableCell>
              <TableCell>الميزانية المتبقية</TableCell>
              <TableCell>الحالة</TableCell>
              <TableCell>الإجراءات</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {departments.map((department) => (
              <TableRow key={department.id}>
                <TableCell>{department.name}</TableCell>
                <TableCell>{department.code}</TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <PersonIcon fontSize="small" />
                    {department.employeeCount}
                  </Box>
                </TableCell>
                <TableCell>{department.budget.annual.toLocaleString()} ج.م</TableCell>
                <TableCell>{department.budget.remaining.toLocaleString()} ج.م</TableCell>
                <TableCell>
                  <Chip
                    label={department.status === 'active' ? 'نشط' : 'غير نشط'}
                    color={department.status === 'active' ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={() => handleOpenDialog(department)}
                  >
                    <EditIcon />
                  </IconButton>
                  <IconButton
                    size="small"
                    onClick={() => handleDelete(department.id)}
                  >
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingDepartment ? 'تعديل القسم' : 'إضافة قسم جديد'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="اسم القسم"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="كود القسم"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="معرف المدير"
                  value={formData.managerId}
                  onChange={(e) => setFormData({ ...formData, managerId: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="الميزانية السنوية"
                  value={formData.budget}
                  onChange={(e) => setFormData({ ...formData, budget: Number(e.target.value) })}
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="الوصف"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>إلغاء</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingDepartment ? 'تحديث' : 'إضافة'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DepartmentsManager;
