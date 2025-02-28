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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Toolbar,
} from '@mui/material';
import type { Employee } from '../types';

interface LeaveRequest {
  id: string;
  employeeId: string;
  type: 'annual' | 'sick' | 'emergency' | 'unpaid';
  startDate: string;
  endDate: string;
  days: number;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  approvedBy?: string;
  approvedAt?: string;
  attachments?: string[];
  createdAt: string;
  updatedAt: string;
}

interface LeaveManagementProps {
  employees: Employee[];
  onRequestLeave: (request: Omit<LeaveRequest, 'id' | 'status' | 'createdAt' | 'updatedAt'>) => void;
  onApproveLeave: (id: string, approved: boolean, approverComment?: string) => void;
}

const LeaveManagement: React.FC<LeaveManagementProps> = ({
  employees,
  onRequestLeave,
  onApproveLeave,
}) => {
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState('');
  const [leaveType, setLeaveType] = useState<LeaveRequest['type']>('annual');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [reason, setReason] = useState('');

  // Mock leave requests - in real app, this would come from props or context
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>([
    {
      id: '1',
      employeeId: '1',
      type: 'annual',
      startDate: '2023-10-01',
      endDate: '2023-10-05',
      days: 5,
      reason: 'إجازة سنوية',
      status: 'pending',
      createdAt: '2023-09-25T00:00:00Z',
      updatedAt: '2023-09-25T00:00:00Z'
    }
  ]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const days = Math.ceil(
      (new Date(endDate).getTime() - new Date(startDate).getTime()) / (1000 * 60 * 60 * 24)
    ) + 1;

    const newRequest = {
      employeeId: selectedEmployee,
      type: leaveType,
      startDate,
      endDate,
      days,
      reason,
    };

    onRequestLeave(newRequest);
    handleCloseDialog();
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setSelectedEmployee('');
    setLeaveType('annual');
    setStartDate('');
    setEndDate('');
    setReason('');
  };

  const getLeaveTypeText = (type: LeaveRequest['type']) => {
    switch (type) {
      case 'annual':
        return 'إجازة سنوية';
      case 'sick':
        return 'إجازة مرضية';
      case 'emergency':
        return 'إجازة طارئة';
      case 'unpaid':
        return 'إجازة بدون راتب';
      default:
        return type;
    }
  };

  const getStatusColor = (status: LeaveRequest['status']) => {
    switch (status) {
      case 'approved':
        return 'success';
      case 'rejected':
        return 'error';
      case 'pending':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getStatusText = (status: LeaveRequest['status']) => {
    switch (status) {
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return status;
    }
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">
          إدارة الإجازات
        </Typography>
        <Button
          variant="contained"
          onClick={() => setOpenDialog(true)}
        >
          طلب إجازة جديد
        </Button>
      </Toolbar>

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الطلبات</Typography>
            <Typography variant="h4">{leaveRequests.length}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">الطلبات المعلقة</Typography>
            <Typography variant="h4">
              {leaveRequests.filter(r => r.status === 'pending').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">الطلبات المقبولة</Typography>
            <Typography variant="h4">
              {leaveRequests.filter(r => r.status === 'approved').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">الطلبات المرفوضة</Typography>
            <Typography variant="h4">
              {leaveRequests.filter(r => r.status === 'rejected').length}
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>الموظف</TableCell>
              <TableCell>نوع الإجازة</TableCell>
              <TableCell>من تاريخ</TableCell>
              <TableCell>إلى تاريخ</TableCell>
              <TableCell>عدد الأيام</TableCell>
              <TableCell>السبب</TableCell>
              <TableCell>الحالة</TableCell>
              <TableCell>الإجراءات</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {leaveRequests.map((request) => {
              const employee = employees.find(emp => emp.id === request.employeeId);
              return (
                <TableRow key={request.id}>
                  <TableCell>{employee?.name}</TableCell>
                  <TableCell>{getLeaveTypeText(request.type)}</TableCell>
                  <TableCell>{request.startDate}</TableCell>
                  <TableCell>{request.endDate}</TableCell>
                  <TableCell>{request.days}</TableCell>
                  <TableCell>{request.reason}</TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusText(request.status)}
                      color={getStatusColor(request.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {request.status === 'pending' && (
                      <>
                        <Button
                          size="small"
                          color="success"
                          onClick={() => onApproveLeave(request.id, true)}
                        >
                          موافقة
                        </Button>
                        <Button
                          size="small"
                          color="error"
                          onClick={() => onApproveLeave(request.id, false)}
                        >
                          رفض
                        </Button>
                      </>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          طلب إجازة جديد
        </DialogTitle>
        <DialogContent>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <FormControl fullWidth required>
                  <InputLabel>الموظف</InputLabel>
                  <Select
                    value={selectedEmployee}
                    label="الموظف"
                    onChange={(e) => setSelectedEmployee(e.target.value)}
                  >
                    {employees.map((emp) => (
                      <MenuItem key={emp.id} value={emp.id}>
                        {emp.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth required>
                  <InputLabel>نوع الإجازة</InputLabel>
                  <Select
                    value={leaveType}
                    label="نوع الإجازة"
                    onChange={(e) => setLeaveType(e.target.value as LeaveRequest['type'])}
                  >
                    <MenuItem value="annual">إجازة سنوية</MenuItem>
                    <MenuItem value="sick">إجازة مرضية</MenuItem>
                    <MenuItem value="emergency">إجازة طارئة</MenuItem>
                    <MenuItem value="unpaid">إجازة بدون راتب</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  required
                  type="date"
                  label="من تاريخ"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  required
                  type="date"
                  label="إلى تاريخ"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  required
                  multiline
                  rows={3}
                  label="سبب الإجازة"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>إلغاء</Button>
          <Button onClick={handleSubmit} variant="contained">
            تقديم الطلب
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default LeaveManagement;
