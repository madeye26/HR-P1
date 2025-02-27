import * as yup from 'yup';

export const departmentSchema = yup.object().shape({
  name: yup
    .string()
    .required('اسم القسم مطلوب')
    .min(2, 'اسم القسم يجب أن يكون حرفين على الأقل')
    .max(50, 'اسم القسم يجب أن لا يتجاوز 50 حرف'),
  
  description: yup
    .string()
    .max(200, 'الوصف يجب أن لا يتجاوز 200 حرف')
    .optional()
});

export const positionFormSchema = yup.object().shape({
  title: yup
    .string()
    .required('المسمى الوظيفي مطلوب')
    .min(2, 'المسمى الوظيفي يجب أن يكون حرفين على الأقل')
    .max(50, 'المسمى الوظيفي يجب أن لا يتجاوز 50 حرف'),
  
  departmentId: yup
    .string()
    .required('القسم مطلوب'),
  
  description: yup
    .string()
    .max(200, 'الوصف يجب أن لا يتجاوز 200 حرف')
    .optional()
});

// Keep other schemas unchanged
export const employeeSchema = yup.object().shape({
  // ... existing employee schema
});

export const leaveRequestSchema = yup.object().shape({
  // ... existing leave request schema
});

export const attendanceSchema = yup.object().shape({
  // ... existing attendance schema
});
