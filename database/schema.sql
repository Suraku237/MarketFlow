-- ============================================================================
-- SmartSchool — Week 2: Database Design & Management
-- Combined relational schema (MySQL 8 dialect)
--
-- Modules covered (matches the exam's Academic / Finance / HR split):
--   1. ACADEMIC -> students, courses, enrollments, grades
--   2. FINANCE  -> invoices (owned by finance-service, Week 4)
--   3. HR       -> users (shared with auth-service), payroll_runs, payslips
--
-- Design notes:
--   * Fixed value-sets (role, status, assessment_type, method) use native
--     MySQL ENUM types instead of CHECK constraints.
--   * Money columns use DECIMAL(10,2), not FLOAT/REAL, to avoid rounding
--     error on currency values.
--   * This file is only ever run once, by the MySQL container's own
--     docker-entrypoint-initdb.d mechanism against a freshly-created empty
--     data volume — so statements are plain CREATE TABLE, not
--     "IF NOT EXISTS": on a from-scratch container this always runs clean.
--   * Every table is in Third Normal Form (3NF): each column depends on the
--     whole primary key and nothing but the key (no repeating groups, no
--     transitive dependencies — e.g. a course's fee lives only in `courses`,
--     never copied into `enrollments`; `invoices.amount` is kept
--     deliberately as a *price snapshot at enrollment time*, which is not a
--     3NF violation since it represents a historical fact, not a duplicate
--     of the current `courses.fee_amount`).
--   * `students` is a separate table, 1:1 with `users`, rather than bolting
--     academic-only columns onto `users` — mirrors the existing design
--     principle of keeping auth identity (login/role) separate from
--     domain profile data. There is no separate `teachers` table: a teacher
--     is just a `users` row with role='teacher'; `courses.teacher_id` and
--     `grades.recorded_by` reference `users.id` directly, the same way
--     `payslips.staff_id` already does.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SHARED: users (staff / auth-service identities; also referenced by payroll)
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('admin', 'teacher', 'student') NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 1: ACADEMIC
-- ----------------------------------------------------------------------------
CREATE TABLE students (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id          INT UNSIGNED NOT NULL UNIQUE,
    admission_number VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth    DATE,
    guardian_name    VARCHAR(255),
    guardian_phone   VARCHAR(50),
    enrolled_on      DATE NOT NULL,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE courses (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code       VARCHAR(20)  NOT NULL UNIQUE,
    name       VARCHAR(255) NOT NULL,
    teacher_id INT UNSIGNED,
    credits    INT NOT NULL DEFAULT 3 CHECK (credits > 0),
    fee_amount DECIMAL(10,2) NOT NULL CHECK (fee_amount >= 0),
    term       VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_courses_teacher FOREIGN KEY (teacher_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id  INT UNSIGNED NOT NULL,
    course_id   INT UNSIGNED NOT NULL,
    status      ENUM('active', 'completed', 'dropped') NOT NULL DEFAULT 'active',
    enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_enrollment_student_course (student_id, course_id),
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_enrollments_course  FOREIGN KEY (course_id)  REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE grades (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id   INT UNSIGNED NOT NULL,
    assessment_type ENUM('quiz', 'assignment', 'midterm', 'final') NOT NULL,
    score           DECIMAL(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    recorded_by     INT UNSIGNED,
    recorded_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
    CONSTRAINT fk_grades_recorder   FOREIGN KEY (recorded_by)   REFERENCES users(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 2: FINANCE (owned by finance-service, Week 4)
-- ----------------------------------------------------------------------------
CREATE TABLE invoices (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id     INT UNSIGNED NOT NULL,
    enrollment_id  INT UNSIGNED NOT NULL UNIQUE,  -- one invoice per enrollment
    amount         DECIMAL(10,2) NOT NULL CHECK (amount >= 0),  -- fee snapshot at enrollment time
    momo_reference VARCHAR(100),
    method         ENUM('momo', 'cash', 'card') NOT NULL DEFAULT 'momo',
    status         ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending',
    issued_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at        DATETIME,
    CONSTRAINT fk_invoices_student    FOREIGN KEY (student_id)    REFERENCES students(id),
    CONSTRAINT fk_invoices_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- MODULE 3: HR / STAFF PAYROLL
-- ----------------------------------------------------------------------------
CREATE TABLE payroll_runs (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    period_start DATE NOT NULL,
    period_end   DATE NOT NULL,
    run_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('draft', 'processed', 'paid') NOT NULL DEFAULT 'draft',
    created_by   INT UNSIGNED,
    CONSTRAINT fk_payrollrun_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE payslips (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payroll_run_id INT UNSIGNED NOT NULL,
    staff_id       INT UNSIGNED NOT NULL,
    base_salary    DECIMAL(10,2) NOT NULL CHECK (base_salary >= 0),
    deductions     DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (deductions >= 0),
    net_pay        DECIMAL(10,2) NOT NULL CHECK (net_pay >= 0),
    momo_reference VARCHAR(100),
    status         ENUM('pending', 'paid') NOT NULL DEFAULT 'pending',
    UNIQUE KEY uq_payslip_run_staff (payroll_run_id, staff_id),
    CONSTRAINT fk_payslip_run   FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id),
    CONSTRAINT fk_payslip_staff FOREIGN KEY (staff_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ============================================================================
-- INDEXES — Build Task 5: "add an index to at least 2 tables that will be
-- searched often". Chosen for the queries the demo actually needs to run
-- fast: a student's enrollments, a course's roster, a student's grades, a
-- teacher's own grade entries, and a student's invoices.
-- ============================================================================
CREATE INDEX idx_courses_teacher      ON courses(teacher_id);
CREATE INDEX idx_enrollments_student  ON enrollments(student_id);
CREATE INDEX idx_enrollments_course   ON enrollments(course_id);
CREATE INDEX idx_grades_enrollment    ON grades(enrollment_id);
CREATE INDEX idx_grades_recorded_by   ON grades(recorded_by);
CREATE INDEX idx_invoices_student     ON invoices(student_id);
CREATE INDEX idx_payslips_staff       ON payslips(staff_id);
-- Note: users.email, students.user_id, students.admission_number,
-- courses.code, enrollments(student_id, course_id) and
-- invoices.enrollment_id already have an implicit unique index from their
-- UNIQUE constraints, so no separate CREATE INDEX is needed there.
