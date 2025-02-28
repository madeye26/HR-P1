import { useState } from 'react';
import styled from '@emotion/styled';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { useEmployee } from '../context/EmployeeContext';
import { departmentSchema, positionSchema } from '../utils/validationSchemas';
import { Department, Position } from '../types';

const Container = styled.div`
  background: var(--card-background);
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
`;

const TabContainer = styled.div`
  margin-bottom: 2rem;
`;

const TabButton = styled.button<{ active: boolean }>`
  padding: 10px 20px;
  margin-left: 10px;
  border: none;
  border-radius: 4px;
  background-color: ${props => props.active ? 'var(--primary-color)' : '#fff'};
  color: ${props => props.active ? '#fff' : 'var(--primary-color)'};
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    background-color: ${props => props.active ? 'var(--primary-color)' : '#e9ecef'};
  }
`;

const Form = styled.form`
  margin-bottom: 2rem;
`;

const FormGroup = styled.div`
  margin-bottom: 1rem;

  label {
    display: block;
    margin-bottom: 0.5rem;
  }

  input, select, textarea {
    width: 100%;
    padding: 8px;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    background-color: var(--input-background);
    color: var(--text-color);

    &:focus {
      outline: none;
      border-color: var(--primary-color);
    }
  }

  .error {
    color: var(--danger-color);
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
`;

const Card = styled.div`
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 15px;
  position: relative;

  h3 {
    margin: 0 0 10px 0;
    color: var(--primary-color);
  }

  p {
    margin: 5px 0;
    color: var(--text-color);
  }

  .actions {
    position: absolute;
    top: 15px;
    left: 15px;
    display: flex;
    gap: 5px;
  }

  .positions {
    margin-top: 10px;
    padding-top: 10px;
    border-top: 1px solid var(--border-color);
  }
`;

interface DepartmentFormInputs {
  name: string;
  description?: string;
}

interface PositionFormInputs {
  title: string;
  departmentId: string;
  description?: string;
}

