import { State, Action } from './employeeContextTypes';

export function employeeReducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_EMPLOYEES':
      return {
        ...state,
        employees: action.payload
      };

    case 'ADD_EMPLOYEE':
      return {
        ...state,
        employees: [...state.employees, action.payload]
      };

    case 'UPDATE_EMPLOYEE':
      return {
        ...state,
        employees: state.employees.map(emp =>
          emp.id === action.payload.id
            ? { ...emp, ...action.payload.data }
            : emp
        )
      };

    case 'DELETE_EMPLOYEE':
      return {
        ...state,
        employees: state.employees.filter(emp => emp.id !== action.payload)
      };

    case 'SET_DEPARTMENTS':
      return {
        ...state,
        departments: action.payload
      };

    case 'ADD_DEPARTMENT':
      return {
        ...state,
        departments: [...state.departments, action.payload]
      };

    case 'UPDATE_DEPARTMENT':
      return {
        ...state,
        departments: state.departments.map(dept =>
          dept.id === action.payload.id
            ? { ...dept, ...action.payload.data }
            : dept
        )
      };

    case 'SET_POSITIONS':
      return {
        ...state,
        positions: action.payload
      };

    case 'ADD_POSITION':
      return {
        ...state,
        positions: [...state.positions, action.payload]
      };

    case 'UPDATE_POSITION':
      return {
        ...state,
        positions: state.positions.map(pos =>
          pos.id === action.payload.id
            ? { ...pos, ...action.payload.data }
            : pos
        )
      };

    case 'ADD_PAYROLL_RECORD':
      return {
        ...state,
        payrollRecords: [...state.payrollRecords, action.payload]
      };

    case 'UPDATE_PAYROLL_STATUS':
      return {
        ...state,
        payrollRecords: state.payrollRecords.map(record =>
          record.id === action.payload.id
            ? { ...record, status: action.payload.status }
            : record
        )
      };

    case 'PROCESS_PAYROLL':
      return {
        ...state,
        payrollRecords: state.payrollRecords.map(record =>
          record.id === action.payload.id
            ? {
                ...record,
                status: 'processed',
                processedBy: action.payload.processedBy,
                processedAt: new Date().toISOString()
              }
            : record
        )
      };

    case 'MARK_PAYROLL_PAID':
      return {
        ...state,
        payrollRecords: state.payrollRecords.map(record =>
          record.id === action.payload.id
            ? {
                ...record,
                status: 'paid',
                paidBy: action.payload.paidBy,
                paidAt: new Date().toISOString()
              }
            : record
        )
      };

    case 'ADD_ADVANCE':
      return {
        ...state,
        advances: [...state.advances, action.payload.advance],
        advanceInstallments: [...state.advanceInstallments, ...action.payload.installments]
      };

    case 'UPDATE_ADVANCE':
      return {
        ...state,
        advances: state.advances.map(advance =>
          advance.id === action.payload.id
            ? { ...advance, ...action.payload }
            : advance
        )
      };

    case 'DELETE_ADVANCE':
      return {
        ...state,
        advances: state.advances.filter(advance => advance.id !== action.payload),
        advanceInstallments: state.advanceInstallments.filter(
          installment => installment.advanceId !== action.payload
        )
      };

    case 'UPDATE_ADVANCE_INSTALLMENT':
      return {
        ...state,
        advanceInstallments: state.advanceInstallments.map(installment =>
          installment.id === action.payload.id
            ? { ...installment, ...action.payload }
            : installment
        )
      };

    case 'ADD_LEAVE_REQUEST':
      return {
        ...state,
        leaveRequests: [...state.leaveRequests, action.payload]
      };

    case 'UPDATE_LEAVE_REQUEST':
      return {
        ...state,
        leaveRequests: state.leaveRequests.map(request =>
          request.id === action.payload.id
            ? { ...request, ...action.payload.data }
            : request
        )
      };

    case 'ADD_ATTENDANCE_RECORD':
      return {
        ...state,
        attendanceRecords: [...state.attendanceRecords, action.payload]
      };

    case 'UPDATE_ATTENDANCE':
      return {
        ...state,
        attendanceRecords: state.attendanceRecords.map(record =>
          record.id === action.payload.id
            ? { ...record, ...action.payload.data }
            : record
        )
      };

    case 'ADD_NOTIFICATION':
      return {
        ...state,
        notifications: [action.payload, ...state.notifications]
      };

    case 'MARK_NOTIFICATION_READ':
      return {
        ...state,
        notifications: state.notifications.map(notification =>
          notification.id === action.payload
            ? { ...notification, status: 'read' }
            : notification
        )
      };

    case 'CLEAR_NOTIFICATIONS':
      return {
        ...state,
        notifications: []
      };

    case 'UPDATE_SETTINGS':
      return {
        ...state,
        settings: { ...state.settings, ...action.payload }
      };

    case 'SET_ERROR':
      return {
        ...state,
        error: action.payload
      };

    case 'CLEAR_ERROR':
      return {
        ...state,
        error: null
      };

    case 'SET_LOADING':
      return {
        ...state,
        loading: action.payload
      };

    default:
      return state;
  }
}
