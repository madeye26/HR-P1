import React from 'react';
import { Box, Tab, Tabs, Paper } from '@mui/material';
import ThemeSettings from './ThemeSettings';

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
      id={`settings-tabpanel-${index}`}
      aria-labelledby={`settings-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

const Settings: React.FC = () => {
  const [value, setValue] = React.useState(0);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Paper sx={{ width: '100%', mb: 2 }}>
        <Tabs
          value={value}
          onChange={handleChange}
          indicatorColor="primary"
          textColor="primary"
          centered
        >
          <Tab label="المظهر" />
          <Tab label="الإشعارات" />
          <Tab label="الأمان" />
          <Tab label="عام" />
        </Tabs>
      </Paper>

      <TabPanel value={value} index={0}>
        <ThemeSettings />
      </TabPanel>
      <TabPanel value={value} index={1}>
        إعدادات الإشعارات
      </TabPanel>
      <TabPanel value={value} index={2}>
        إعدادات الأمان
      </TabPanel>
      <TabPanel value={value} index={3}>
        إعدادات عامة
      </TabPanel>
    </Box>
  );
};

export default Settings;
