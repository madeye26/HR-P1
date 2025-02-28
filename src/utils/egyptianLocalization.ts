import { format, formatDistance, formatRelative } from 'date-fns';
import { ar } from 'date-fns/locale';

// Arabic number mapping
const arabicNumbers: { [key: string]: string } = {
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩',
};

// Arabic month names
const arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

// Arabic day names
const arabicDays = [
  'الأحد',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

/**
 * Convert numbers to Arabic numerals
 */
export const toArabicNumbers = (num: number | string): string => {
  return num.toString().replace(/[0-9]/g, (digit) => arabicNumbers[digit] || digit);
};

/**
 * Convert Arabic numerals to English numbers
 */
export const fromArabicNumbers = (str: string): string => {
  const arabicToEnglish: { [key: string]: string } = 
    Object.fromEntries(
      Object.entries(arabicNumbers).map(([k, v]) => [v, k])
    );
  
  return str.replace(/[٠-٩]/g, (digit) => arabicToEnglish[digit] || digit);
};

/**
 * Format currency in Egyptian Pounds
 */
export const formatEGP = (amount: number): string => {
  const formatted = new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);

  return formatted;
};

/**
 * Convert number to Arabic words
 */
export const numberToArabicWords = (num: number): string => {
  const units = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة'];
  const teens = ['', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'];
  const tens = ['', 'عشرة', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
  const hundreds = ['', 'مائة', 'مئتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'];
  
  if (num === 0) return 'صفر';
  
  const convertLessThanThousand = (n: number): string => {
    if (n === 0) return '';
    
    const h = Math.floor(n / 100);
    const t = Math.floor((n % 100) / 10);
    const u = n % 10;
    
    let result = '';
    
    if (h > 0) {
      result += hundreds[h] + ' ';
    }
    
    if (t === 1 && u > 0) {
      result += teens[u] + ' ';
    } else {
      if (u > 0) result += units[u] + ' ';
      if (t > 1) result += tens[t] + ' ';
    }
    
    return result.trim();
  };
  
  if (num < 1000) return convertLessThanThousand(num);
  
  const parts = [];
  let remaining = num;
  
  // Billions
  const billions = Math.floor(remaining / 1000000000);
  if (billions > 0) {
    parts.push(convertLessThanThousand(billions) + ' مليار');
    remaining %= 1000000000;
  }
  
  // Millions
  const millions = Math.floor(remaining / 1000000);
  if (millions > 0) {
    parts.push(convertLessThanThousand(millions) + ' مليون');
    remaining %= 1000000;
  }
  
  // Thousands
  const thousands = Math.floor(remaining / 1000);
  if (thousands > 0) {
    parts.push(convertLessThanThousand(thousands) + ' ألف');
    remaining %= 1000;
  }
  
  // Remainder
  if (remaining > 0) {
    parts.push(convertLessThanThousand(remaining));
  }
  
  return parts.join(' و ');
};

/**
 * Format date in Egyptian style
 */
export const formatEgyptianDate = (date: Date | string, formatStr: string = 'full'): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  
  switch (formatStr) {
    case 'full':
      return format(dateObj, 'EEEE، d MMMM yyyy', { locale: ar });
    case 'short':
      return format(dateObj, 'd/M/yyyy', { locale: ar });
    case 'month':
      return format(dateObj, 'MMMM yyyy', { locale: ar });
    case 'time':
      return format(dateObj, 'h:mm a', { locale: ar });
    case 'datetime':
      return format(dateObj, 'EEEE، d MMMM yyyy h:mm a', { locale: ar });
    default:
      return format(dateObj, formatStr, { locale: ar });
  }
};

/**
 * Format relative time in Arabic
 */
export const formatRelativeTime = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatDistance(dateObj, new Date(), {
    addSuffix: true,
    locale: ar,
  });
};

/**
 * Format relative date in Arabic
 */
export const formatRelativeDate = (date: Date | string): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return formatRelative(dateObj, new Date(), { locale: ar });
};

/**
 * Get Arabic month name
 */
export const getArabicMonth = (month: number): string => {
  return arabicMonths[month];
};

/**
 * Get Arabic day name
 */
export const getArabicDay = (day: number): string => {
  return arabicDays[day];
};

/**
 * Format phone number in Egyptian format
 */
export const formatEgyptianPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 11) {
    return `${cleaned.slice(0, 3)} ${cleaned.slice(3, 7)} ${cleaned.slice(7)}`;
  }
  return phone;
};

/**
 * Format national ID in Egyptian format
 */
export const formatEgyptianNationalId = (id: string): string => {
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length === 14) {
    return `${cleaned.slice(0, 1)} ${cleaned.slice(1, 7)} ${cleaned.slice(7, 9)} ${cleaned.slice(9)}`;
  }
  return id;
};

/**
 * Get gender from Egyptian national ID
 */
export const getGenderFromNationalId = (id: string): 'male' | 'female' | null => {
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length === 14) {
    const genderDigit = parseInt(cleaned[12]);
    if (!isNaN(genderDigit)) {
      return genderDigit % 2 === 1 ? 'male' : 'female';
    }
  }
  return null;
};

/**
 * Get birth date from Egyptian national ID
 */
export const getBirthDateFromNationalId = (id: string): Date | null => {
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length === 14) {
    const century = cleaned[0] === '2' ? '19' : '20';
    const year = century + cleaned.slice(1, 3);
    const month = cleaned.slice(3, 5);
    const day = cleaned.slice(5, 7);
    
    const date = new Date(`${year}-${month}-${day}`);
    return isNaN(date.getTime()) ? null : date;
  }
  return null;
};

/**
 * Format amount in words (for checks and official documents)
 */
export const formatAmountInWords = (amount: number): string => {
  const integer = Math.floor(amount);
  const fraction = Math.round((amount - integer) * 100);
  
  const integerWords = numberToArabicWords(integer);
  const fractionWords = fraction > 0 ? numberToArabicWords(fraction) : '';
  
  let result = `${integerWords} جنيه مصري`;
  if (fraction > 0) {
    result += ` و ${fractionWords} قرش`;
  }
  result += ' فقط لا غير';
  
  return result;
};

/**
 * Validate Egyptian national ID
 */
export const validateEgyptianNationalId = (id: string): boolean => {
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length !== 14) return false;
  
  // Check century digit (2 or 3)
  if (!['2', '3'].includes(cleaned[0])) return false;
  
  // Check birth date
  const birthDate = getBirthDateFromNationalId(cleaned);
  if (!birthDate) return false;
  
  // Check governorate code (01-27)
  const govCode = parseInt(cleaned.slice(7, 9));
  if (isNaN(govCode) || govCode < 1 || govCode > 27) return false;
  
  return true;
};

/**
 * Get governorate name from national ID
 */
export const getGovernorateFromNationalId = (id: string): string | null => {
  const governorates: { [key: string]: string } = {
    '01': 'القاهرة',
    '02': 'الإسكندرية',
    '03': 'بورسعيد',
    '04': 'السويس',
    // Add more governorates as needed
  };
  
  const cleaned = id.replace(/\D/g, '');
  if (cleaned.length === 14) {
    const govCode = cleaned.slice(7, 9);
    return governorates[govCode] || null;
  }
  return null;
};
