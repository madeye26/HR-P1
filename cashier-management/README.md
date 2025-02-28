# نظام إدارة المحاسبة (Cashier Management System)

## Overview

A comprehensive management system for cashiers and retail operations, providing tools for sales, inventory, employee management, and more. The system is built with a modular architecture using shell scripts for management tasks and a React/TypeScript frontend for the user interface.

## Features

### Sales & Customer Management
- Sales recording and tracking
- Customer database management
- Loyalty program management
- Sales reports and analytics

### Inventory & Purchase Management
- Inventory tracking
- Purchase order management
- Supplier management
- Stock alerts and reports

### Employee & HR Management
- Employee records management
- Attendance tracking
- Leave management
- Payroll processing
- Department management

### System Management
- User access control
- System configuration
- Backup management
- Log management
- Cache management
- Task scheduling

## Directory Structure

```
cashier-management/
├── data/               # Data storage
│   ├── customers/
│   ├── employees/
│   ├── inventory/
│   ├── sales/
│   └── ...
├── reports/            # Generated reports
├── logs/              # System logs
├── backups/           # System backups
├── templates/         # Document templates
└── src/              # Frontend source code
```

## Management Scripts

### Main Scripts
- `manage.sh` - Main management interface
- `sales.sh` - Sales management
- `customers.sh` - Customer management
- `inventory.sh` - Inventory management
- `purchase.sh` - Purchase order management
- `suppliers.sh` - Supplier management

### Employee Management
- `employees.sh` - Employee management
- `attendance.sh` - Attendance management
- `leave.sh` - Leave management
- `payroll.sh` - Payroll management
- `departments.sh` - Department management

### System Management
- `users.sh` - User management
- `config.sh` - Configuration management
- `backup.sh` - Backup management
- `logs.sh` - Log management
- `cache.sh` - Cache management
- `tasks.sh` - Task management
- `notify.sh` - Notification management
- `report.sh` - Report generation

### Development Tools
- `init.sh` - System initialization
- `deps.sh` - Dependency management
- `lint.sh` - Code linting
- `ci.sh` - Continuous integration
- `git.sh` - Git operations

## Usage

1. Initialize the system:
   ```bash
   ./init.sh
   ```

2. Launch the management interface:
   ```bash
   ./manage.sh
   ```

3. Access specific functionality directly:
   ```bash
   ./sales.sh      # Sales management
   ./inventory.sh  # Inventory management
   ./employees.sh  # Employee management
   # etc...
   ```

## Data Management

### Sales Data
- Sales transactions are stored in JSON format
- Each sale includes customer info, items, payments
- Daily reports are automatically generated

### Customer Data
- Customer profiles with contact information
- Purchase history tracking
- Loyalty points management

### Inventory Data
- Product catalog with details and pricing
- Stock levels and movement tracking
- Automatic reorder alerts

### Employee Data
- Employee profiles and contracts
- Attendance and leave records
- Payroll calculations and history

## Reports

The system generates various reports:
- Daily sales reports
- Inventory status reports
- Employee attendance reports
- Payroll reports
- Customer activity reports
- System audit reports

## Backup and Recovery

Regular backups are performed for:
- Transaction data
- Customer records
- Inventory data
- Employee records
- System configuration

## Security

- User authentication and authorization
- Role-based access control
- Activity logging and auditing
- Secure data storage
- Regular security updates

## Configuration

System configuration is managed through:
- Environment variables
- Configuration files
- User preferences
- System settings

## Development

### Requirements
- Node.js
- npm/yarn
- Git
- bash shell

### Setup Development Environment
1. Clone the repository
2. Run `./init.sh` to initialize
3. Install dependencies with `./deps.sh`
4. Start development server with `./dev.sh`

### Contributing
1. Create a feature branch
2. Make changes
3. Run tests and linting
4. Submit pull request

## Support

For support and bug reports:
1. Check the documentation
2. Review system logs
3. Contact system administrator

## License

This system is proprietary and confidential.
All rights reserved.
