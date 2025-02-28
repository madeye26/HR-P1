import React, { useState } from 'react';
import {
  Box,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  IconButton,
  Typography,
  Chip,
  Divider,
  Button,
  Badge,
  ListItemButton,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  NotificationsActive as UrgentIcon,
  Delete as DeleteIcon,
  CheckCircle as ReadIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

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

const NotificationsPopover: React.FC = () => {
  const navigate = useNavigate();
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

  const handleNotificationClick = (notification: Notification) => {
    if (notification.actionUrl) {
      handleMarkAsRead(notification.id);
      navigate(notification.actionUrl);
    }
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
    <Box sx={{ width: '100%', maxWidth: 360 }}>
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h6">الإشعارات</Typography>
        <Button size="small" onClick={() => navigate('/notifications')}>
          عرض الكل
        </Button>
      </Box>
      <Divider />
      <List sx={{ maxHeight: 400, overflow: 'auto' }}>
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
              <ListItem disablePadding>
                <ListItemButton
                  onClick={() => handleNotificationClick(notification)}
                  sx={{
                    bgcolor: notification.isRead ? 'transparent' : 'action.hover',
                  }}
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
                  <Box sx={{ display: 'flex', gap: 1, ml: 1 }}>
                    {!notification.isRead && (
                      <IconButton
                        size="small"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleMarkAsRead(notification.id);
                        }}
                      >
                        <ReadIcon />
                      </IconButton>
                    )}
                    <IconButton
                      size="small"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(notification.id);
                      }}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                </ListItemButton>
              </ListItem>
              <Divider />
            </React.Fragment>
          ))
        )}
      </List>
    </Box>
  );
};

export default NotificationsPopover;
