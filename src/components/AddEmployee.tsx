import React from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Divider,
} from '@mui/material';
import type { Employee } from '../types';

interface AddEmployeeProps {
  onAddEmployee: (employee: Omit<Employee, 'id'>) => void;
  departments: string[];
}

const AddEmployee: React.FC<AddEmployeeProps> = ({ onAddEmployee, departments }) => {
  const [formData, setFormData] = React.useState({
    name: '',
    position: '',
    department: '',
    basicSalary: 0,
    monthlyIncentives: 0,
    absenceDays: 0,
    penalties: 0,
    advances: 0,
    joinDate: '',
    status: 'active' as const,
    nationalId: '',
    phoneNumber: '',
    email: '',
    address: '',
    bankAccount: '',
    bankName: '',
    insuranceNumber: '',
    emergencyContact: {
      name: '',
      relation: '',
      phone: '',
    },
  });

  const handleChange = (field: string, value: string | number) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleEmergencyContactChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      emergencyContact: {
        ...prev.emergencyContact,
        [field]: value,
      },
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onAddEmployee(formData);
  };

  return (
    <Box component="form" onSubmit={handleSubmit}>
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          إضافة موظف جديد
        </Typography>

        <Grid container spacing={3}>
          {/* Basic Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" gutterBottom>
              المعلومات الأساسية
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="الاسم"
              value={formData.name}
              onChange={(e) => handleChange('name', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="المنصب"
              value={formData.position}
              onChange={(e) => handleChange('position', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <FormControl fullWidth required>
              <InputLabel>القسم</InputLabel>
              <Select
                value={formData.department}
                label="القسم"
                onChange={(e) => handleChange('department', e.target.value)}
              >
                {departments.map((dept) => (
                  <MenuItem key={dept} value={dept}>
                    {dept}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              type="date"
              label="تاريخ التعيين"
              value={formData.joinDate}
              onChange={(e) => handleChange('joinDate', e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
          </Grid>

          {/* Financial Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" gutterBottom>
              المعلومات المالية
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              type="number"
              label="الراتب الأساسي"
              value={formData.basicSalary}
              onChange={(e) => handleChange('basicSalary', Number(e.target.value))}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              type="number"
              label="الحوافز الشهرية"
              value={formData.monthlyIncentives}
              onChange={(e) => handleChange('monthlyIncentives', Number(e.target.value))}
            />
          </Grid>

          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
          </Grid>

          {/* Contact Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" gutterBottom>
              معلومات الاتصال
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="الرقم القومي"
              value={formData.nationalId}
              onChange={(e) => handleChange('nationalId', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="رقم الهاتف"
              value={formData.phoneNumber}
              onChange={(e) => handleChange('phoneNumber', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="البريد الإلكتروني"
              type="email"
              value={formData.email}
              onChange={(e) => handleChange('email', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="العنوان"
              value={formData.address}
              onChange={(e) => handleChange('address', e.target.value)}
            />
          </Grid>

          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
          </Grid>

          {/* Bank Information */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" gutterBottom>
              المعلومات البنكية
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="رقم الحساب البنكي"
              value={formData.bankAccount}
              onChange={(e) => handleChange('bankAccount', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="اسم البنك"
              value={formData.bankName}
              onChange={(e) => handleChange('bankName', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              label="رقم التأمين"
              value={formData.insuranceNumber}
              onChange={(e) => handleChange('insuranceNumber', e.target.value)}
            />
          </Grid>

          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
          </Grid>

          {/* Emergency Contact */}
          <Grid item xs={12}>
            <Typography variant="subtitle1" gutterBottom>
              جهة الاتصال في حالات الطوارئ
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="الاسم"
              value={formData.emergencyContact.name}
              onChange={(e) => handleEmergencyContactChange('name', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="صلة القرابة"
              value={formData.emergencyContact.relation}
              onChange={(e) => handleEmergencyContactChange('relation', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              required
              label="رقم الهاتف"
              value={formData.emergencyContact.phone}
              onChange={(e) => handleEmergencyContactChange('phone', e.target.value)}
            />
          </Grid>

          <Grid item xs={12}>
            <Box sx={{ mt: 3, display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                type="submit"
                variant="contained"
                size="large"
              >
                إضافة الموظف
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>
    </Box>
  );
};

export default AddEmployee;
