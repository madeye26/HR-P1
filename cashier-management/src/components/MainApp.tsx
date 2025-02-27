import React, { useState } from 'react';
import {
  Box,
  CssBaseline,
  Drawer,
  AppBar,
  Toolbar,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  IconButton,
  Badge,
  Divider,
  useTheme,
} from '@mui/material';
import {
  Menu as MenuIcon,
  People as PeopleIcon,
  AttachMoney as PayrollIcon,
  MonetizationOn as AdvanceIcon,
  CalendarToday as AttendanceIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  Dashboard as DashboardIcon,
} from '@mui/icons-material';
import { useEmployee } from '../context/EmployeeContext';
import Dashboard from './Dashboard';
import EmployeeListNew from './EmployeeListNew';
import PayrollManagerNew from './PayrollManagerNew';
import AdvanceManager from './AdvanceManager';
import AttendanceManagement from './AttendanceManagement';
import Settings from './Settings';
import NotificationsPopover from './NotificationsPopover';
import { Attendance } from '../types';

const drawerWidth = 240;

interface MenuItem {
  id: string;
  text: string;
  icon: React.ReactElement;
}

const MainApp = () => {
  const theme = useTheme();
  const { state, dispatch } = useEmployee();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [notificationsAnchor, setNotificationsAnchor] = useState<null | HTMLElement>(null);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleNotificationsClick = (event: React.MouseEvent<HTMLElement>) => {
    setNotificationsAnchor(event.currentTarget);
  };

  const handleNotificationsClose = () => {
    setNotificationsAnchor(null);
  };

  const handleRecordAttendance = (record: Omit<Attendance, 'id'>) => {
    const newRecord: Attendance = {
      ...record,
      id: Date.now().toString(),
      overtimeHours: 0, // Initialize with 0
    };
    dispatch({
      type: 'ADD_ATTENDANCE_RECORD',
      payload: newRecord
    });
  };

  const handleUpdateAttendance = (id: string, data: Partial<Attendance>) => {
    dispatch({
      type: 'UPDATE_ATTENDANCE',
      payload: { id, data }
    });
  };

  const unreadNotifications = state.notifications.filter(n => n.status === 'unread').length;

  const menuItems: MenuItem[] = [
    { id: 'dashboard', text: 'لوحة التحكم', icon: <DashboardIcon /> },
    { id: 'employees', text: 'الموظفين', icon: <PeopleIcon /> },
    { id: 'payroll', text: 'الرواتب', icon: <PayrollIcon /> },
    { id: 'advances', text: 'السلف', icon: <AdvanceIcon /> },
    { id: 'attendance', text: 'الحضور والانصراف', icon: <AttendanceIcon /> },
    { id: 'settings', text: 'الإعدادات', icon: <SettingsIcon /> },
  ];

  const drawer = (
    <div>
      <Toolbar>
        <Typography variant="h6" noWrap component="div">
          نظام إدارة الرواتب
        </Typography>
      </Toolbar>
      <Divider />
      <List>
        {menuItems.map((item) => (
          <ListItem key={item.id} disablePadding>
            <ListItemButton
              onClick={() => setCurrentView(item.id)}
              selected={currentView === item.id}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </div>
  );

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return <Dashboard />;
      case 'employees':
        return <EmployeeListNew />;
      case 'payroll':
        return <PayrollManagerNew />;
      case 'advances':
        return <AdvanceManager employees={state.employees} />;
      case 'attendance':
        return (
          <AttendanceManagement
            employees={state.employees}
            onRecordAttendance={handleRecordAttendance}
            onUpdateAttendance={handleUpdateAttendance}
          />
        );
      case 'settings':
        return <Settings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <Box sx={{ display: 'flex', direction: 'rtl' }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          mr: { sm: `${drawerWidth}px` },
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            {menuItems.find(item => item.id === currentView)?.text}
          </Typography>
          <IconButton color="inherit" onClick={handleNotificationsClick}>
            <Badge badgeContent={unreadNotifications} color="error">
              <NotificationsIcon />
            </Badge>
          </IconButton>
        </Toolbar>
      </AppBar>
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          anchor="right"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better open performance on mobile.
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          anchor="right"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
        }}
      >
        <Toolbar />
        {renderCurrentView()}
      </Box>
      {notificationsAnchor && (
        <NotificationsPopover
          notifications={state.notifications}
          open={Boolean(notificationsAnchor)}
          anchorEl={notificationsAnchor}
          onClose={handleNotificationsClose}
          onMarkAsRead={(notificationId: string) => {
            dispatch({ type: 'MARK_NOTIFICATION_READ', payload: notificationId });
          }}
        />
      )}
    </Box>
  );
};

export default MainApp;
