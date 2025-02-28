import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Tooltip,
  Alert,
  SelectChangeEvent,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Payment as PaymentIcon,
  History as HistoryIcon,
} from '@mui/icons-material';
import { useEmployee } from '../context/EmployeeContext';
import type { Employee } from '../types/employee';
import type { Advance, AdvanceInstallment } from '../types/advance';
import { formatCurrency } from '../utils/formatters';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`advance-tabpanel-${index}`}
      aria-labelledby={`advance-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

interface AdvanceFormData {
  employeeId: string;
  amount: number;
  reason: string;
  installments: number;
  notes: string;
}

const initialFormData: AdvanceFormData = {
  employeeId: '',
  amount: 0,
  reason: '',
  installments: 1,
  notes: '',
};

interface Props {
  employees: Employee[];
}

const AdvanceManager = ({ employees }: Props): React.ReactElement => {
  const { state, dispatch } = useEmployee();
  const [tabValue, setTabValue] = useState(0);
  const [openDialog, setOpenDialog] = useState(false);
  const [formData, setFormData] = useState<AdvanceFormData>(initialFormData);
  const [selectedAdvance, setSelectedAdvance] = useState<Advance | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleOpenDialog = () => {
    setOpenDialog(true);
    setError(null);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setFormData(initialFormData);
    setSelectedAdvance(null);
    setError(null);
  };

  const handleSelectChange = (e: SelectChangeEvent<string>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleTextFieldChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'amount' || name === 'installments' ? Number(value) : value,
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.employeeId) {
      setError('يرجى اختيار الموظف');
      return false;
    }
    if (formData.amount <= 0) {
      setError('يجب أن يكون المبلغ أكبر من صفر');
      return false;
    }
    if (formData.installments < 1) {
      setError('يجب أن يكون عدد الأقساط أكبر من صفر');
      return false;
    }
    if (!formData.reason.trim()) {
      setError('يرجى إدخال سبب السلفة');
      return false;
    }
    return true;
  };

  const handleSubmit = () => {
    if (!validateForm()) return;

    const employee = employees.find(emp => emp.id === formData.employeeId);
    if (!employee) {
      setError('لم يتم العثور على الموظف');
      return;
    }

    const advance: Advance = {
      id: Date.now().toString(),
      employeeId: formData.employeeId,
      amount: formData.amount,
      date: new Date().toISOString(),
      reason: formData.reason,
      installments: formData.installments,
      remainingAmount: formData.amount,
      status: 'pending',
      notes: formData.notes,
    };

    // Create installments
    const installmentAmount = Math.ceil(formData.amount / formData.installments);
    const installments: AdvanceInstallment[] = Array.from({ length: formData.installments }, (_, index) => {
      const dueDate = new Date();
      dueDate.setMonth(dueDate.getMonth() + index + 1);
      
      return {
        id: `${advance.id}-${index + 1}`,
        advanceId: advance.id,
        amount: index === formData.installments - 1 ? 
          formData.amount - (installmentAmount * (formData.installments - 1)) : 
          installmentAmount,
        dueDate: dueDate.toISOString(),
        paidAmount: 0,
        status: 'pending',
      };
    });

    dispatch({
      type: 'ADD_ADVANCE',
      payload: { advance, installments }
    });

    // Add notification
    dispatch({
      type: 'ADD_NOTIFICATION',
      payload: {
        id: Date.now().toString(),
        type: 'advance',
        title: 'طلب سلفة جديد',
        message: `تم تقديم طلب سلفة جديد من ${employee.name} بمبلغ ${formatCurrency(formData.amount)}`,
        status: 'unread',
        createdAt: new Date().toISOString(),
        targetId: advance.id,
        targetType: 'advance'
      }
    });

    handleCloseDialog();
  };

  const handleApprove = (advance: Advance) => {
    dispatch({
      type: 'UPDATE_ADVANCE',
      payload: {
        ...advance,
        status: 'approved',
        approvedBy: '1', // TODO: Get from auth context
        approvalDate: new Date().toISOString(),
      }
    });

    // Add notification
    const employee = employees.find(emp => emp.id === advance.employeeId);
    dispatch({
      type: 'ADD_NOTIFICATION',
      payload: {
        id: Date.now().toString(),
        type: 'advance',
        title: 'تمت الموافقة على طلب السلفة',
        message: `تمت الموافقة على طلب سلفة ${employee?.name} بمبلغ ${formatCurrency(advance.amount)}`,
        status: 'unread',
        createdAt: new Date().toISOString(),
        targetId: advance.id,
        targetType: 'advance'
      }
    });
  };

  const handleReject = (advance: Advance) => {
    dispatch({
      type: 'UPDATE_ADVANCE',
      payload: {
        ...advance,
        status: 'rejected',
        approvedBy: '1', // TODO: Get from auth context
        approvalDate: new Date().toISOString(),
      }
    });

    // Add notification
    const employee = employees.find(emp => emp.id === advance.employeeId);
    dispatch({
      type: 'ADD_NOTIFICATION',
      payload: {
        id: Date.now().toString(),
        type: 'advance',
        title: 'تم رفض طلب السلفة',
        message: `تم رفض طلب سلفة ${employee?.name} بمبلغ ${formatCurrency(advance.amount)}`,
        status: 'unread',
        createdAt: new Date().toISOString(),
        targetId: advance.id,
        targetType: 'advance'
      }
    });
  };

  const handleDelete = (advance: Advance) => {
    if (advance.status === 'pending') {
      dispatch({
        type: 'DELETE_ADVANCE',
        payload: advance.id
      });
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Paper sx={{ p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
          <Typography variant="h6">إدارة السلف</Typography>
          <Button
            variant="contained"
            color="primary"
            startIcon={<AddIcon />}
            onClick={handleOpenDialog}
          >
            طلب سلفة جديدة
          </Button>
        </Box>

        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={handleTabChange}>
            <Tab label="السلف النشطة" />
            <Tab label="سجل السلف" />
          </Tabs>
        </Box>

        <TabPanel value={tabValue} index={0}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>الموظف</TableCell>
                  <TableCell>المبلغ</TableCell>
                  <TableCell>تاريخ الطلب</TableCell>
                  <TableCell>السبب</TableCell>
                  <TableCell>عدد الأقساط</TableCell>
                  <TableCell>المبلغ المتبقي</TableCell>
                  <TableCell>الحالة</TableCell>
                  <TableCell>الإجراءات</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {state.advances
                  .filter(advance => advance.status !== 'completed')
                  .map(advance => {
                    const employee = employees.find(emp => emp.id === advance.employeeId);
                    return (
                      <TableRow key={advance.id}>
                        <TableCell>{employee?.name}</TableCell>
                        <TableCell>{formatCurrency(advance.amount)}</TableCell>
                        <TableCell>{new Date(advance.date).toLocaleDateString('ar-EG')}</TableCell>
                        <TableCell>{advance.reason}</TableCell>
                        <TableCell>{advance.installments}</TableCell>
                        <TableCell>{formatCurrency(advance.remainingAmount)}</TableCell>
                        <TableCell>
                          <Chip
                            label={
                              advance.status === 'pending' ? 'قيد الانتظار' :
                              advance.status === 'approved' ? 'تمت الموافقة' :
                              advance.status === 'rejected' ? 'مرفوض' : 'مكتمل'
                            }
                            color={
                              advance.status === 'pending' ? 'warning' :
                              advance.status === 'approved' ? 'success' :
                              advance.status === 'rejected' ? 'error' : 'default'
                            }
                          />
                        </TableCell>
                        <TableCell>
                          {advance.status === 'pending' && (
                            <>
                              <Tooltip title="موافقة">
                                <IconButton
                                  color="success"
                                  onClick={() => handleApprove(advance)}
                                >
                                  <ApproveIcon />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="رفض">
                                <IconButton
                                  color="error"
                                  onClick={() => handleReject(advance)}
                                >
                                  <RejectIcon />
                                </IconButton>
                              </Tooltip>
                              <Tooltip title="حذف">
                                <IconButton
                                  color="error"
                                  onClick={() => handleDelete(advance)}
                                >
                                  <DeleteIcon />
                                </IconButton>
                              </Tooltip>
                            </>
                          )}
                          {advance.status === 'approved' && (
                            <Tooltip title="تفاصيل الأقساط">
                              <IconButton color="primary">
                                <PaymentIcon />
                              </IconButton>
                            </Tooltip>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
              </TableBody>
            </Table>
          </TableContainer>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>الموظف</TableCell>
                  <TableCell>المبلغ</TableCell>
                  <TableCell>تاريخ الطلب</TableCell>
                  <TableCell>تاريخ الموافقة</TableCell>
                  <TableCell>السبب</TableCell>
                  <TableCell>الحالة</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {state.advances
                  .filter(advance => advance.status === 'completed')
                  .map(advance => {
                    const employee = employees.find(emp => emp.id === advance.employeeId);
                    return (
                      <TableRow key={advance.id}>
                        <TableCell>{employee?.name}</TableCell>
                        <TableCell>{formatCurrency(advance.amount)}</TableCell>
                        <TableCell>{new Date(advance.date).toLocaleDateString('ar-EG')}</TableCell>
                        <TableCell>
                          {advance.approvalDate && new Date(advance.approvalDate).toLocaleDateString('ar-EG')}
                        </TableCell>
                        <TableCell>{advance.reason}</TableCell>
                        <TableCell>
                          <Chip label="مكتمل" color="default" />
                        </TableCell>
                      </TableRow>
                    );
                  })}
              </TableBody>
            </Table>
          </TableContainer>
        </TabPanel>
      </Paper>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedAdvance ? 'تعديل طلب سلفة' : 'طلب سلفة جديدة'}
        </DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>الموظف</InputLabel>
                <Select
                  name="employeeId"
                  value={formData.employeeId}
                  onChange={handleSelectChange}
                  label="الموظف"
                >
                  {employees.map(employee => (
                    <MenuItem key={employee.id} value={employee.id}>
                      {employee.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="المبلغ"
                name="amount"
                type="number"
                value={formData.amount}
                onChange={handleTextFieldChange}
                InputProps={{ inputProps: { min: 0 } }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="عدد الأقساط"
                name="installments"
                type="number"
                value={formData.installments}
                onChange={handleTextFieldChange}
                InputProps={{ inputProps: { min: 1 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="السبب"
                name="reason"
                value={formData.reason}
                onChange={handleTextFieldChange}
                multiline
                rows={2}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="ملاحظات"
                name="notes"
                value={formData.notes}
                onChange={handleTextFieldChange}
                multiline
                rows={2}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>إلغاء</Button>
          <Button
            variant="contained"
            color="primary"
            onClick={handleSubmit}
          >
            {selectedAdvance ? 'تحديث' : 'إضافة'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AdvanceManager;
