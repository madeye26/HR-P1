import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondary,
  IconButton,
  Chip,
  Divider,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
  Grid,
  Badge,
  Toolbar,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  NotificationsActive as UrgentIcon,
  NotificationsOff as DisabledIcon,
  Delete as DeleteIcon,
  CheckCircle as ReadIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';

interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  timestamp: string;
  isRead: boolean;
  isUrgent: boolean;
  category: 'attendance' | 'payroll' | 'leave' | 'system';
  actionUrl?: string;
}

interface NotificationPreferences {
  email: boolean;
  push: boolean;
  sms: boolean;
  categories: {
    attendance: boolean;
    payroll: boolean;
    leave: boolean;
    system: boolean;
  };
}

const NotificationsManager: React.FC = () => {
  const [notifications, setNotifications] = useState<Notification[]>([
    {
      id: '1',
      title: 'طلب إجازة جديد',
      message: 'قام أحمد محمد بتقديم طلب إجازة جديد',
      type: 'info',
      timestamp: new Date().toISOString(),
      isRead: false,
      isUrgent: true,
      category: 'leave',
      actionUrl: '/leave'
    },
    {
      id: '2',
      title: 'تأخر في الحضور',
      message: 'تم تسجيل تأخر في الحضور لـ 3 موظفين',
      type: 'warning',
      timestamp: new Date().toISOString(),
      isRead: false,
      isUrgent: false,
      category: 'attendance',
      actionUrl: '/attendance'
    }
  ]);

  const [preferences, setPreferences] = useState<NotificationPreferences>({
    email: true,
    push: true,
    sms: false,
    categories: {
      attendance: true,
      payroll: true,
      leave: true,
      system: true
    }
  });

  const [settingsOpen, setSettingsOpen] = useState(false);

  const handleMarkAsRead = (id: string) => {
    setNotifications(prev =>
      prev.map(notif =>
        notif.id === id ? { ...notif, isRead: true } : notif
      )
    );
  };

  const handleDelete = (id: string) => {
    setNotifications(prev => prev.filter(notif => notif.id !== id));
  };

  const handleClearAll = () => {
    setNotifications([]);
  };

  const handleMarkAllAsRead = () => {
    setNotifications(prev =>
      prev.map(notif => ({ ...notif, isRead: true }))
    );
  };

  const getNotificationIcon = (type: Notification['type']) => {
    switch (type) {
      case 'info':
        return <NotificationsIcon color="info" />;
      case 'warning':
        return <NotificationsIcon color="warning" />;
      case 'error':
        return <NotificationsIcon color="error" />;
      case 'success':
        return <NotificationsIcon color="success" />;
      default:
        return <NotificationsIcon />;
    }
  };

  const getCategoryText = (category: Notification['category']) => {
    switch (category) {
      case 'attendance':
        return 'الحضور والانصراف';
      case 'payroll':
        return 'الرواتب';
      case 'leave':
        return 'الإجازات';
      case 'system':
        return 'النظام';
      default:
        return category;
    }
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">
          الإشعارات
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            onClick={handleMarkAllAsRead}
            disabled={notifications.every(n => n.isRead)}
          >
            تحديد الكل كمقروء
          </Button>
          <Button
            variant="outlined"
            onClick={handleClearAll}
            disabled={notifications.length === 0}
          >
            حذف الكل
          </Button>
          <IconButton onClick={() => setSettingsOpen(true)}>
            <SettingsIcon />
          </IconButton>
        </Box>
      </Toolbar>

      <Paper>
        <List>
          {notifications.length === 0 ? (
            <ListItem>
              <ListItemText
                primary="لا توجد إشعارات"
                secondary="أنت على اطلاع بكل شيء"
              />
            </ListItem>
          ) : (
            notifications.map((notification) => (
              <React.Fragment key={notification.id}>
                <ListItem
                  secondaryAction={
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      {!notification.isRead && (
                        <IconButton
                          edge="end"
                          onClick={() => handleMarkAsRead(notification.id)}
                        >
                          <ReadIcon />
                        </IconButton>
                      )}
                      <IconButton
                        edge="end"
                        onClick={() => handleDelete(notification.id)}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  }
                >
                  <ListItemIcon>
                    <Badge
                      color="error"
                      variant="dot"
                      invisible={notification.isRead}
                    >
                      {getNotificationIcon(notification.type)}
                    </Badge>
                  </ListItemIcon>
                  <ListItemText
                    primary={
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {notification.title}
                        {notification.isUrgent && (
                          <Chip
                            size="small"
                            color="error"
                            label="عاجل"
                            icon={<UrgentIcon />}
                          />
                        )}
                      </Box>
                    }
                    secondary={
                      <>
                        <Typography variant="body2" color="text.secondary">
                          {notification.message}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                          <Chip
                            size="small"
                            label={getCategoryText(notification.category)}
                          />
                          <Typography variant="caption" color="text.secondary">
                            {new Date(notification.timestamp).toLocaleString('ar-EG')}
                          </Typography>
                        </Box>
                      </>
                    }
                  />
                </ListItem>
                <Divider />
              </React.Fragment>
            ))
          )}
        </List>
      </Paper>

      <Dialog
        open={settingsOpen}
        onClose={() => setSettingsOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>إعدادات الإشعارات</DialogTitle>
        <DialogContent>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                طرق الإشعار
              </Typography>
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.email}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      email: e.target.checked
                    })}
                  />
                }
                label="البريد الإلكتروني"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.push}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      push: e.target.checked
                    })}
                  />
                }
                label="إشعارات الموقع"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.sms}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      sms: e.target.checked
                    })}
                  />
                }
                label="الرسائل النصية"
              />
            </Grid>
            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                أنواع الإشعارات
              </Typography>
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.categories.attendance}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      categories: {
                        ...preferences.categories,
                        attendance: e.target.checked
                      }
                    })}
                  />
                }
                label="الحضور والانصراف"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.categories.payroll}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      categories: {
                        ...preferences.categories,
                        payroll: e.target.checked
                      }
                    })}
                  />
                }
                label="الرواتب"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.categories.leave}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      categories: {
                        ...preferences.categories,
                        leave: e.target.checked
                      }
                    })}
                  />
                }
                label="الإجازات"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={preferences.categories.system}
                    onChange={(e) => setPreferences({
                      ...preferences,
                      categories: {
                        ...preferences.categories,
                        system: e.target.checked
                      }
                    })}
                  />
                }
                label="إشعارات النظام"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSettingsOpen(false)}>إغلاق</Button>
          <Button variant="contained" onClick={() => setSettingsOpen(false)}>
            حفظ التغييرات
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default NotificationsManager;
