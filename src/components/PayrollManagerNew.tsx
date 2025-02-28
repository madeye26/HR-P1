import { useState } from 'react';
import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Button,
  Tab,
  Tabs,
  IconButton,
  Tooltip,
  ButtonGroup as MuiButtonGroup,
} from '@mui/material';
import {
  Settings as SettingsIcon,
  PictureAsPdf as PdfIcon,
  Calculate as CalculateIcon,
} from '@mui/icons-material';
import { useEmployee } from '../context/EmployeeContext';
import { PayrollRecord, PayrollSettings as IPayrollSettings } from '../types/payroll';
import { calculatePayrollRecord } from '../utils/payrollCalculations';
import { defaultPayrollSettings } from '../config/payrollSettings';
import PayrollSettingsPanel from './PayrollSettings';
import {
  PayrollContainer,
  PayrollHeader,
  PayrollFilters,
  PayrollTable,
  FormGroup,
} from '../styles/PayrollStyles';

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
      id={`payroll-tabpanel-${index}`}
      aria-labelledby={`payroll-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

function PayrollManagerNew() {
  const { state, dispatch } = useEmployee();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [tabValue, setTabValue] = useState(0);
  const [showSettings, setShowSettings] = useState(false);
  const [settings, setSettings] = useState<IPayrollSettings>(defaultPayrollSettings);

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleSettingsChange = (newSettings: IPayrollSettings) => {
    setSettings(newSettings);
    localStorage.setItem('payrollSettings', JSON.stringify(newSettings));
  };

  const generatePayroll = () => {
    const newPayrollRecords = state.employees.map(employee => {
      return calculatePayrollRecord(employee, selectedMonth, selectedYear, settings);
    });

    newPayrollRecords.forEach(record => {
      dispatch({
        type: 'ADD_PAYROLL_RECORD',
        payload: record
      });

      dispatch({
        type: 'ADD_NOTIFICATION',
        payload: {
          id: Date.now().toString(),
          type: 'payroll',
          title: 'تم إنشاء كشف راتب جديد',
          message: `تم إنشاء كشف راتب ${record.employeeName} لشهر ${selectedMonth}/${selectedYear}`,
          status: 'unread',
          createdAt: new Date().toISOString(),
          targetId: record.id,
          targetType: 'payroll_record'
        }
      });
    });
  };

  const handleProcessPayroll = (recordId: string) => {
    dispatch({
      type: 'PROCESS_PAYROLL',
      payload: { 
        id: recordId,
        processedBy: '1' // Using string instead of number
      }
    });
  };

  const handleMarkAsPaid = (recordId: string) => {
    dispatch({
      type: 'MARK_PAYROLL_PAID',
      payload: { 
        id: recordId,
        paidBy: '1' // Using string instead of number
      }
    });
  };

  // ... rest of the component code remains the same ...

  return (
    <PayrollContainer>
      <PayrollHeader>
        <Typography variant="h5">إدارة كشوف المرتبات</Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="إعدادات الرواتب">
            <IconButton onClick={() => setShowSettings(!showSettings)}>
              <SettingsIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="contained"
            color="primary"
            startIcon={<CalculateIcon />}
            onClick={generatePayroll}
          >
            إنشاء كشف المرتبات
          </Button>
          {state.payrollRecords.length > 0 && (
            <Button
              variant="outlined"
              color="primary"
              startIcon={<PdfIcon />}
              onClick={() => {
                const doc = new jsPDF();
                // ... PDF generation code ...
                doc.save(`payroll-${selectedMonth}-${selectedYear}.pdf`);
              }}
            >
              تصدير PDF
            </Button>
          )}
        </Box>
      </PayrollHeader>

      {showSettings && (
        <PayrollSettingsPanel
          settings={settings}
          onSave={handleSettingsChange}
        />
      )}

      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={handleTabChange}>
          <Tab label="كشف المرتبات" />
          <Tab label="السجل" />
        </Tabs>
      </Box>

      <TabPanel value={tabValue} index={0}>
        <PayrollFilters>
          <FormGroup>
            <label>الشهر</label>
            <select
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(parseInt(e.target.value))}
            >
              {Array.from({ length: 12 }, (_, i) => i + 1).map(month => (
                <option key={month} value={month}>
                  {new Date(2000, month - 1).toLocaleString('ar-SA', { month: 'long' })}
                </option>
              ))}
            </select>
          </FormGroup>

          <FormGroup>
            <label>السنة</label>
            <select
              value={selectedYear}
              onChange={(e) => setSelectedYear(parseInt(e.target.value))}
            >
              {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map(year => (
                <option key={year} value={year}>{year}</option>
              ))}
            </select>
          </FormGroup>
        </PayrollFilters>

        {/* ... rest of the JSX remains the same ... */}
      </TabPanel>

      <TabPanel value={tabValue} index={1}>
        <Typography>سجل المعاملات</Typography>
      </TabPanel>
    </PayrollContainer>
  );
}

export default PayrollManagerNew;
