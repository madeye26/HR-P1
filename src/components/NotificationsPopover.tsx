import React, { useState } from 'react';
import {
  Popover,
  List,
  ListItem,
  ListItemText,
  Typography,
  IconButton,
  Box,
  Button,
  Divider,
  Badge,
  ListItemIcon,
  Tooltip,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  CheckCircle as CheckCircleIcon,
  Info as InfoIcon,
  Warning as WarningIcon,
  DoneAll as DoneAllIcon,
} from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Notification } from '../types';
import NotificationsDialog from './NotificationsDialog';

interface NotificationsPopoverProps {
  notifications: Notification[];
  open: boolean;
  anchorEl: HTMLElement | null;
  onClose: () => void;
  onMarkAsRead: (notificationId: string) => void;
  onMarkAllAsRead?: () => void;
}

const getNotificationIcon = (type: Notification['type']) => {
  switch (type) {
    case 'payroll':
      return <CheckCircleIcon color="success" />;
    case 'advance':
      return <WarningIcon color="warning" />;
    case 'leave':
      return <InfoIcon color="info" />;
    case 'attendance':
      return <WarningIcon color="warning" />;
    case 'system':
      return <InfoIcon color="info" />;
    default:
      return <InfoIcon color="info" />;
  }
};

const NotificationsPopover: React.FC<NotificationsPopoverProps> = ({
  notifications,
  open,
  anchorEl,
  onClose,
  onMarkAsRead,
  onMarkAllAsRead,
}) => {
  const [dialogOpen, setDialogOpen] = useState(false);
  const unreadCount = notifications.filter(n => n.status === 'unread').length;

  return (
    <>
      <Popover
        open={open}
        anchorEl={anchorEl}
        onClose={onClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        PaperProps={{
          sx: {
            width: 360,
            maxHeight: '70vh',
          },
        }}
      >
        <Box sx={{ p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">
            الإشعارات
            {unreadCount > 0 && (
              <Badge
                badgeContent={unreadCount}
                color="error"
                sx={{ ml: 1 }}
              />
            )}
          </Typography>
          {unreadCount > 0 && onMarkAllAsRead && (
            <Tooltip title="تحديد الكل كمقروء">
              <IconButton onClick={onMarkAllAsRead} size="small">
                <DoneAllIcon />
              </IconButton>
            </Tooltip>
          )}
        </Box>
        <Divider />
        {notifications.length > 0 ? (
          <List sx={{ py: 0 }}>
            {notifications.slice(0, 5).map((notification, index) => (
              <React.Fragment key={notification.id}>
                <ListItem
                  sx={{
                    bgcolor: notification.status === 'unread' ? 'action.hover' : 'inherit',
                    '&:hover': {
                      bgcolor: 'action.selected',
                    },
                  }}
                  button
                  onClick={() => onMarkAsRead(notification.id)}
                >
                  <ListItemIcon>
                    {getNotificationIcon(notification.type)}
                  </ListItemIcon>
                  <ListItemText
                    primary={notification.message}
                    secondary={
                      <Typography
                        variant="caption"
                        color="text.secondary"
                        component="span"
                        dir="ltr"
                      >
                        {formatDistanceToNow(new Date(notification.createdAt), {
                          addSuffix: true,
                          locale: ar,
                        })}
                      </Typography>
                    }
                  />
                </ListItem>
                {index < notifications.slice(0, 5).length - 1 && <Divider />}
              </React.Fragment>
            ))}
          </List>
        ) : (
          <Box sx={{ p: 3, textAlign: 'center' }}>
            <NotificationsIcon color="disabled" sx={{ fontSize: 40 }} />
            <Typography color="text.secondary" sx={{ mt: 1 }}>
              لا توجد إشعارات
            </Typography>
          </Box>
        )}
        {notifications.length > 5 && (
          <Box sx={{ p: 1 }}>
            <Button 
              fullWidth 
              color="inherit" 
              size="small"
              onClick={() => {
                onClose();
                setDialogOpen(true);
              }}
            >
              عرض كل الإشعارات
            </Button>
          </Box>
        )}
      </Popover>
      <NotificationsDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        notifications={notifications}
        onMarkAsRead={onMarkAsRead}
      />
    </>
  );
};

export default NotificationsPopover;
