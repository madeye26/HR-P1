import React, { useState, useMemo } from 'react';
import {
  Box,
  Paper,
  TextField,
  InputAdornment,
  IconButton,
  Chip,
  Stack,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  SelectChangeEvent,
} from '@mui/material';
import {
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
} from '@mui/icons-material';
import { 
  DataGrid, 
  GridColDef, 
  GridToolbar,
  GridPaginationModel,
  GridRenderCellParams,
  GridValueFormatter,
  GridValueGetter
} from '@mui/x-data-grid';
import { useEmployee } from '../context/EmployeeContext';
import { formatCurrency } from '../utils/dashboardUtils';
import { Employee } from '../types';

const EmployeeListNew: React.FC = () => {
  const { state } = useEmployee();
  const [searchText, setSearchText] = useState('');
  const [departmentFilter, setDepartmentFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    pageSize: 10,
    page: 0,
  });

  const departments = useMemo(() => {
    const depts = new Set(state.employees.map(emp => emp.department));
    return Array.from(depts);
  }, [state.employees]);

  const filteredEmployees = useMemo(() => {
    return state.employees.filter(employee => {
      const matchesSearch = searchText === '' ||
        employee.name.toLowerCase().includes(searchText.toLowerCase()) ||
        employee.code.toLowerCase().includes(searchText.toLowerCase()) ||
        employee.position.title.toLowerCase().includes(searchText.toLowerCase());

      const matchesDepartment = departmentFilter === 'all' || employee.department === departmentFilter;
      const matchesStatus = statusFilter === 'all' || employee.status === statusFilter;

      return matchesSearch && matchesDepartment && matchesStatus;
    });
  }, [state.employees, searchText, departmentFilter, statusFilter]);

  const columns: GridColDef<Employee>[] = [
    { field: 'code', headerName: 'كود الموظف', width: 130 },
    { field: 'name', headerName: 'اسم الموظف', width: 200 },
    {
      field: 'position',
      headerName: 'المسمى الوظيفي',
      width: 180,
      valueGetter: ({ row }: { row: Employee }) => row.position.title,
    },
    { field: 'department', headerName: 'القسم', width: 150 },
    {
      field: 'basicSalary',
      headerName: 'الراتب الأساسي',
      width: 150,
      valueFormatter: ({ value }: { value: number }) => formatCurrency(value),
    },
    {
      field: 'status',
      headerName: 'الحالة',
      width: 130,
      renderCell: (params: GridRenderCellParams<Employee>) => (
        <Chip
          label={params.value === 'active' ? 'نشط' : params.value === 'inactive' ? 'غير نشط' : 'في إجازة'}
          color={params.value === 'active' ? 'success' : params.value === 'inactive' ? 'error' : 'warning'}
          size="small"
        />
      ),
    },
    {
      field: 'joinDate',
      headerName: 'تاريخ التعيين',
      width: 150,
      valueFormatter: ({ value }: { value: string }) => new Date(value).toLocaleDateString('ar-EG'),
    },
  ];

  const handleDepartmentChange = (event: SelectChangeEvent) => {
    setDepartmentFilter(event.target.value);
  };

  const handleStatusChange = (event: SelectChangeEvent) => {
    setStatusFilter(event.target.value);
  };

  const handleClearFilters = () => {
    setSearchText('');
    setDepartmentFilter('all');
    setStatusFilter('all');
  };

  return (
    <Box sx={{ height: '100%', width: '100%', p: 3 }}>
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" sx={{ mb: 2 }}>
          <TextField
            label="بحث"
            variant="outlined"
            size="small"
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            sx={{ minWidth: 200 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
              endAdornment: searchText && (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={() => setSearchText('')}>
                    <ClearIcon />
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />

          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>القسم</InputLabel>
            <Select
              value={departmentFilter}
              label="القسم"
              onChange={handleDepartmentChange}
            >
              <MenuItem value="all">جميع الأقسام</MenuItem>
              {departments.map((dept) => (
                <MenuItem key={dept} value={dept}>{dept}</MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>الحالة</InputLabel>
            <Select
              value={statusFilter}
              label="الحالة"
              onChange={handleStatusChange}
            >
              <MenuItem value="all">جميع الحالات</MenuItem>
              <MenuItem value="active">نشط</MenuItem>
              <MenuItem value="inactive">غير نشط</MenuItem>
              <MenuItem value="on_leave">في إجازة</MenuItem>
            </Select>
          </FormControl>

          <IconButton onClick={handleClearFilters} size="small">
            <FilterIcon />
          </IconButton>
        </Stack>

        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
          {filteredEmployees.length} موظف
        </Typography>
      </Paper>

      <DataGrid
        rows={filteredEmployees}
        columns={columns}
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50]}
        checkboxSelection
        disableRowSelectionOnClick
        autoHeight
        slots={{
          toolbar: GridToolbar,
        }}
        slotProps={{
          toolbar: {
            showQuickFilter: true,
            quickFilterProps: { debounceMs: 500 },
          },
        }}
        sx={{
          '& .MuiDataGrid-toolbarContainer': {
            direction: 'rtl',
          },
        }}
      />
    </Box>
  );
};

export default EmployeeListNew;
