import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  Snackbar,
} from '@mui/material';
import { SystemConfig } from '../types';

const Settings: React.FC = () => {
  const [settings, setSettings] = useState<SystemConfig>({
    companyName: 'نظام إدارة الكاشير',
    companyLogo: undefined,
    currency: 'EGP',
    timezone: 'Africa/Cairo',
    dateFormat: 'dd/MM/yyyy',
    timeFormat: 'HH:mm',
    language: 'ar',
    theme: 'light',
  });

  const [snackbar, setSnackbar] = useState({
    open: false,
    message: '',
    severity: 'success' as 'success' | 'error',
  });

  const [backupSettings, setBackupSettings] = useState({
    autoBackup: true,
    backupFrequency: 'daily',
    backupTime: '00:00',
    retentionDays: 30,
  });

  const [notificationSettings, setNotificationSettings] = useState({
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    lowBalanceAlert: true,
    attendanceAlert: true,
    payrollAlert: true,
  });

  const handleSave = () => {
    // Here you would typically save to backend
    setSnackbar({
      open: true,
      message: 'تم حفظ الإعدادات بنجاح',
      severity: 'success',
    });
  };

  const handleBackup = () => {
    // Here you would typically trigger a backup
    setSnackbar({
      open: true,
      message: 'تم بدء النسخ الاحتياطي',
      severity: 'success',
    });
  };

  const currencies = [
    { code: 'EGP', name: 'جنيه مصري' },
    { code: 'USD', name: 'دولار أمريكي' },
    { code: 'EUR', name: 'يورو' },
    { code: 'SAR', name: 'ريال سعودي' },
  ];

  const dateFormats = [
    { value: 'dd/MM/yyyy', label: 'DD/MM/YYYY' },
    { value: 'MM/dd/yyyy', label: 'MM/DD/YYYY' },
    { value: 'yyyy-MM-dd', label: 'YYYY-MM-DD' },
  ];

  const timeFormats = [
    { value: 'HH:mm', label: '24 ساعة' },
    { value: 'hh:mm a', label: '12 ساعة' },
  ];

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        إعدادات النظام
      </Typography>

      <Grid container spacing={3}>
        {/* Company Settings */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="subtitle1" gutterBottom>
              إعدادات الشركة
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="اسم الشركة"
                  value={settings.companyName}
                  onChange={(e) => setSettings({ ...settings, companyName: e.target.value })}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>العملة</InputLabel>
                  <Select
                    value={settings.currency}
                    label="العملة"
                    onChange={(e) => setSettings({ ...settings, currency: e.target.value })}
                  >
                    {currencies.map((currency) => (
                      <MenuItem key={currency.code} value={currency.code}>
                        {currency.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Localization Settings */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="subtitle1" gutterBottom>
              إعدادات المنطقة والوقت
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>تنسيق التاريخ</InputLabel>
                  <Select
                    value={settings.dateFormat}
                    label="تنسيق التاريخ"
                    onChange={(e) => setSettings({ ...settings, dateFormat: e.target.value })}
                  >
                    {dateFormats.map((format) => (
                      <MenuItem key={format.value} value={format.value}>
                        {format.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>تنسيق الوقت</InputLabel>
                  <Select
                    value={settings.timeFormat}
                    label="تنسيق الوقت"
                    onChange={(e) => setSettings({ ...settings, timeFormat: e.target.value })}
                  >
                    {timeFormats.map((format) => (
                      <MenuItem key={format.value} value={format.value}>
                        {format.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Backup Settings */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="subtitle1" gutterBottom>
              إعدادات النسخ الاحتياطي
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={backupSettings.autoBackup}
                      onChange={(e) => setBackupSettings({
                        ...backupSettings,
                        autoBackup: e.target.checked
                      })}
                    />
                  }
                  label="النسخ الاحتياطي التلقائي"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>تكرار النسخ الاحتياطي</InputLabel>
                  <Select
                    value={backupSettings.backupFrequency}
                    label="تكرار النسخ الاحتياطي"
                    onChange={(e) => setBackupSettings({
                      ...backupSettings,
                      backupFrequency: e.target.value
                    })}
                  >
                    <MenuItem value="daily">يومي</MenuItem>
                    <MenuItem value="weekly">أسبوعي</MenuItem>
                    <MenuItem value="monthly">شهري</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  type="number"
                  label="مدة الاحتفاظ (بالأيام)"
                  value={backupSettings.retentionDays}
                  onChange={(e) => setBackupSettings({
                    ...backupSettings,
                    retentionDays: Number(e.target.value)
                  })}
                />
              </Grid>
              <Grid item xs={12}>
                <Button variant="outlined" onClick={handleBackup}>
                  نسخ احتياطي الآن
                </Button>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="subtitle1" gutterBottom>
              إعدادات الإشعارات
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={notificationSettings.emailNotifications}
                      onChange={(e) => setNotificationSettings({
                        ...notificationSettings,
                        emailNotifications: e.target.checked
                      })}
                    />
                  }
                  label="إشعارات البريد الإلكتروني"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={notificationSettings.smsNotifications}
                      onChange={(e) => setNotificationSettings({
                        ...notificationSettings,
                        smsNotifications: e.target.checked
                      })}
                    />
                  }
                  label="إشعارات الرسائل النصية"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={notificationSettings.lowBalanceAlert}
                      onChange={(e) => setNotificationSettings({
                        ...notificationSettings,
                        lowBalanceAlert: e.target.checked
                      })}
                    />
                  }
                  label="تنبيهات الرصيد المنخفض"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={notificationSettings.attendanceAlert}
                      onChange={(e) => setNotificationSettings({
                        ...notificationSettings,
                        attendanceAlert: e.target.checked
                      })}
                    />
                  }
                  label="تنبيهات الحضور والانصراف"
                />
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Save Button */}
        <Grid item xs={12}>
          <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
            <Button
              variant="contained"
              onClick={handleSave}
              size="large"
            >
              حفظ الإعدادات
            </Button>
          </Box>
        </Grid>
      </Grid>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Settings;
