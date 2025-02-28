import React from 'react';
import ReactDOM from 'react-dom/client';
import MainApp from './components/MainApp';
import './styles/index.css';

// Add global styles for theme variables
const style = document.createElement('style');
style.textContent = `
  :root {
    /* Light theme defaults */
    --background-color: #f5f5f5;
    --card-background: #ffffff;
    --text-color: #333333;
    --text-secondary: #666666;
    --border-color: #e0e0e0;
    --hover-color: #f0f0f0;
    --input-background: #ffffff;
    --primary-color: #0d6efd;
    --success-color: #198754;
    --warning-color: #ffc107;
    --danger-color: #dc3545;
    --info-color: #0dcaf0;
    --sidebar-background: #ffffff;
  }

  /* Global styles */
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  body {
    font-family: 'Tajawal', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
      'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
      sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    background-color: var(--background-color);
    color: var(--text-color);
    direction: rtl;
  }

  /* Button styles */
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.5rem 1rem;
    font-size: 1rem;
    font-weight: 600;
    line-height: 1.5;
    border-radius: 0.25rem;
    border: 1px solid transparent;
    cursor: pointer;
    transition: all 0.15s ease-in-out;
  }

  .btn-primary {
    background-color: var(--primary-color);
    color: white;
  }

  .btn-success {
    background-color: var(--success-color);
    color: white;
  }

  .btn-warning {
    background-color: var(--warning-color);
    color: black;
  }

  .btn-danger {
    background-color: var(--danger-color);
    color: white;
  }

  .btn-info {
    background-color: var(--info-color);
    color: black;
  }

  .btn-sm {
    padding: 0.25rem 0.5rem;
    font-size: 0.875rem;
  }

  /* Form styles */
  .form-control {
    display: block;
    width: 100%;
    padding: 0.375rem 0.75rem;
    font-size: 1rem;
    line-height: 1.5;
    color: var(--text-color);
    background-color: var(--input-background);
    border: 1px solid var(--border-color);
    border-radius: 0.25rem;
    transition: border-color 0.15s ease-in-out;
  }

  .form-control:focus {
    border-color: var(--primary-color);
    outline: 0;
  }

  .form-label {
    margin-bottom: 0.5rem;
    display: inline-block;
  }

  /* Margin utilities */
  .me-1 { margin-left: 0.25rem; }
  .me-2 { margin-left: 0.5rem; }
  .me-3 { margin-left: 1rem; }
  .mb-2 { margin-bottom: 0.5rem; }
  .mb-3 { margin-bottom: 1rem; }
  .mb-4 { margin-bottom: 1.5rem; }

  /* Font imports */
  @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap');
`;

document.head.appendChild(style);

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MainApp />
  </React.StrictMode>
);
