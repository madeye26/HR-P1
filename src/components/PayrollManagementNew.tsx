import { useState } from 'react';
import styled from '@emotion/styled';
import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import { useEmployee } from '../context/EmployeeContext';
import { PayrollRecord } from '../types';
import { formatCurrency } from '../utils/payrollCalculations';
import { generatePayrollSlip } from '../utils/reportGenerator';

const PayrollContainer = styled.div`
  background: var(--card-background);
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
`;

const PayrollHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
`;

const PayrollFilters = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
`;

const PayrollTable = styled.div`
  overflow-x: auto;
  margin-bottom: 2rem;

  table {
    width: 100%;
    border-collapse: collapse;
    
    th, td {
      padding: 12px;
      text-align: right;
      border-bottom: 1px solid var(--border-color);
    }

    th {
      background-color: var(--primary-color);
      color: white;
    }

    tr:nth-of-type(even) {
      background-color: var(--hover-color);
    }

    .status {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.875rem;

      &.pending { background-color: var(--warning-color); }
      &.processed { background-color: var(--info-color); }
      &.paid { background-color: var(--success-color); }
    }
  }
`;

function PayrollManagement() {
  const { state, dispatch } = useEmployee();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  const generatePayroll = () => {
    const newPayrollRecords = state.employees.map(employee => {
      const dailyRate = employee.basicSalary / state.settings.workingDays;
      const absenceDeduction = dailyRate * employee.absenceDays;
      const netSalary = employee.basicSalary + employee.monthlyIncentives - (absenceDeduction + employee.penalties + employee.advances);

      const payrollRecord: PayrollRecord = {
        id: Date.now() + employee.id,
        employeeId: employee.id,
        month: selectedMonth,
        year: selectedYear,
        basicSalary: employee.basicSalary,
        monthlyIncentives: employee.monthlyIncentives,
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

export default PayrollManagement;
