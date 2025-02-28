import { useState } from 'react';
import styled from '@emotion/styled';
import { useEmployee } from '../context/EmployeeContext';
import { Employee } from '../types';
import { formatCurrency } from '../utils/payrollCalculations';

const EmployeeCard = styled.div`
  background: var(--card-background);
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
`;

const EmployeeHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
`;

const SalaryDetails = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
`;

const DetailItem = styled.div`
  padding: 10px;
  background: var(--hover-color);
  border-radius: 4px;
  
  label {
    display: block;
    font-size: 0.875rem;
    color: var(--text-secondary);
    margin-bottom: 0.25rem;
  }
  
  span {
    font-weight: 600;
    color: var(--text-color);
  }
`;

const NetSalary = styled.div<{ amount: number }>`
  text-align: center;
  padding: 15px;
  background: ${props => props.amount >= 0 ? 'var(--success-color)' : 'var(--danger-color)'};
  color: white;
  border-radius: 4px;
  margin-top: 1rem;
  font-weight: bold;
`;

function EmployeeList() {
  const { state, dispatch } = useEmployee();
  const [searchTerm, setSearchTerm] = useState('');

  const calculateDailyRate = (basicSalary: number): number => {
    return basicSalary / 30; // Assuming 30 days per month
  };

  const calculateNetSalary = (employee: Employee): number => {
    const dailyRate = calculateDailyRate(employee.basicSalary);
    const absenceDeduction = dailyRate * employee.absenceDays;
    
    return (
      employee.basicSalary +
      employee.monthlyIncentives -
      (absenceDeduction + employee.penalties + employee.advances)
    );
  };

  const handleUpdateEmployee = (id: number, data: Partial<Employee>) => {
    dispatch({
      type: 'UPDATE_EMPLOYEE',
      payload: { id, data }
    });
  };

  const filteredEmployees = state.employees.filter(employee =>
    employee.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      <div className="mb-4">
        <input
          type="text"
          className="form-control"
          placeholder="البحث عن موظف..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {filteredEmployees.map(employee => (
        <EmployeeCard key={employee.id}>
          <EmployeeHeader>
            <h3>{employee.name}</h3>
            <button 
              className="btn btn-primary"
              onClick={() => {
                // TODO: Implement edit functionality
              }}
            >
              تعديل البيانات
            </button>
          </EmployeeHeader>

          <SalaryDetails>
            <DetailItem>
              <label>الراتب الأساسي</label>
              <span>{formatCurrency(employee.basicSalary)}</span>
            </DetailItem>
            <DetailItem>
              <label>الحوافز الشهرية</label>
              <span>{formatCurrency(employee.monthlyIncentives)}</span>
            </DetailItem>
            <DetailItem>
              <label>عدد أيام الغياب</label>
              <span>{employee.absenceDays} يوم</span>
            </DetailItem>
            <DetailItem>
              <label>الجزاءات</label>
              <span>{formatCurrency(employee.penalties)}</span>
            </DetailItem>
            <DetailItem>
              <label>السلف</label>
              <span>{formatCurrency(employee.advances)}</span>
            </DetailItem>
            <DetailItem>
              <label>معدل اليوم</label>
              <span>{formatCurrency(calculateDailyRate(employee.basicSalary))}</span>
            </DetailItem>
          </SalaryDetails>

          <NetSalary amount={calculateNetSalary(employee)}>
            صافي الراتب: {formatCurrency(calculateNetSalary(employee))}
          </NetSalary>
        </EmployeeCard>
      ))}
    </div>
  );
}

export default EmployeeList;
