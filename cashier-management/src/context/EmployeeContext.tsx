import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { employeeReducer } from './employeeReducer';
import { State, Action, initialState } from './employeeContextTypes';

interface EmployeeContextType {
  state: State;
  dispatch: React.Dispatch<Action>;
}

const EmployeeContext = createContext<EmployeeContextType | undefined>(undefined);

export const useEmployee = () => {
  const context = useContext(EmployeeContext);
  if (!context) {
    throw new Error('useEmployee must be used within an EmployeeProvider');
  }
  return context;
};

interface EmployeeProviderProps {
  children: React.ReactNode;
}

export const EmployeeProvider: React.FC<EmployeeProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(employeeReducer, initialState);

  // Load saved state from localStorage on mount
  useEffect(() => {
    const savedState = localStorage.getItem('employeeState');
    if (savedState) {
      try {
        const parsedState = JSON.parse(savedState);
        // Load each section of the state separately to handle potential schema changes
        if (parsedState.employees) {
          dispatch({ type: 'SET_EMPLOYEES', payload: parsedState.employees });
        }
        if (parsedState.departments) {
          dispatch({ type: 'SET_DEPARTMENTS', payload: parsedState.departments });
        }
        if (parsedState.positions) {
          dispatch({ type: 'SET_POSITIONS', payload: parsedState.positions });
        }
        if (parsedState.settings) {
          dispatch({ type: 'UPDATE_SETTINGS', payload: parsedState.settings });
        }
        // Load advances and installments
        if (parsedState.advances) {
          parsedState.advances.forEach((advance: any) => {
            const installments = parsedState.advanceInstallments.filter(
              (i: any) => i.advanceId === advance.id
            );
            dispatch({
              type: 'ADD_ADVANCE',
              payload: { advance, installments }
            });
          });
        }
        // Load notifications that aren't too old (last 30 days)
        if (parsedState.notifications) {
          const thirtyDaysAgo = new Date();
          thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
          const recentNotifications = parsedState.notifications.filter(
            (n: any) => new Date(n.createdAt) > thirtyDaysAgo
          );
          recentNotifications.forEach((notification: any) => {
            dispatch({ type: 'ADD_NOTIFICATION', payload: notification });
          });
        }
      } catch (error) {
        console.error('Error loading saved state:', error);
        dispatch({
          type: 'SET_ERROR',
          payload: 'حدث خطأ أثناء تحميل البيانات المحفوظة'
        });
      }
    }
  }, []);

  // Save state to localStorage whenever it changes
  useEffect(() => {
    try {
      localStorage.setItem('employeeState', JSON.stringify(state));
    } catch (error) {
      console.error('Error saving state:', error);
      dispatch({
        type: 'SET_ERROR',
        payload: 'حدث خطأ أثناء حفظ البيانات'
      });
    }
  }, [state]);

  // Auto-clear old notifications (older than 30 days)
  useEffect(() => {
    const interval = setInterval(() => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const oldNotifications = state.notifications.filter(
        n => new Date(n.createdAt) <= thirtyDaysAgo
      );
      
      if (oldNotifications.length > 0) {
        dispatch({ type: 'CLEAR_NOTIFICATIONS' });
        const recentNotifications = state.notifications.filter(
          n => new Date(n.createdAt) > thirtyDaysAgo
        );
        recentNotifications.forEach(notification => {
          dispatch({ type: 'ADD_NOTIFICATION', payload: notification });
        });
      }
    }, 24 * 60 * 60 * 1000); // Check once per day

    return () => clearInterval(interval);
  }, [state.notifications]);

  // Auto-update advance statuses based on installments
  useEffect(() => {
    state.advances.forEach(advance => {
      if (advance.status === 'approved') {
        const advanceInstallments = state.advanceInstallments.filter(
          i => i.advanceId === advance.id
        );
        
        const allPaid = advanceInstallments.every(i => i.status === 'paid');
        const hasOverdue = advanceInstallments.some(i => i.status === 'overdue');
        
        if (allPaid) {
          dispatch({
            type: 'UPDATE_ADVANCE',
            payload: { ...advance, status: 'completed' }
          });
        } else if (hasOverdue) {
          // Add a notification for overdue installments
          dispatch({
            type: 'ADD_NOTIFICATION',
            payload: {
              id: Date.now().toString(),
              type: 'advance',
              title: 'قسط متأخر',
              message: `يوجد قسط متأخر للسلفة الخاصة بالموظف ${advance.employeeId}`,
              status: 'unread',
              createdAt: new Date().toISOString(),
              targetId: advance.id,
              targetType: 'advance'
            }
          });
        }
      }
    });
  }, [state.advances, state.advanceInstallments]);

  return (
    <EmployeeContext.Provider value={{ state, dispatch }}>
      {children}
    </EmployeeContext.Provider>
  );
};
