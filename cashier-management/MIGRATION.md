# Migration Guide

This guide explains how to migrate from the old project structure to the new TypeScript-based setup.

## Prerequisites

1. Make sure you have committed or backed up your current work
2. Ensure you have Node.js and npm installed
3. Make sure you have bash shell available (Git Bash on Windows)

## Migration Steps

1. Make the migration script executable:
```bash
chmod +x migrate.sh
```

2. Run the migration script:
```bash
./migrate.sh
```

The script will:
- Create a backup of your original configuration files
- Move them to a 'backup' directory
- Rename and move the new configuration files into place
- Clean up old component files
- Install the new dependencies

## Post-Migration Steps

1. Verify the migration was successful:
```bash
npm run dev
```

2. Check that the application runs without errors

3. Test the main features:
   - Employee management
   - Payroll processing
   - Attendance tracking
   - Leave management
   - Department management
   - Reports generation
   - Theme switching
   - RTL support

## Troubleshooting

If you encounter any issues:

1. Check the backup directory for your original files
2. Review the console for any error messages
3. Verify all dependencies were installed correctly
4. Check that all TypeScript types are properly defined

## Rolling Back

If you need to roll back to the previous version:

1. Stop any running development servers
2. Delete the new configuration files:
```bash
rm package.json tsconfig.json tsconfig.node.json vite.config.ts .eslintrc.json
```

3. Restore the backup files:
```bash
mv backup/* .
```

4. Reinstall dependencies:
```bash
npm install
```

## New Features

The migration adds several new features:

1. Full TypeScript support
2. Improved ESLint configuration
3. Better type checking
4. Enhanced development experience
5. Improved build process
6. Better code organization
7. Enhanced component structure
8. Improved state management
9. Better form handling
10. Enhanced PDF generation

## File Structure Changes

The migration reorganizes the project structure:

```
src/
├── components/          # React components
├── context/            # React context providers
├── styles/             # Styled components
├── utils/             # Utility functions
└── types/             # TypeScript types
```

## Questions?

If you have any questions or encounter issues, please:

1. Check the console for error messages
2. Review the TypeScript errors in your editor
3. Check the README.md for more details
4. Open an issue in the repository

Remember to commit your changes regularly and test thoroughly after the migration.
