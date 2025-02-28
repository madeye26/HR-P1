import { State, Action } from './employeeContextTypes';

export const employeeReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case 'MARK_NOTIFICATION_READ':
      return {
        ...state,
        notifications: state.notifications.map(notification =>
          notification.id === action.payload
            ? { ...notification, status: 'read' }
            : notification
        ),
      };

    case 'MARK_ALL_NOTIFICATIONS_READ':
      return {
        ...state,
        notifications: state.notifications.map(notification => ({
          ...notification,
          status: 'read',
        })),
      };

    case 'ADD_NOTIFICATION':
      return {
        ...state,
        notifications: [
          {
            ...action.payload,
            status: 'unread',
            createdAt: new Date().toISOString(),
          },
          ...state.notifications,
        ],
      };

    case 'SET_EMPLOYEES':
      return {
        ...state,
        employees: action.payload,
      };

    case 'ADD_EMPLOYEE':
      return {
        ...state,
        employees: [...state.employees, action.payload],
      };

    case 'UPDATE_EMPLOYEE':
      return {
        ...state,
        employees: state.employees.map(employee =>
          employee.id === action.payload.id
            ? { ...employee, ...action.payload.data }
            : employee
        ),
      };

    case 'DELETE_EMPLOYEE':
      return {
        ...state,
        employees: state.employees.filter(
          employee => employee.id !== action.payload
        ),
      };

    case 'ADD_ATTENDANCE_RECORD':
      return {
        ...state,
        attendanceRecords: [...state.attendanceRecords, action.payload],
      };

    case 'UPDATE_ATTENDANCE':
      return {
        ...state,
        attendanceRecords: state.attendanceRecords.map(record =>
          record.id === action.payload.id
            ? { ...record, ...action.payload.data }
            : record
        ),
      };

    case 'SET_ERROR':
      return {
        ...state,
        error: action.payload,
      };

    case 'CLEAR_ERROR':
      return {
        ...state,
        error: null,
      };

    case 'SET_LOADING':
      return {
        ...state,
        loading: action.payload,
      };

    default:
      return state;
  }
};
