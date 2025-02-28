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
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  IconButton,
  Chip,
  Toolbar,
} from '@mui/material';
import {
  Edit as EditIcon,
  Check as CheckIcon,
  Close as CloseIcon,
  Today as TodayIcon,
} from '@mui/icons-material';
import type { Employee, Attendance } from '../types';

interface AttendanceManagementProps {
  employees: Employee[];
  onRecordAttendance: (record: Omit<Attendance, 'id'>) => void;
  onUpdateAttendance: (id: string, data: Partial<Attendance>) => void;
}

const AttendanceManagement: React.FC<AttendanceManagementProps> = ({
  employees,
  onRecordAttendance,
  onUpdateAttendance,
}) => {
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedEmployee, setSelectedEmployee] = useState<string>('');
  const [checkInTime, setCheckInTime] = useState('');
  const [checkOutTime, setCheckOutTime] = useState<string>('');
  const [status, setStatus] = useState<Attendance['status']>('present');
  const [overtimeHours, setOvertimeHours] = useState(0);
  const [notes, setNotes] = useState<string | null>('');

  // Mock attendance records - in real app, this would come from props or context
  const [attendanceRecords, setAttendanceRecords] = useState<Attendance[]>([]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedDate || !selectedEmployee || !checkInTime) return;

    const newRecord: Omit<Attendance, 'id'> = {
      employeeId: selectedEmployee,
      date: selectedDate,
      checkIn: checkInTime,
      checkOut: checkOutTime || null,
      status,
      overtimeHours,
      notes: notes || null
    };

    onRecordAttendance(newRecord);
    
    // Reset form
    setSelectedEmployee('');
    setCheckInTime('');
    setCheckOutTime('');
    setStatus('present');
    setOvertimeHours(0);
    setNotes('');
  };

  const getStatusColor = (status: Attendance['status']) => {
    switch (status) {
      case 'present':
        return 'success';
      case 'absent':
        return 'error';
      case 'late':
        return 'warning';
      case 'early_leave':
        return 'info';
      default:
        return 'default';
    }
  };

  const getStatusText = (status: Attendance['status']) => {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      case 'early_leave':
        return 'مغادرة مبكرة';
      default:
        return status;
    }
  };

  return (
    <Box>
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          تسجيل الحضور والانصراف
        </Typography>

        <Grid container spacing={3} component="form" onSubmit={handleSubmit}>
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>الموظف</InputLabel>
              <Select
                value={selectedEmployee}
                label="الموظف"
                onChange={(e) => setSelectedEmployee(e.target.value)}
                required
              >
                {employees.map((emp) => (
                  <MenuItem key={emp.id} value={emp.id}>
                    {emp.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <TextField
              fullWidth
              type="date"
              label="التاريخ"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <TextField
              fullWidth
              type="time"
              label="وقت الحضور"
              value={checkInTime}
              onChange={(e) => setCheckInTime(e.target.value)}
              InputLabelProps={{ shrink: true }}
              required
            />
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <TextField
              fullWidth
              type="time"
              label="وقت الانصراف"
              value={checkOutTime}
              onChange={(e) => setCheckOutTime(e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <FormControl fullWidth>
              <InputLabel>الحالة</InputLabel>
              <Select
                value={status}
                label="الحالة"
                onChange={(e) => setStatus(e.target.value as Attendance['status'])}
                required
              >
                <MenuItem value="present">حاضر</MenuItem>
                <MenuItem value="absent">غائب</MenuItem>
                <MenuItem value="late">متأخر</MenuItem>
                <MenuItem value="early_leave">مغادرة مبكرة</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6} md={2}>
            <TextField
              fullWidth
              type="number"
              label="ساعات إضافية"
              value={overtimeHours}
              onChange={(e) => setOvertimeHours(Number(e.target.value))}
              InputProps={{ inputProps: { min: 0, step: 0.5 } }}
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="ملاحظات"
              value={notes || ''}
              onChange={(e) => setNotes(e.target.value || null)}
              multiline
              rows={2}
            />
          </Grid>

          <Grid item xs={12}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                type="submit"
                variant="contained"
                startIcon={<CheckIcon />}
              >
                تسجيل الحضور
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      <TableContainer component={Paper}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            سجل الحضور اليومي
          </Typography>
          <TextField
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            sx={{ width: 200 }}
            InputLabelProps={{ shrink: true }}
          />
        </Toolbar>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>الموظف</TableCell>
              <TableCell>التاريخ</TableCell>
              <TableCell>وقت الحضور</TableCell>
              <TableCell>وقت الانصراف</TableCell>
              <TableCell>الحالة</TableCell>
              <TableCell>الساعات الإضافية</TableCell>
              <TableCell>ملاحظات</TableCell>
              <TableCell>الإجراءات</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {attendanceRecords
              .filter(record => record.date === selectedDate)
              .map((record) => {
                const employee = employees.find(emp => emp.id === record.employeeId);
                return (
                  <TableRow key={record.id}>
                    <TableCell>{employee?.name}</TableCell>
                    <TableCell>{record.date}</TableCell>
                    <TableCell>{record.checkIn}</TableCell>
                    <TableCell>{record.checkOut || '-'}</TableCell>
                    <TableCell>
                      <Chip
                        label={getStatusText(record.status)}
                        color={getStatusColor(record.status)}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{record.overtimeHours}</TableCell>
                    <TableCell>{record.notes || '-'}</TableCell>
                    <TableCell>
                      <IconButton
                        onClick={() => {/* Handle edit */}}
                        size="small"
                      >
                        <EditIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                );
              })}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default AttendanceManagement;
