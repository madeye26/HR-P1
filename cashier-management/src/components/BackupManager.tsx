import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
  TextField,
  MenuItem,
  Toolbar,
  LinearProgress,
} from '@mui/material';
import {
  Backup as BackupIcon,
  Restore as RestoreIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';

interface BackupRecord {
  id: string;
  timestamp: string;
  size: string;
  type: 'auto' | 'manual';
  status: 'success' | 'failed';
  path: string;
}

interface BackupSettings {
  autoBackup: boolean;
  frequency: 'daily' | 'weekly' | 'monthly';
  time: string;
  retentionDays: number;
  compressionLevel: 'low' | 'medium' | 'high';
  includeAttachments: boolean;
  encryptBackups: boolean;
}

const BackupManager: React.FC = () => {
  const [backups, setBackups] = useState<BackupRecord[]>([
    {
      id: '1',
      timestamp: new Date().toISOString(),
      size: '256 MB',
      type: 'auto',
      status: 'success',
      path: '/backups/auto/backup_20231001.zip'
    },
    {
      id: '2',
      timestamp: new Date(Date.now() - 86400000).toISOString(),
      size: '245 MB',
      type: 'manual',
      status: 'success',
      path: '/backups/manual/backup_20230930.zip'
    }
  ]);

  const [settings, setSettings] = useState<BackupSettings>({
    autoBackup: true,
    frequency: 'daily',
    time: '00:00',
    retentionDays: 30,
    compressionLevel: 'medium',
    includeAttachments: true,
    encryptBackups: true
  });

  const [settingsOpen, setSettingsOpen] = useState(false);
  const [isBackingUp, setIsBackingUp] = useState(false);
  const [backupProgress, setBackupProgress] = useState(0);

  const handleCreateBackup = async () => {
    setIsBackingUp(true);
    setBackupProgress(0);

    // Simulate backup process
    for (let i = 0; i <= 100; i += 10) {
      await new Promise(resolve => setTimeout(resolve, 500));
      setBackupProgress(i);
    }

    const newBackup: BackupRecord = {
      id: Date.now().toString(),
      timestamp: new Date().toISOString(),
      size: '250 MB',
      type: 'manual',
      status: 'success',
      path: `/backups/manual/backup_${new Date().toISOString().split('T')[0].replace(/-/g, '')}.zip`
    };

    setBackups(prev => [newBackup, ...prev]);
    setIsBackingUp(false);
    setBackupProgress(0);
  };

  const handleRestore = (backup: BackupRecord) => {
    console.log('Restoring backup:', backup);
  };

  const handleDelete = (id: string) => {
    setBackups(prev => prev.filter(backup => backup.id !== id));
  };

  const handleDownload = (backup: BackupRecord) => {
    console.log('Downloading backup:', backup);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('ar-EG', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <Box>
      <Toolbar sx={{ justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">
          إدارة النسخ الاحتياطي
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="contained"
            startIcon={<BackupIcon />}
            onClick={handleCreateBackup}
            disabled={isBackingUp}
          >
            نسخ احتياطي جديد
          </Button>
          <IconButton onClick={() => setSettingsOpen(true)}>
            <SettingsIcon />
          </IconButton>
        </Box>
      </Toolbar>

      {isBackingUp && (
        <Box sx={{ width: '100%', mb: 3 }}>
          <LinearProgress variant="determinate" value={backupProgress} />
          <Typography variant="caption" sx={{ mt: 1 }}>
            جاري إنشاء نسخة احتياطية... {backupProgress}%
          </Typography>
        </Box>
      )}

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي النسخ</Typography>
            <Typography variant="h4">{backups.length}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">النسخ التلقائية</Typography>
            <Typography variant="h4">
              {backups.filter(b => b.type === 'auto').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">النسخ اليدوية</Typography>
            <Typography variant="h4">
              {backups.filter(b => b.type === 'manual').length}
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="subtitle1">إجمالي الحجم</Typography>
            <Typography variant="h4">
              {backups.reduce((sum, b) => sum + parseInt(b.size), 0)} MB
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>التاريخ</TableCell>
              <TableCell>النوع</TableCell>
              <TableCell>الحجم</TableCell>
              <TableCell>الحالة</TableCell>
              <TableCell>الإجراءات</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {backups.map((backup) => (
              <TableRow key={backup.id}>
                <TableCell>{formatDate(backup.timestamp)}</TableCell>
                <TableCell>
                  <Chip
                    label={backup.type === 'auto' ? 'تلقائي' : 'يدوي'}
                    color={backup.type === 'auto' ? 'primary' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>{backup.size}</TableCell>
                <TableCell>
                  <Chip
                    label={backup.status === 'success' ? 'ناجح' : 'فشل'}
                    color={backup.status === 'success' ? 'success' : 'error'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={() => handleRestore(backup)}
                    title="استعادة"
                  >
                    <RestoreIcon />
                  </IconButton>
                  <IconButton
                    size="small"
                    onClick={() => handleDownload(backup)}
                    title="تحميل"
                  >
                    <DownloadIcon />
                  </IconButton>
                  <IconButton
                    size="small"
                    onClick={() => handleDelete(backup.id)}
                    title="حذف"
                  >
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog
        open={settingsOpen}
        onClose={() => setSettingsOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>إعدادات النسخ الاحتياطي</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.autoBackup}
                    onChange={(e) => setSettings({
                      ...settings,
                      autoBackup: e.target.checked
                    })}
                  />
                }
                label="النسخ الاحتياطي التلقائي"
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                select
                label="تكرار النسخ"
                value={settings.frequency}
                onChange={(e) => setSettings({
                  ...settings,
                  frequency: e.target.value as BackupSettings['frequency']
                })}
                disabled={!settings.autoBackup}
              >
                <MenuItem value="daily">يومي</MenuItem>
                <MenuItem value="weekly">أسبوعي</MenuItem>
                <MenuItem value="monthly">شهري</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="time"
                label="وقت النسخ"
                value={settings.time}
                onChange={(e) => setSettings({
                  ...settings,
                  time: e.target.value
                })}
                disabled={!settings.autoBackup}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="number"
                label="مدة الاحتفاظ (بالأيام)"
                value={settings.retentionDays}
                onChange={(e) => setSettings({
                  ...settings,
                  retentionDays: parseInt(e.target.value)
                })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                select
                label="مستوى الضغط"
                value={settings.compressionLevel}
                onChange={(e) => setSettings({
                  ...settings,
                  compressionLevel: e.target.value as BackupSettings['compressionLevel']
                })}
              >
                <MenuItem value="low">منخفض</MenuItem>
                <MenuItem value="medium">متوسط</MenuItem>
                <MenuItem value="high">عالي</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.includeAttachments}
                    onChange={(e) => setSettings({
                      ...settings,
                      includeAttachments: e.target.checked
                    })}
                  />
                }
                label="تضمين المرفقات"
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.encryptBackups}
                    onChange={(e) => setSettings({
                      ...settings,
                      encryptBackups: e.target.checked
                    })}
                  />
                }
                label="تشفير النسخ الاحتياطية"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSettingsOpen(false)}>إلغاء</Button>
          <Button variant="contained" onClick={() => setSettingsOpen(false)}>
            حفظ التغييرات
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default BackupManager;
