import { useState } from 'react';
import styled from '@emotion/styled';
import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import { useEmployee } from '../context/EmployeeContext';
import { PayrollRecord } from '../types';
import { formatCurrency } from '../utils/payrollCalculations';
import { generatePayrollSlip } from '../utils/reportGenerator';

// ... (keep all styled components from PayrollManagementNew.tsx)

function PayrollManager() {
  const { state, dispatch } = useEmployee();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  const generatePayroll = () => {
    const newPayrollRecords = state.employees.map(employee => {
      const dailyRate = employee.basicSalary / state.settings.workingDays;
      const absenceDeduction = dailyRate * employee.absenceDays;

      // Calculate overtime based on attendance records
      const attendanceRecords = state.attendanceRecords.filter(
        record => record.employeeId === employee.id &&
        new Date(record.date).getMonth() + 1 === selectedMonth &&
        new Date(record.date).getFullYear() === selectedYear
      );

      let totalOvertimeHours = 0;
      attendanceRecords.forEach(record => {
        if (record.checkOut) {
          const checkOut = new Date(`1970-01-01T${record.checkOut}`);
          const expectedCheckOut = new Date(`1970-01-01T${state.settings.workingHours}:00`);
          if (checkOut > expectedCheckOut) {
            const diffHours = (checkOut.getTime() - expectedCheckOut.getTime()) / (1000 * 60 * 60);
            totalOvertimeHours += diffHours;
          }
        }
      });

      const overtimeRate = state.settings.overtimeRate;
      const hourlyRate = (employee.basicSalary / state.settings.workingDays) / state.settings.workingHours;
      const overtimeAmount = totalOvertimeHours * hourlyRate * overtimeRate;

      // Calculate commission (if applicable)
      const commission = {
        percentage: 0,
        amount: 0
      };

      const netSalary = employee.basicSalary + 
                       employee.monthlyIncentives + 
                       overtimeAmount + 
                       commission.amount - 
                       (absenceDeduction + employee.penalties + employee.advances);

      const payrollRecord: PayrollRecord = {
        id: Date.now() + employee.id,
        employeeId: employee.id,
        month: selectedMonth,
        year: selectedYear,
        basicSalary: employee.basicSalary,
        monthlyIncentives: employee.monthlyIncentives,
        overtime: {
          hours: totalOvertimeHours,
          rate: overtimeRate,
          amount: overtimeAmount
        },
        commission,
        absenceDays: employee.absenceDays,
        penalties: employee.penalties,
        advances: employee.advances,
        netSalary,
        status: 'pending'
      };

      dispatch({
        type: 'ADD_PAYROLL_RECORD',
        payload: payrollRecord
      });

      // Add notification
      dispatch({
        type: 'ADD_NOTIFICATION',
        payload: {
          id: Date.now(),
          type: 'payroll',
          title: 'تم إنشاء كشف راتب جديد',
          message: `تم إنشاء كشف راتب ${employee.name} لشهر ${selectedMonth}/${selectedYear}`,
          status: 'unread',
          createdAt: new Date().toISOString(),
          targetId: payrollRecord.id,
          targetType: 'payroll_record'
        }
      });

      return payrollRecord;
    });
  };

  const exportToPDF = () => {
    const doc = new jsPDF();
    
    // Add title
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.text(`كشف المرتبات - ${selectedMonth}/${selectedYear}`, 200, 20, { align: 'right' });

    // Add table
    const tableData = state.payrollRecords
      .filter(record => record.month === selectedMonth && record.year === selectedYear)
      .map(record => {
        const employee = state.employees.find(emp => emp.id === record.employeeId);
        return [
          formatCurrency(record.netSalary),
          formatCurrency(record.advances),
          formatCurrency(record.penalties),
          record.absenceDays,
          formatCurrency(record.monthlyIncentives),
          formatCurrency(record.basicSalary),
          employee?.name || ''
        ];
      });

    (doc as any).autoTable({
      head: [['صافي الراتب', 'السلف', 'الجزاءات', 'الغياب', 'الحوافز', 'الراتب الأساسي', 'اسم الموظف']],
      body: tableData,
      startY: 30,
      theme: 'grid',
      styles: {
        font: 'helvetica',
        halign: 'right',
        textColor: [0, 0, 0],
        lineWidth: 0.1
      },
      headStyles: {
        fillColor: [44, 62, 80],
        textColor: [255, 255, 255],
        fontStyle: 'bold'
      }
    });

    doc.save(`payroll-${selectedMonth}-${selectedYear}.pdf`);
  };

  const handleProcessPayroll = (id: number) => {
    dispatch({
      type: 'PROCESS_PAYROLL',
      payload: { id, processedBy: 1 } // TODO: Get from auth context
    });
  };

  const handleMarkAsPaid = (id: number) => {
    dispatch({
      type: 'MARK_PAYROLL_PAID',
      payload: { id, paidBy: 1 } // TODO: Get from auth context
    });
  };

  const handleGenerateSlip = (record: PayrollRecord) => {
    const employee = state.employees.find(emp => emp.id === record.employeeId);
    if (!employee) return;

    const doc = generatePayrollSlip(employee, record, employee.position.department);
    doc.save(`payslip-${employee.name}-${record.month}-${record.year}.pdf`);
  };

  const filteredRecords = state.payrollRecords.filter(
    record => record.month === selectedMonth && record.year === selectedYear
  );

  return (
    <PayrollContainer>
      <PayrollHeader>
        <h2>إدارة كشوف المرتبات</h2>
        <div>
          <button 
            className="btn btn-primary me-2"
            onClick={generatePayroll}
          >
            إنشاء كشف المرتبات
          </button>
          {filteredRecords.length > 0 && (
            <button 
              className="btn btn-success"
              onClick={exportToPDF}
            >
              تصدير PDF
            </button>
          )}
        </div>
      </PayrollHeader>

      <PayrollFilters>
        <div className="form-group">
          <label className="form-label">الشهر</label>
          <select
            className="form-control"
            value={selectedMonth}
            onChange={(e) => setSelectedMonth(parseInt(e.target.value))}
          >
            {Array.from({ length: 12 }, (_, i) => i + 1).map(month => (
              <option key={month} value={month}>
                {new Date(2000, month - 1).toLocaleString('ar-SA', { month: 'long' })}
              </option>
            ))}
          </select>
        </div>

        <div className="form-group">
          <label className="form-label">السنة</label>
          <select
            className="form-control"
            value={selectedYear}
            onChange={(e) => setSelectedYear(parseInt(e.target.value))}
          >
            {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map(year => (
              <option key={year} value={year}>{year}</option>
            ))}
          </select>
        </div>
      </PayrollFilters>

      {filteredRecords.length > 0 && (
        <PayrollTable>
          <table>
            <thead>
              <tr>
                <th>اسم الموظف</th>
                <th>الراتب الأساسي</th>
                <th>الحوافز</th>
                <th>العمل الإضافي</th>
                <th>الغياب</th>
                <th>الجزاءات</th>
                <th>السلف</th>
                <th>صافي الراتب</th>
                <th>الحالة</th>
                <th>الإجراءات</th>
              </tr>
            </thead>
            <tbody>
              {filteredRecords.map(record => {
                const employee = state.employees.find(emp => emp.id === record.employeeId);
                return (
                  <tr key={record.id}>
                    <td>{employee?.name}</td>
                    <td>{formatCurrency(record.basicSalary)}</td>
                    <td>{formatCurrency(record.monthlyIncentives)}</td>
                    <td>{formatCurrency(record.overtime.amount)}</td>
                    <td>{record.absenceDays} يوم</td>
                    <td>{formatCurrency(record.penalties)}</td>
                    <td>{formatCurrency(record.advances)}</td>
                    <td>{formatCurrency(record.netSalary)}</td>
                    <td>
                      <span className={`status ${record.status}`}>
                        {record.status === 'pending' ? 'قيد المعالجة' :
                         record.status === 'processed' ? 'تمت المعالجة' : 'مدفوع'}
                      </span>
                    </td>
                    <td>
                      <button
                        className="btn btn-sm btn-info me-1"
                        onClick={() => handleGenerateSlip(record)}
                      >
                        قسيمة الراتب
                      </button>
                      {record.status === 'pending' && (
                        <button
                          className="btn btn-sm btn-primary"
                          onClick={() => handleProcessPayroll(record.id)}
                        >
                          معالجة
                        </button>
                      )}
                      {record.status === 'processed' && (
                        <button
                          className="btn btn-sm btn-success"
                          onClick={() => handleMarkAsPaid(record.id)}
                        >
                          تأكيد الدفع
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </PayrollTable>
      )}
    </PayrollContainer>
  );
}

export default PayrollManager;
