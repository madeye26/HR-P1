import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  TextField,
  Switch,
  FormControlLabel,
  Button,
  Divider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  IconButton,
  Tooltip,
} from '@mui/material';
import { Save as SaveIcon, Refresh as ResetIcon } from '@mui/icons-material';
import { PayrollSettings as IPayrollSettings } from '../types/payroll';
import { defaultPayrollSettings } from '../config/payrollSettings';

interface PayrollSettingsProps {
  settings: IPayrollSettings;
  onSave: (settings: IPayrollSettings) => void;
}

const PayrollSettings: React.FC<PayrollSettingsProps> = ({ settings, onSave }) => {
  const [currentSettings, setCurrentSettings] = useState<IPayrollSettings>(settings);
  const [isEditing, setIsEditing] = useState(false);

  const handleRateChange = (field: keyof IPayrollSettings['rates'], value: number | string) => {
    setCurrentSettings(prev => ({
      ...prev,
      rates: {
        ...prev.rates,
        [field]: typeof value === 'string' ? parseFloat(value) || 0 : value
      }
    }));
  };

  const handleTaxBracketChange = (index: number, field: 'min' | 'max' | 'rate', value: string) => {
    setCurrentSettings(prev => ({
      ...prev,
      taxBrackets: prev.taxBrackets.map((bracket, i) => 
        i === index ? { ...bracket, [field]: parseFloat(value) || 0 } : bracket
      )
    }));
  };

  const handleToggleChange = (
    category: 'deductions' | 'additions' | 'allowances',
    field: string,
    checked: boolean
  ) => {
    setCurrentSettings(prev => ({
      ...prev,
      [category]: {
        ...prev[category],
        [field]: checked
      }
    }));
  };

  const handleCalculationMethodChange = (
    category: 'rates' | 'deductions' | 'additions',
    field: string,
    value: string
  ) => {
    setCurrentSettings(prev => ({
      ...prev,
      [category]: {
        ...prev[category],
        [field]: value
      }
    }));
  };

  const handleSave = () => {
    onSave(currentSettings);
    setIsEditing(false);
  };

  const handleReset = () => {
    setCurrentSettings(defaultPayrollSettings);
  };

  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">إعدادات الرواتب</Typography>
        <Box>
          <Tooltip title="إعادة تعيين إلى الإعدادات الافتراضية">
            <IconButton onClick={handleReset} color="warning">
              <ResetIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="contained"
            color="primary"
            startIcon={<SaveIcon />}
            onClick={handleSave}
            disabled={!isEditing}
          >
            حفظ التغييرات
          </Button>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Basic Rates Section */}
        <Grid item xs={12}>
          <Typography variant="subtitle1" sx={{ mb: 2 }}>المعدلات الأساسية</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="معدل التأمين الاجتماعي"
                type="number"
                value={currentSettings.rates.socialInsurance}
                onChange={(e) => {
                  handleRateChange('socialInsurance', e.target.value);
                  setIsEditing(true);
                }}
                InputProps={{ inputProps: { min: 0, max: 1, step: 0.01 } }}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="معدل التأمين الصحي"
                type="number"
                value={currentSettings.rates.healthInsurance}
                onChange={(e) => {
                  handleRateChange('healthInsurance', e.target.value);
                  setIsEditing(true);
                }}
                InputProps={{ inputProps: { min: 0, max: 1, step: 0.01 } }}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="معدل العمل الإضافي"
                type="number"
                value={currentSettings.rates.overtimeRate}
                onChange={(e) => {
                  handleRateChange('overtimeRate', e.target.value);
                  setIsEditing(true);
                }}
                InputProps={{ inputProps: { min: 1, step: 0.1 } }}
              />
            </Grid>
          </Grid>
        </Grid>

        {/* Work Schedule Section */}
        <Grid item xs={12}>
          <Typography variant="subtitle1" sx={{ mb: 2 }}>جدول العمل</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="أيام العمل في الشهر"
                type="number"
                value={currentSettings.rates.workingDaysPerMonth}
                onChange={(e) => {
                  handleRateChange('workingDaysPerMonth', e.target.value);
                  setIsEditing(true);
                }}
                InputProps={{ inputProps: { min: 1, max: 31 } }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="ساعات العمل في اليوم"
                type="number"
                value={currentSettings.rates.workingHoursPerDay}
                onChange={(e) => {
                  handleRateChange('workingHoursPerDay', e.target.value);
                  setIsEditing(true);
                }}
                InputProps={{ inputProps: { min: 1, max: 24 } }}
              />
            </Grid>
          </Grid>
        </Grid>

        {/* Calculation Methods Section */}
        <Grid item xs={12}>
          <Typography variant="subtitle1" sx={{ mb: 2 }}>طرق الحساب</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth>
                <InputLabel>حساب المعدل اليومي</InputLabel>
                <Select
                  value={currentSettings.rates.dailyRateCalculation}
                  onChange={(e) => {
                    handleCalculationMethodChange('rates', 'dailyRateCalculation', e.target.value);
                    setIsEditing(true);
                  }}
                >
                  <MenuItem value="monthly">شهري</MenuItem>
                  <MenuItem value="hourly">بالساعة</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth>
                <InputLabel>حساب الحوافز</InputLabel>
                <Select
                  value={currentSettings.rates.incentiveCalculation}
                  onChange={(e) => {
                    handleCalculationMethodChange('rates', 'incentiveCalculation', e.target.value);
                    setIsEditing(true);
                  }}
                >
                  <MenuItem value="percentage">نسبة مئوية</MenuItem>
                  <MenuItem value="fixed">مبلغ ثابت</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth>
                <InputLabel>حساب الغياب</InputLabel>
                <Select
                  value={currentSettings.deductions.absenceCalculation}
                  onChange={(e) => {
                    handleCalculationMethodChange('deductions', 'absenceCalculation', e.target.value);
                    setIsEditing(true);
                  }}
                >
                  <MenuItem value="daily">يومي</MenuItem>
                  <MenuItem value="hourly">بالساعة</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </Grid>

        {/* Toggles Section */}
        <Grid item xs={12}>
          <Typography variant="subtitle1" sx={{ mb: 2 }}>تفعيل/تعطيل المكونات</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={currentSettings.deductions.enableSocialInsurance}
                    onChange={(e) => {
                      handleToggleChange('deductions', 'enableSocialInsurance', e.target.checked);
                      setIsEditing(true);
                    }}
                  />
                }
                label="التأمين الاجتماعي"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={currentSettings.deductions.enableHealthInsurance}
                    onChange={(e) => {
                      handleToggleChange('deductions', 'enableHealthInsurance', e.target.checked);
                      setIsEditing(true);
                    }}
                  />
                }
                label="التأمين الصحي"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={currentSettings.additions.enableOvertime}
                    onChange={(e) => {
                      handleToggleChange('additions', 'enableOvertime', e.target.checked);
                      setIsEditing(true);
                    }}
                  />
                }
                label="العمل الإضافي"
              />
            </Grid>
          </Grid>
        </Grid>

        {/* Tax Brackets Section */}
        <Grid item xs={12}>
          <Typography variant="subtitle1" sx={{ mb: 2 }}>شرائح الضريبة</Typography>
          {currentSettings.taxBrackets.map((bracket, index) => (
            <Grid container spacing={2} key={index} sx={{ mb: 2 }}>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="الحد الأدنى"
                  type="number"
                  value={bracket.min}
                  onChange={(e) => {
                    handleTaxBracketChange(index, 'min', e.target.value);
                    setIsEditing(true);
                  }}
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="الحد الأقصى"
                  type="number"
                  value={bracket.max}
                  onChange={(e) => {
                    handleTaxBracketChange(index, 'max', e.target.value);
                    setIsEditing(true);
                  }}
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  label="النسبة"
                  type="number"
                  value={bracket.rate}
                  onChange={(e) => {
                    handleTaxBracketChange(index, 'rate', e.target.value);
                    setIsEditing(true);
                  }}
                  InputProps={{ inputProps: { min: 0, max: 1, step: 0.001 } }}
                />
              </Grid>
            </Grid>
          ))}
        </Grid>
      </Grid>
    </Paper>
  );
};

export default PayrollSettings;
