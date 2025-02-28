import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { createSystemNotification, createBackupNotification } from './notificationManager';

interface BackupConfig {
  autoBackup: boolean;
  frequency: 'daily' | 'weekly' | 'monthly';
  time: string;
  retentionDays: number;
  compressionLevel: 'low' | 'medium' | 'high';
  includeAttachments: boolean;
  encryptBackups: boolean;
  backupPath: string;
}

interface BackupMetadata {
  id: string;
  timestamp: string;
  size: number;
  type: 'auto' | 'manual';
  status: 'success' | 'failed';
  compressionLevel: BackupConfig['compressionLevel'];
  encrypted: boolean;
  checksum: string;
  version: string;
}

interface BackupContent {
  employees: any[];
  attendance: any[];
  payroll: any[];
  departments: any[];
  leaves: any[];
  settings: any;
  attachments?: any[];
}

interface BackupError extends Error {
  code?: string;
  details?: any;
}

const DEFAULT_CONFIG: BackupConfig = {
  autoBackup: true,
  frequency: 'daily',
  time: '00:00',
  retentionDays: 30,
  compressionLevel: 'medium',
  includeAttachments: true,
  encryptBackups: true,
  backupPath: './backups',
};

/**
 * Create a backup of the system
 */
export const createBackup = async (
  content: BackupContent,
  config: Partial<BackupConfig> = {},
  type: 'auto' | 'manual' = 'manual'
): Promise<BackupMetadata> => {
  const mergedConfig = { ...DEFAULT_CONFIG, ...config };
  const timestamp = new Date().toISOString();
  
  try {
    // Prepare backup data
    const backupData = {
      ...content,
      attachments: mergedConfig.includeAttachments ? content.attachments : undefined,
      metadata: {
        timestamp,
        type,
        version: '1.0.0', // App version
        config: mergedConfig,
      },
    };

    // Compress data
    const compressedData = await compressData(
      backupData,
      mergedConfig.compressionLevel
    );

    // Encrypt if needed
    const finalData = mergedConfig.encryptBackups
      ? await encryptData(compressedData)
      : compressedData;

    // Calculate checksum
    const checksum = await calculateChecksum(finalData);

    // Save backup file
    const fileName = `backup_${format(new Date(timestamp), 'yyyyMMdd_HHmmss')}`;
    const filePath = `${mergedConfig.backupPath}/${fileName}.bak`;
    
    // Simulate file saving
    console.log('Saving backup to:', filePath);
    
    const metadata: BackupMetadata = {
      id: `backup_${Date.now()}`,
      timestamp,
      size: finalData.length,
      type,
      status: 'success',
      compressionLevel: mergedConfig.compressionLevel,
      encrypted: mergedConfig.encryptBackups,
      checksum,
      version: '1.0.0',
    };

    // Create success notification
    createBackupNotification('success', metadata.size);

    return metadata;

  } catch (err) {
    const error = err as BackupError;
    // Create error notification
    createBackupNotification('failed', undefined, error.message || 'Unknown error occurred');
    throw error;
  }
};

/**
 * Restore from a backup
 */
export const restoreFromBackup = async (
  backupId: string,
  decryptionKey?: string
): Promise<BackupContent> => {
  try {
    // Simulate reading backup file
    console.log('Reading backup:', backupId);

    // Decrypt if needed
    // Decompress data
    // Validate checksum
    // Restore data

    // Create success notification
    createSystemNotification(
      'استعادة النسخة الاحتياطية',
      'تم استعادة النظام بنجاح من النسخة الاحتياطية',
      'medium'
    );

    return {} as BackupContent;

  } catch (err) {
    const error = err as BackupError;
    // Create error notification
    createSystemNotification(
      'فشل استعادة النسخة الاحتياطية',
      `فشل استعادة النظام: ${error.message || 'Unknown error occurred'}`,
      'high'
    );
    throw error;
  }
};

/**
 * Clean up old backups
 */
export const cleanupOldBackups = async (
  config: BackupConfig
): Promise<string[]> => {
  try {
    const retentionDate = new Date();
    retentionDate.setDate(retentionDate.getDate() - config.retentionDays);

    // Simulate finding and deleting old backups
    console.log('Cleaning up backups older than:', retentionDate);

    return [];
  } catch (err) {
    const error = err as BackupError;
    console.error('Backup cleanup failed:', error.message || 'Unknown error occurred');
    throw error;
  }
};

/**
 * Verify backup integrity
 */
export const verifyBackup = async (
  backupId: string
): Promise<{ valid: boolean; issues?: string[] }> => {
  try {
    // Simulate backup verification
    console.log('Verifying backup:', backupId);

    return { valid: true };
  } catch (err) {
    const error = err as BackupError;
    return { 
      valid: false, 
      issues: [error.message || 'Unknown error occurred'] 
    };
  }
};

/**
 * Schedule automatic backups
 */
export const scheduleBackups = (config: BackupConfig): void => {
  if (!config.autoBackup) return;

  console.log(
    `Scheduled ${config.frequency} backups at ${config.time}`
  );
};

// Helper functions

const compressData = async (
  data: any,
  level: BackupConfig['compressionLevel']
): Promise<Uint8Array> => {
  // Simulate compression
  console.log('Compressing data with level:', level);
  return new TextEncoder().encode(JSON.stringify(data));
};

const encryptData = async (
  data: Uint8Array
): Promise<Uint8Array> => {
  // Simulate encryption
  console.log('Encrypting data');
  return data;
};

const calculateChecksum = async (
  data: Uint8Array
): Promise<string> => {
  // Simulate checksum calculation
  return 'checksum_' + Date.now();
};

/**
 * Format backup size
 */
export const formatBackupSize = (bytes: number): string => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
};

/**
 * Format backup date
 */
export const formatBackupDate = (timestamp: string): string => {
  return format(new Date(timestamp), 'dd MMMM yyyy HH:mm', { locale: ar });
};

/**
 * Get backup status color
 */
export const getBackupStatusColor = (status: BackupMetadata['status']): string => {
  return status === 'success' ? 'success' : 'error';
};

/**
 * Get compression level label
 */
export const getCompressionLevelLabel = (
  level: BackupConfig['compressionLevel']
): string => {
  const labels: Record<BackupConfig['compressionLevel'], string> = {
    low: 'منخفض',
    medium: 'متوسط',
    high: 'عالي',
  };
  return labels[level];
};

/**
 * Validate backup configuration
 */
export const validateBackupConfig = (
  config: Partial<BackupConfig>
): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  if (config.autoBackup) {
    if (!config.frequency) {
      errors.push('يجب تحديد تكرار النسخ الاحتياطي');
    }
    if (!config.time) {
      errors.push('يجب تحديد وقت النسخ الاحتياطي');
    }
  }

  if (config.retentionDays !== undefined && config.retentionDays < 1) {
    errors.push('يجب أن تكون مدة الاحتفاظ يوم واحد على الأقل');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};
