-- ============================================================
-- Scripts de evaluación – Auditor 1 – Módulo Personal
-- Uso: fase de ejecución, sobre el clon local asistencia_audit
-- Cada consulta devuelve A (registros que cumplen), B (evaluables) y X = A/B
-- Las reglas de definición (P-13, P-17, P-20, P-21) se verifican en el
-- diccionario de datos y en las restricciones del esquema.
-- ============================================================
USE asistencia_audit;  -- ejecutar con el usuario de solo lectura 'auditor'
SET @fecha_corte = '2026-09-22';  -- dump: 22-09-2026 15:35 UTC (10:35 Lima)
-- Parámetros de fuente Empresa (completar con la regla validada)
SET @generos = '__DEFINIR__';          -- valores separados por coma
SET @tipos_practica = '__DEFINIR__';   -- valores separados por coma
SET @edad_min = NULL, @edad_max = NULL;
SET @inicio_operacion = NULL;          -- 'AAAA-MM-DD'

-- P-01 Longitud del DNI
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(CHAR_LENGTH(dni) = 8) AS A, COUNT(*) AS B FROM employees) t;

-- P-02 DNI numérico
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(dni REGEXP '^[0-9]+$') AS A, COUNT(*) AS B FROM employees) t;

-- P-03 Formato del correo personal
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(personal_email REGEXP '^[^@ ]+@[^@ ]+\\.[A-Za-z]{2,}$') AS A, COUNT(*) AS B
  FROM employees) t;

-- P-04 Formato del celular
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(contact_info REGEXP '^9[0-9]{8}$') AS A, COUNT(*) AS B FROM employees) t;

-- P-05 Dominio de género (valores existentes y cumplimiento)
SELECT gender, COUNT(*) FROM employees GROUP BY gender;
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(FIND_IN_SET(gender, @generos) > 0) AS A, COUNT(*) AS B FROM employees) t;

-- P-06 Dominio del tipo de práctica
SELECT type_practice, COUNT(*) FROM employees GROUP BY type_practice;
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(FIND_IN_SET(type_practice, @tipos_practica) > 0) AS A, COUNT(*) AS B FROM employees) t;

-- P-07 Edad al ingreso
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(TIMESTAMPDIFF(YEAR, birthday, date_in) BETWEEN @edad_min AND @edad_max) AS A,
         COUNT(*) AS B FROM employees) t;

-- P-08 Fecha de ingreso en el periodo operativo
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(date_in BETWEEN @inicio_operacion AND @fecha_corte) AS A, COUNT(*) AS B FROM employees) t;

-- P-09 Campos obligatorios sin cadena vacía, por campo
SELECT COUNT(*) AS B,
  SUM(TRIM(employee_id) <> '') AS A_employee_id, SUM(TRIM(firstname) <> '') AS A_firstname,
  SUM(TRIM(lastname) <> '') AS A_lastname, SUM(TRIM(contact_info) <> '') AS A_contact_info,
  SUM(TRIM(gender) <> '') AS A_gender, SUM(TRIM(type_practice) <> '') AS A_type_practice,
  SUM(TRIM(dni) <> '') AS A_dni, SUM(TRIM(personal_email) <> '') AS A_personal_email,
  SUM(TRIM(university) <> '') AS A_university, SUM(TRIM(career) <> '') AS A_career
FROM employees;

-- P-10 Registros completos
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(TRIM(employee_id) <> '' AND TRIM(firstname) <> '' AND TRIM(lastname) <> ''
         AND TRIM(contact_info) <> '' AND TRIM(gender) <> '' AND TRIM(type_practice) <> ''
         AND TRIM(dni) <> '' AND TRIM(personal_email) <> '' AND TRIM(university) <> ''
         AND TRIM(career) <> '' AND departamento_id IS NOT NULL) AS A,
         COUNT(*) AS B FROM employees) t;

-- P-11 Valores por defecto 0, por campo
SELECT COUNT(*) AS B,
  SUM(COALESCE(negocio_id, 0) <> 0) AS A_negocio_id,
  SUM(COALESCE(project_id, 0) <> 0) AS A_project_id
FROM employees;

-- P-12 Unicidad, por campo (A = valores distintos)
SELECT COUNT(*) AS B,
  COUNT(DISTINCT dni) AS A_dni,
  COUNT(DISTINCT employee_id) AS A_employee_id,
  COUNT(DISTINCT personal_email) AS A_personal_email
FROM employees;

-- P-14 Referencias existentes en los catálogos, por campo
SELECT COUNT(*) AS B,
  SUM(p.id IS NOT NULL) AS A_position,
  SUM(s.id IS NOT NULL) AS A_schedule,
  SUM(e.departamento_id IS NOT NULL) AS B_departamento, SUM(d.id IS NOT NULL) AS A_departamento,
  SUM(COALESCE(e.negocio_id, 0) <> 0) AS B_negocio, SUM(n.id IS NOT NULL) AS A_negocio,
  SUM(COALESCE(e.project_id, 0) <> 0) AS B_project, SUM(pr.id IS NOT NULL) AS A_project
FROM employees e
LEFT JOIN position p ON p.id = e.position_id
LEFT JOIN schedules s ON s.id = e.schedule_id
LEFT JOIN departamentos d ON d.id = e.departamento_id
LEFT JOIN negocio n ON n.id = e.negocio_id
LEFT JOIN projects pr ON pr.id = e.project_id;

-- P-15 Departamento del practicante igual al de su puesto
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(e.departamento_id = p.departamento_id) AS A, COUNT(*) AS B
  FROM employees e JOIN position p ON p.id = e.position_id
  WHERE e.departamento_id IS NOT NULL AND p.departamento_id IS NOT NULL) t;

-- P-16 Coherencia de fechas del periodo de prácticas
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(date_out >= date_in AND (date_out_new IS NULL OR date_out_new >= date_out)) AS A,
         COUNT(*) AS B FROM employees) t;

-- P-18 Coincidencia entre employees_backup y employees
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(e.firstname = b.firstname AND e.lastname = b.lastname AND e.dni = b.dni
             AND e.personal_email = b.personal_email AND e.position_id = b.position_id
             AND e.departamento_id <=> b.departamento_id) AS A,
         COUNT(*) AS B
  FROM employees_backup b JOIN employees e ON e.employee_id = b.employee_id) t;

-- P-19 Valores de relleno o de prueba
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(NOT (dni REGEXP '^([0-9])\\1{7}$' OR dni IN ('12345678', '87654321')
                  OR LOWER(CONCAT(firstname, ' ', lastname)) REGEXP 'test|prueba|demo')) AS A,
         COUNT(*) AS B FROM employees) t;

-- P-22 Practicantes activos con periodo vigente
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(COALESCE(date_out_new, date_out) >= @fecha_corte) AS A, COUNT(*) AS B
  FROM employees WHERE active = 1) t;
