export interface Advance {
  id: string;
  employeeId: string;
  amount: number;
  date: string;
  reason: string;
  installments: number; // Number of installments to repay
  remainingAmount: number;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
  approvedBy?: string;
  approvalDate?: string;
  notes?: string;
}

export interface AdvanceInstallment {
  id: string;
  advanceId: string;
  amount: number;
  dueDate: string;
  paidAmount: number;
  paidDate?: string;
  status: 'pending' | 'paid' | 'overdue';
}