function DepartmentManagement() {
  const { state, dispatch } = useEmployee();
  const [activeTab, setActiveTab] = useState<'departments' | 'positions'>('departments');
  const [editingId, setEditingId] = useState<number | null>(null);

  const departmentForm = useForm<DepartmentFormInputs>({
    resolver: yupResolver(departmentSchema)
  });

  const positionForm = useForm<PositionFormInputs>({
    resolver: yupResolver(positionSchema)
  });

  const handleDepartmentSubmit = (data: DepartmentFormInputs) => {
    if (editingId) {
      dispatch({
        type: 'UPDATE_DEPARTMENT',
        payload: {
          id: editingId,
          data: {
            name: data.name,
            description: data.description
          }
        }
      });
    } else {
      const newDepartment: Department = {
        id: Date.now(),
        name: data.name,
        description: data.description
      };
      dispatch({ type: 'ADD_DEPARTMENT', payload: newDepartment });
    }

    departmentForm.reset();
    setEditingId(null);
  };

  const handlePositionSubmit = (data: PositionFormInputs) => {
    const department = state.departments.find(d => d.id === Number(data.departmentId));
    if (!department) return;

    if (editingId) {
      dispatch({
        type: 'UPDATE_POSITION',
        payload: {
          id: editingId,
          data: {
            title: data.title,
            department,
            description: data.description
          }
        }
      });
    } else {
      const newPosition: Position = {
        id: Date.now(),
        title: data.title,
        department,
        description: data.description
      };
      dispatch({ type: 'ADD_POSITION', payload: newPosition });
    }

    positionForm.reset();
    setEditingId(null);
  };

  const handleEdit = (type: 'department' | 'position', id: number) => {
    setEditingId(id);
    if (type === 'department') {
      const department = state.departments.find(d => d.id === id);
      if (department) {
        departmentForm.reset({
          name: department.name,
          description: department.description
        });
      }
    } else {
      const position = state.positions.find(p => p.id === id);
      if (position) {
        positionForm.reset({
          title: position.title,
          departmentId: String(position.department.id),
          description: position.description
        });
      }
    }
  };

  return (
    <Container>
      <h1>إدارة الأقسام والوظائف</h1>

      <TabContainer>
        <TabButton
          active={activeTab === 'departments'}
          onClick={() => setActiveTab('departments')}
        >
          الأقسام
        </TabButton>
        <TabButton
          active={activeTab === 'positions'}
          onClick={() => setActiveTab('positions')}
        >
          المسميات الوظيفية
        </TabButton>
      </TabContainer>

      {activeTab === 'departments' ? (
        <>
          <Form onSubmit={departmentForm.handleSubmit(handleDepartmentSubmit)}>
            <FormGroup>
              <label>اسم القسم</label>
              <input {...departmentForm.register('name')} />
              {departmentForm.formState.errors.name && (
                <span className="error">{departmentForm.formState.errors.name.message}</span>
              )}
            </FormGroup>

            <FormGroup>
              <label>الوصف</label>
              <textarea {...departmentForm.register('description')} rows={3} />
              {departmentForm.formState.errors.description && (
                <span className="error">{departmentForm.formState.errors.description.message}</span>
              )}
            </FormGroup>

            <button type="submit" className="btn btn-primary">
              {editingId ? 'تحديث القسم' : 'إضافة قسم جديد'}
            </button>
            {editingId && (
              <button
                type="button"
                className="btn btn-secondary mr-2"
                onClick={() => {
                  setEditingId(null);
                  departmentForm.reset();
                }}
              >
                إلغاء
              </button>
            )}
          </Form>

          <Grid>
            {state.departments.map(department => (
              <Card key={department.id}>
                <div className="actions">
                  <button
                    className="btn btn-sm btn-primary"
                    onClick={() => handleEdit('department', department.id)}
                  >
                    تعديل
                  </button>
                </div>
                <h3>{department.name}</h3>
                {department.description && <p>{department.description}</p>}
                <div className="positions">
                  <strong>الوظائف:</strong>
                  {state.positions
                    .filter(pos => pos.department.id === department.id)
                    .map(pos => (
                      <p key={pos.id}>• {pos.title}</p>
                    ))
                  }
                </div>
              </Card>
            ))}
          </Grid>
        </>
      ) : (
        <>
          <Form onSubmit={positionForm.handleSubmit(handlePositionSubmit)}>
            <FormGroup>
              <label>المسمى الوظيفي</label>
              <input {...positionForm.register('title')} />
              {positionForm.formState.errors.title && (
                <span className="error">{positionForm.formState.errors.title.message}</span>
              )}
            </FormGroup>

            <FormGroup>
              <label>القسم</label>
              <select {...positionForm.register('departmentId')}>
                <option value="">اختر القسم</option>
                {state.departments.map(dept => (
                  <option key={dept.id} value={dept.id}>{dept.name}</option>
                ))}
              </select>
              {positionForm.formState.errors.departmentId && (
                <span className="error">{positionForm.formState.errors.departmentId.message}</span>
              )}
            </FormGroup>

            <FormGroup>
              <label>الوصف</label>
              <textarea {...positionForm.register('description')} rows={3} />
              {positionForm.formState.errors.description && (
                <span className="error">{positionForm.formState.errors.description.message}</span>
              )}
            </FormGroup>

            <button type="submit" className="btn btn-primary">
              {editingId ? 'تحديث المسمى الوظيفي' : 'إضافة مسمى وظيفي جديد'}
            </button>
            {editingId && (
              <button
                type="button"
                className="btn btn-secondary mr-2"
                onClick={() => {
                  setEditingId(null);
                  positionForm.reset();
                }}
              >
                إلغاء
              </button>
            )}
          </Form>

          <Grid>
            {state.positions.map(position => (
              <Card key={position.id}>
                <div className="actions">
                  <button
                    className="btn btn-sm btn-primary"
                    onClick={() => handleEdit('position', position.id)}
                  >
                    تعديل
                  </button>
                </div>
                <h3>{position.title}</h3>
                <p>القسم: {position.department.name}</p>
                {position.description && <p>{position.description}</p>}
              </Card>
            ))}
          </Grid>
        </>
      )}
    </Container>
  );
}

export default DepartmentManagement;
