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
  IconButton,
  Typography,
  TextField,
  InputAdornment,
  Toolbar,
  Button,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import type { Employee, EmployeeListProps } from '../types';

const EmployeeList: React.FC<EmployeeListProps> = ({ employees, onUpdateEmployee }) => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredEmployees = employees.filter(employee =>
    employee.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    employee.position.toLowerCase().includes(searchTerm.toLowerCase()) ||
    employee.department.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleEdit = (employee: Employee) => {
    // For now, just update the status as an example
    onUpdateEmployee(employee.id, { status: 'inactive' });
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between' }}>
        <Typography variant="h6" component="div">
          قائمة الموظفين
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => console.log('Add new employee')}
        >
          إضافة موظف
        </Button>
      </Toolbar>

      <TextField
        fullWidth
        margin="normal"
        variant="outlined"
        placeholder="بحث عن موظف..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon />
            </InputAdornment>
          ),
        }}
      />

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>الاسم</TableCell>
              <TableCell>المنصب</TableCell>
              <TableCell>القسم</TableCell>
              <TableCell>الراتب الأساسي</TableCell>
              <TableCell>الحالة</TableCell>
              <TableCell>الإجراءات</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredEmployees.map((employee) => (
              <TableRow key={employee.id}>
                <TableCell>{employee.name}</TableCell>
                <TableCell>{employee.position}</TableCell>
                <TableCell>{employee.department}</TableCell>
                <TableCell>{employee.basicSalary}</TableCell>
                <TableCell>{employee.status}</TableCell>
                <TableCell>
                  <IconButton onClick={() => handleEdit(employee)}>
                    <EditIcon />
                  </IconButton>
                  <IconButton onClick={() => console.log('Delete', employee.id)}>
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default EmployeeList;
