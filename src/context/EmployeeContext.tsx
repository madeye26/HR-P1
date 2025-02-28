import React, { createContext, useContext, useReducer } from 'react';
import { employeeReducer } from './employeeReducer';
import { initialState } from './employeeContextTypes';
import { Employee, Notification } from '../types';

interface EmployeeContextType {
  state: typeof initialState;
  addEmployee: (employee: Employee) => void;
  updateEmployee: (id: string, data: Partial<Employee>) => void;
  deleteEmployee: (id: string) => void;
  addNotification: (notification: Omit<Notification, 'status' | 'createdAt'>) => void;
  markNotificationAsRead: (id: string) => void;
  markAllNotificationsAsRead: () => void;
  setError: (error: string) => void;
  clearError: () => void;
  setLoading: (loading: boolean) => void;
}

const EmployeeContext = createContext<EmployeeContextType | undefined>(undefined);

export const EmployeeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(employeeReducer, initialState);

  const addEmployee = (employee: Employee) => {
    dispatch({ type: 'ADD_EMPLOYEE', payload: employee });
  };

  const updateEmployee = (id: string, data: Partial<Employee>) => {
    dispatch({ type: 'UPDATE_EMPLOYEE', payload: { id, data } });
  };

  const deleteEmployee = (id: string) => {
    dispatch({ type: 'DELETE_EMPLOYEE', payload: id });
  };

  const addNotification = (notification: Omit<Notification, 'status' | 'createdAt'>) => {
    dispatch({ type: 'ADD_NOTIFICATION', payload: notification });
  };

  const markNotificationAsRead = (id: string) => {
    dispatch({ type: 'MARK_NOTIFICATION_READ', payload: id });
  };

  const markAllNotificationsAsRead = () => {
    dispatch({ type: 'MARK_ALL_NOTIFICATIONS_READ' });
  };

  const setError = (error: string) => {
    dispatch({ type: 'SET_ERROR', payload: error });
  };

  const clearError = () => {
    dispatch({ type: 'CLEAR_ERROR' });
  };

  const setLoading = (loading: boolean) => {
    dispatch({ type: 'SET_LOADING', payload: loading });
  };

  const value = {
    state,
    addEmployee,
    updateEmployee,
    deleteEmployee,
    addNotification,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    setError,
    clearError,
    setLoading,
  };

  return (
    <EmployeeContext.Provider value={value}>
      {children}
    </EmployeeContext.Provider>
  );
};

export const useEmployee = () => {
  const context = useContext(EmployeeContext);
  if (context === undefined) {
    throw new Error('useEmployee must be used within an EmployeeProvider');
  }
  return context;
};
