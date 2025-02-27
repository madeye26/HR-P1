import React, { ReactNode } from 'react';
import {
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemButton,
  Divider,
  Toolbar,
  Typography,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  AttachMoney as PayrollIcon,
  EventNote as AttendanceIcon,
  BusinessCenter as DepartmentsIcon,
  Receipt as ExpensesIcon,
  Settings as SettingsIcon,
  ExitToApp as LogoutIcon,
  BeachAccess as LeaveIcon,
  Assessment as ReportIcon,
  Backup as BackupIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';

interface MenuItem {
  text: string;
  icon: ReactNode;
  path: string;
  group?: string;
}

const menuGroups: { [key: string]: MenuItem[] } = {
  main: [
    { text: 'لوحة التحكم', icon: <DashboardIcon />, path: '/', group: 'main' },
    { text: 'التقرير اليومي', icon: <ReportIcon />, path: '/daily-report', group: 'main' },
  ],
  hr: [
    { text: 'الموظفين', icon: <PeopleIcon />, path: '/employees', group: 'hr' },
    { text: 'الرواتب', icon: <PayrollIcon />, path: '/payroll', group: 'hr' },
    { text: 'الحضور والانصراف', icon: <AttendanceIcon />, path: '/attendance', group: 'hr' },
    { text: 'الإجازات', icon: <LeaveIcon />, path: '/leave', group: 'hr' },
  ],
  management: [
    { text: 'الأقسام', icon: <DepartmentsIcon />, path: '/departments', group: 'management' },
    { text: 'المصروفات', icon: <ExpensesIcon />, path: '/expenses', group: 'management' },
  ],
  system: [
    { text: 'النسخ الاحتياطي', icon: <BackupIcon />, path: '/backup', group: 'system' },
    { text: 'الإعدادات', icon: <SettingsIcon />, path: '/settings', group: 'system' },
  ],
};

const groupTitles: { [key: string]: string } = {
  main: 'الرئيسية',
  hr: 'الموارد البشرية',
  management: 'الإدارة',
  system: 'النظام',
};

interface NavigationProps {
  onLogout: () => void;
}

const Navigation: React.FC<NavigationProps> = ({ onLogout }) => {
  const navigate = useNavigate();
  const location = useLocation();

  const handleNavigation = (path: string) => {
    navigate(path);
  };

  const isSelected = (path: string) => {
    return location.pathname === path;
  };

  return (
    <>
      <Toolbar>
        <Typography variant="h6" noWrap component="div">
          القائمة الرئيسية
        </Typography>
      </Toolbar>
      <Divider />
      {Object.entries(menuGroups).map(([group, items]) => (
        <React.Fragment key={group}>
          <List
            subheader={
              <Typography
                variant="subtitle2"
                color="textSecondary"
                sx={{ px: 2, py: 1, fontWeight: 'bold' }}
              >
                {groupTitles[group]}
              </Typography>
            }
          >
            {items.map((item) => (
              <ListItem key={item.text} disablePadding>
                <ListItemButton
                  onClick={() => handleNavigation(item.path)}
                  selected={isSelected(item.path)}
                  sx={{
                    '&.Mui-selected': {
                      backgroundColor: 'primary.main',
                      color: 'primary.contrastText',
                      '&:hover': {
                        backgroundColor: 'primary.dark',
                      },
                      '& .MuiListItemIcon-root': {
                        color: 'primary.contrastText',
                      },
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      minWidth: 40,
                      color: isSelected(item.path) ? 'inherit' : 'default',
                    }}
                  >
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText 
                    primary={item.text}
                    primaryTypographyProps={{
                      fontSize: '0.9rem',
                    }}
                  />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
          {group !== 'system' && <Divider sx={{ my: 1 }} />}
        </React.Fragment>
      ))}
      <List>
        <ListItem disablePadding>
          <ListItemButton
            onClick={onLogout}
            sx={{
              color: 'error.main',
              '&:hover': {
                backgroundColor: 'error.light',
                color: 'error.contrastText',
                '& .MuiListItemIcon-root': {
                  color: 'error.contrastText',
                },
              },
            }}
          >
            <ListItemIcon sx={{ minWidth: 40, color: 'inherit' }}>
              <LogoutIcon />
            </ListItemIcon>
            <ListItemText 
              primary="تسجيل الخروج"
              primaryTypographyProps={{
                fontSize: '0.9rem',
              }}
            />
          </ListItemButton>
        </ListItem>
      </List>
    </>
  );
};

export default Navigation;
