# نظام إدارة الرواتب والموظفين

A comprehensive employee and payroll management system built with React, TypeScript, and Emotion.

## Features

- 👥 Employee Management
- 💰 Payroll Processing
- ⏰ Attendance Tracking
- 📅 Leave Management
- 🏢 Department & Position Management
- 📊 Reports Generation
- 💾 Backup Management
- 🌙 Dark/Light Theme Support
- 🌐 RTL Support (Arabic)

## Tech Stack

- React 18
- TypeScript
- Emotion (Styled Components)
- React Router v6
- React Hook Form
- Yup Validation
- jsPDF for PDF Generation
- Vite for Build Tool

## Getting Started

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Build for production:
```bash
npm run build
```

## Project Structure

```
src/
├── components/          # React components
│   ├── Dashboard.tsx
│   ├── EmployeeList.tsx
│   ├── PayrollManager.tsx
│   ├── AttendanceManagement.tsx
│   ├── LeaveManagement.tsx
│   ├── DepartmentsManager.tsx
│   ├── NotificationsManager.tsx
│   ├── Settings.tsx
│   └── ...
├── context/            # React context providers
│   ├── EmployeeContext.tsx
│   └── ...
├── styles/             # Styled components and global styles
│   ├── PayrollStyles.ts
│   └── index.css
├── utils/             # Utility functions
│   ├── payrollCalculations.ts
│   ├── attendanceManagement.ts
│   ├── notificationManager.ts
│   ├── reportGenerator.ts
│   └── ...
├── types/             # TypeScript type definitions
│   └── index.ts
└── main.tsx          # Application entry point
```

## Features Details

### Employee Management
- Add, edit, and delete employees
- Track employee details, positions, and departments
- Manage employee status and basic information

### Payroll Processing
- Generate monthly payroll records
- Calculate salaries including overtime and deductions
- Process and mark payroll records as paid
- Generate payslips in PDF format

### Attendance Management
- Track daily attendance
- Record check-in and check-out times
- Calculate overtime hours
- Generate attendance reports

### Leave Management
- Process leave requests
- Track different types of leave (annual, sick, unpaid)
- Manage leave approvals
- Calculate leave balances

### Department & Position Management
- Create and manage departments
- Define positions within departments
- Track employee assignments

### Reports
- Generate various reports in PDF format
- Export data for analysis
- View historical data and trends

### System Settings
- Configure system parameters
- Manage working hours and overtime rates
- Set up backup schedules
- Customize theme and language preferences

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
