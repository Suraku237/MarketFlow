-- ============================================================================
-- SmartSchool — sample seed data (for local demo / evaluation only)
-- Runs once, right after schema.sql, via the MySQL container's
-- docker-entrypoint-initdb.d mechanism.
-- ============================================================================

-- Staff & students (password hashes are placeholders — real hashes come from
-- auth-service; register real demo accounts through the Week 1 API instead
-- of logging in with these rows directly).
INSERT INTO users (name, email, password_hash, role) VALUES
    ('Rayan Kwete',   'admin@smartschool.local',   '$2a$10$placeholderadminhash',   'admin'),
    ('Neil Marshall', 'teacher@smartschool.local', '$2a$10$placeholderteacherhash', 'teacher'),
    ('Ama Nti',       'ama@smartschool.local',     '$2a$10$placeholderstudent1hash', 'student'),
    ('Kofi Mensah',   'kofi@smartschool.local',    '$2a$10$placeholderstudent2hash', 'student');

-- Academic
INSERT INTO students (user_id, admission_number, date_of_birth, guardian_name, guardian_phone, enrolled_on) VALUES
    (3, 'ADM-2026-001', '2008-03-14', 'Efua Nti',    '+237670000011', '2026-01-15'),
    (4, 'ADM-2026-002', '2007-11-02', 'Yaw Mensah',  '+237670000012', '2026-01-15');

INSERT INTO courses (code, name, teacher_id, credits, fee_amount, term) VALUES
    ('MATH101', 'Algebra I',              2, 3, 25000, '2026-S2'),
    ('ENG101',  'English Composition',    2, 3, 20000, '2026-S2'),
    ('SCI101',  'Introduction to Science', 2, 4, 30000, '2026-S2');

INSERT INTO enrollments (student_id, course_id, status) VALUES
    (1, 1, 'active'),
    (2, 2, 'active');

INSERT INTO grades (enrollment_id, assessment_type, score, recorded_by) VALUES
    (1, 'quiz',       78.50, 2),
    (2, 'assignment', 85.00, 2);

-- Finance (owned by finance-service, Week 4) — one pre-existing invoice so
-- there's something to see immediately; a fresh live enrollment during the
-- evaluation demonstrates the actual RabbitMQ flow creating a new one.
INSERT INTO invoices (student_id, enrollment_id, amount, momo_reference, method, status, paid_at) VALUES
    (1, 1, 25000, 'MOMO-REF-0001', 'momo', 'paid', NOW());

-- HR / Payroll
INSERT INTO payroll_runs (period_start, period_end, status, created_by) VALUES
    (DATE_FORMAT(CURDATE(), '%Y-%m-01'), LAST_DAY(CURDATE()), 'processed', 1);

INSERT INTO payslips (payroll_run_id, staff_id, base_salary, deductions, net_pay, momo_reference, status) VALUES
    (1, 2, 150000, 15000, 135000, 'MOMO-PAY-0001', 'paid');
