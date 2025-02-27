import styled from '@emotion/styled';

export const PayrollContainer = styled.div`
  padding: 24px;
  background-color: #f5f5f5;
  min-height: 100vh;
`;

export const PayrollHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
`;

export const PayrollFilters = styled.div`
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  padding: 16px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
`;

export const PayrollTable = styled.div`
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow-x: auto;

  table {
    width: 100%;
    border-collapse: collapse;
    
    th, td {
      padding: 12px;
      text-align: right;
      border-bottom: 1px solid #eee;
    }

    th {
      background-color: #f8f9fa;
      font-weight: 600;
    }

    tr:hover {
      background-color: #f8f9fa;
    }

    .status {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.875rem;

      &.pending {
        background-color: #fff3cd;
        color: #856404;
      }

      &.processed {
        background-color: #d4edda;
        color: #155724;
      }

      &.paid {
        background-color: #cce5ff;
        color: #004085;
      }
    }
  }
`;

export const FormGroup = styled.div`
  display: flex;
  flex-direction: column;
  gap: 8px;

  label {
    font-weight: 500;
  }

  select {
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    min-width: 200px;
  }
`;

export const ButtonGroup = styled.div`
  display: flex;
  gap: 8px;
  align-items: center;
`;
