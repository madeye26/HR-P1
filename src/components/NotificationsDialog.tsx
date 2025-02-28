import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  IconButton,
  Typography,
  Divider,
  Box,
  Tabs,
  Tab,
  Chip,
  TextField,
  InputAdornment,
} from '@mui/material';
import {
  Close as CloseIcon,
  Search as SearchIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
} from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Notification } from '../types';

interface NotificationsDialogProps {
  open: boolean;
  onClose: () => void;
  notifications: Notification[];
  onMarkAsRead: (notificationId: string) => void;
}

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
      id={`notifications-tabpanel-${index}`}
      aria-labelledby={`notifications-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 2 }}>{children}</Box>}
    </div>
  );
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

const NotificationsDialog: React.FC<NotificationsDialogProps> = ({
  open,
  onClose,
  notifications,
  onMarkAsRead,
}) => {
  const [tabValue, setTabValue] = useState(0);
  const [searchText, setSearchText] = useState('');

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const filteredNotifications = notifications.filter((notification) => {
    const matchesSearch = notification.message.toLowerCase().includes(searchText.toLowerCase()) ||
                         notification.title.toLowerCase().includes(searchText.toLowerCase());
    const matchesTab = tabValue === 0 || 
                      (tabValue === 1 && notification.status === 'unread') ||
                      (tabValue === 2 && notification.status === 'read');
    return matchesSearch && matchesTab;
  });

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          height: '80vh',
          display: 'flex',
          flexDirection: 'column',
        },
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">سجل الإشعارات</Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>
      <Divider />
      <Box sx={{ px: 2, pt: 2 }}>
        <TextField
          fullWidth
          placeholder="بحث في الإشعارات..."
          variant="outlined"
          size="small"
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ mb: 2 }}
        />
        <Tabs value={tabValue} onChange={handleTabChange} sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tab label="الكل" />
          <Tab
            label={
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                غير مقروء
                <Chip
                  size="small"
                  color="error"
                  label={notifications.filter(n => n.status === 'unread').length}
                  sx={{ ml: 1 }}
                />
              </Box>
            }
          />
          <Tab label="مقروء" />
        </Tabs>
      </Box>
      <DialogContent sx={{ p: 0, overflowY: 'auto' }}>
        <TabPanel value={tabValue} index={tabValue}>
          <List>
            {filteredNotifications.map((notification, index) => (
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
                    primary={
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Typography variant="subtitle1">{notification.title}</Typography>
                        {notification.status === 'unread' && (
                          <Chip size="small" color="primary" label="جديد" />
                        )}
                      </Box>
                    }
                    secondary={
                      <>
                        <Typography variant="body2" color="text.primary" sx={{ my: 0.5 }}>
                          {notification.message}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" component="span" dir="ltr">
                          {formatDistanceToNow(new Date(notification.createdAt), {
                            addSuffix: true,
                            locale: ar,
                          })}
                        </Typography>
                      </>
                    }
                  />
                </ListItem>
                {index < filteredNotifications.length - 1 && <Divider />}
              </React.Fragment>
            ))}
            {filteredNotifications.length === 0 && (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <InfoIcon color="disabled" sx={{ fontSize: 48, mb: 2 }} />
                <Typography color="text.secondary">
                  {searchText ? 'لا توجد نتائج للبحث' : 'لا توجد إشعارات'}
                </Typography>
              </Box>
            )}
          </List>
        </TabPanel>
      </DialogContent>
    </Dialog>
  );
};

export default NotificationsDialog;
