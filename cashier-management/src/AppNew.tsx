import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import styled from '@emotion/styled';
import { EmployeeProvider } from './context/EmployeeContext';

// Components
import Navigation from './components/Navigation';
import Dashboard from './components/Dashboard';
import EmployeeList from './components/EmployeeList';
import PayrollManagement from './components/PayrollManagement';
import DailyReport from './components/DailyReport';
import BackupManager from './components/BackupManager';
import AttendanceManagement from './components/AttendanceManagement';
import LeaveManagement from './components/LeaveManagement';
import DepartmentsManager from './components/DepartmentsManager';
import NotificationsManager from './components/NotificationsManager';
import Settings from './components/Settings';

const AppContainer = styled.div`
  min-height: 100vh;
  background-color: var(--background-color);
  direction: rtl;
  font-family: 'Tajawal', sans-serif;
  transition: all 0.3s ease;
`;

const MainContent = styled.main`
  padding: 20px;
  margin-right: 250px; // Space for sidebar
  min-height: 100vh;
  background-color: var(--background-color);
  transition: all 0.3s ease;

  @media (max-width: 768px) {
    margin-right: 0;
    padding: 70px 15px 15px;
  }
`;

const ThemeToggle = styled.button`
  position: fixed;
  bottom: 20px;
  left: 20px;
  padding: 10px;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--primary-color);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  z-index: 1000;

  &:hover {
    transform: scale(1.1);
  }
`;

// Load CSS variables for themes
const loadThemeVariables = (isDarkMode: boolean) => {
  if (isDarkMode) {
    document.documentElement.style.setProperty('--background-color', '#1a1a1a');
    document.documentElement.style.setProperty('--card-background', '#2d2d2d');
    document.documentElement.style.setProperty('--text-color', '#ffffff');
    document.documentElement.style.setProperty('--text-secondary', '#b3b3b3');
    document.documentElement.style.setProperty('--border-color', '#404040');
    document.documentElement.style.setProperty('--hover-color', '#363636');
    document.documentElement.style.setProperty('--input-background', '#363636');
  } else {
    document.documentElement.style.setProperty('--background-color', '#f5f5f5');
    document.documentElement.style.setProperty('--card-background', '#ffffff');
    document.documentElement.style.setProperty('--text-color', '#333333');
    document.documentElement.style.setProperty('--text-secondary', '#666666');
    document.documentElement.style.setProperty('--border-color', '#e0e0e0');
    document.documentElement.style.setProperty('--hover-color', '#f0f0f0');
    document.documentElement.style.setProperty('--input-background', '#ffffff');
  }
};

function App() {
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const savedTheme = localStorage.getItem('theme');
    return savedTheme === 'dark';
  });

  useEffect(() => {
    loadThemeVariables(isDarkMode);
    localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  const toggleTheme = () => {
    setIsDarkMode(!isDarkMode);
  };

  return (
    <Router>
      <EmployeeProvider>
        <AppContainer className={isDarkMode ? 'dark-theme' : 'light-theme'}>
          <Navigation />
          <MainContent>
            <Routes>
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/employees" element={<EmployeeList />} />
              <Route path="/payroll" element={<PayrollManagement />} />
              <Route path="/attendance" element={<AttendanceManagement />} />
              <Route path="/leave" element={<LeaveManagement />} />
              <Route path="/departments" element={<DepartmentsManager />} />
              <Route path="/reports" element={<DailyReport />} />
              <Route path="/notifications" element={<NotificationsManager />} />
              <Route path="/backup" element={<BackupManager />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </MainContent>
          <ThemeToggle 
            onClick={toggleTheme} 
            title={isDarkMode ? 'تفعيل الوضع النهاري' : 'تفعيل الوضع الليلي'}
            aria-label={isDarkMode ? 'تفعيل الوضع النهاري' : 'تفعيل الوضع الليلي'}
          >
            {isDarkMode ? '🌞' : '🌙'}
          </ThemeToggle>
        </AppContainer>
      </EmployeeProvider>
    </Router>
  );
}

export default App;
