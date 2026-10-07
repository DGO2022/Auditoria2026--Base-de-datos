-- ============================================================
-- Scripts de evaluación – Auditor 2 – Módulo Asistencia
-- Uso: fase de ejecución, sobre el clon local asistencia_audit
-- Cada consulta devuelve A (registros que cumplen), B (evaluables) y X = A/B
-- Las reglas de definición (A-01, A-03, A-10, A-17, A-22) se verifican en el
-- diccionario de datos y en las restricciones del esquema.
-- ============================================================
USE asistencia_audit;  -- ejecutar con el usuario de solo lectura 'auditor'
SET @fecha_corte = '2026-09-22';  -- dump: 22-09-2026 15:35 UTC (10:35 Lima)
-- Parámetros de fuente Empresa (completar con la regla validada)
SET @status_validos = '__DEFINIR__';    -- valores separados por coma
SET @hora_min = NULL, @hora_max = NULL; -- 'HH:MM:SS'
SET @max_horas_extra = NULL;
SET @max_jornada = NULL;                -- 'HH:MM:SS'

-- A-02 Dominio de estados (valores existentes y cumplimiento)
SELECT status, COUNT(*) FROM attendance GROUP BY status;
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(FIND_IN_SET(status, @status_validos) > 0) AS A, COUNT(*) AS B FROM attendance) t;

-- A-04 Hora de entrada en la franja operativa
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(time_in BETWEEN @hora_min AND @hora_max) AS A, COUNT(*) AS B FROM attendance) t;

-- A-05 Horas extra en rango
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(horas_extra BETWEEN 1 AND @max_horas_extra) AS A, COUNT(*) AS B
  FROM horas_extra_detalle) t;

-- A-06 Día y mes válidos en feriados (2024 admite el 29 de febrero)
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(STR_TO_DATE(CONCAT('2024-', month, '-', day), '%Y-%m-%d') IS NOT NULL) AS A,
         COUNT(*) AS B
  FROM holidays WHERE day IS NOT NULL OR month IS NOT NULL) t;

-- A-07 Campos informados en faltas justificadas, por campo
SELECT COUNT(*) AS B,
  SUM(fecha_justificada IS NOT NULL) AS A_fecha_justificada,
  SUM(employee_id IS NOT NULL) AS A_employee_id
FROM faltas_justificadas;

-- A-08 Practicantes activos con asistencia en los últimos 30 días
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(EXISTS (SELECT 1 FROM attendance a WHERE a.employee_id = e.id
                     AND a.date BETWEEN @fecha_corte - INTERVAL 30 DAY AND @fecha_corte)) AS A,
         COUNT(*) AS B
  FROM employees e
  WHERE e.active = 1 AND e.date_in <= @fecha_corte - INTERVAL 30 DAY) t;

-- A-09 Asistencias únicas por practicante y fecha (A = pares distintos)
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT COUNT(DISTINCT employee_id, date) AS A, COUNT(*) AS B FROM attendance) t;

-- A-11 Practicante existente, por tabla
SELECT 'attendance' AS tabla, SUM(e.id IS NOT NULL) AS A, COUNT(*) AS B
FROM attendance a LEFT JOIN employees e ON e.id = a.employee_id
UNION ALL
SELECT 'faltas_justificadas', SUM(e.id IS NOT NULL), COUNT(*)
FROM faltas_justificadas f LEFT JOIN employees e ON e.id = f.employee_id
WHERE f.employee_id IS NOT NULL;

-- A-12 Salida posterior a la entrada
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(time_out > time_in) AS A, COUNT(*) AS B FROM attendance
  WHERE time_out IS NOT NULL AND time_out <> '00:00:00') t;

-- A-13 Sin asistencia en fecha de falta justificada
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(NOT EXISTS (SELECT 1 FROM faltas_justificadas f
                         WHERE f.employee_id = a.employee_id
                           AND f.fecha_justificada = a.date)) AS A,
         COUNT(*) AS B FROM attendance a) t;

-- A-14 Asistencia dentro del periodo de prácticas
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(a.date BETWEEN e.date_in AND COALESCE(e.date_out_new, e.date_out)) AS A,
         COUNT(*) AS B
  FROM attendance a JOIN employees e ON e.id = a.employee_id) t;

-- A-15 Feriados fijos coherentes con sus fechas
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(h.day IS NOT NULL AND h.month IS NOT NULL
             AND DAY(hd.date) = h.day AND MONTH(hd.date) = h.month) AS A,
         COUNT(*) AS B
  FROM holidays h JOIN holiday_dates hd ON hd.holiday_id = h.id
  WHERE h.is_fixed = 1) t;

-- A-16 Recuperación posterior a la falta
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(fecha_recuperacion >= fecha_falta) AS A, COUNT(*) AS B
  FROM horas_extra_detalle WHERE fecha_falta IS NOT NULL) t;

-- A-18 Tiempo trabajado igual a la diferencia entre salida y entrada
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(tiempo_trabajado = TIMEDIFF(time_out, time_in)) AS A, COUNT(*) AS B
  FROM attendance
  WHERE tiempo_trabajado IS NOT NULL AND time_out IS NOT NULL AND time_out <> '00:00:00') t;

-- A-19 Año coherente con la fecha
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(year = YEAR(date)) AS A, COUNT(*) AS B FROM holiday_dates) t;

-- A-20 Último registro del historial coincidente con el detalle
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(h.horas_extra <=> d.horas_extra
             AND h.fecha_falta <=> d.fecha_falta
             AND h.fecha_recuperacion <=> d.fecha_recuperacion) AS A,
         COUNT(*) AS B
  FROM horas_extra_detalle d
  JOIN horas_extra_historial h ON h.hora_extra_id = d.id
  WHERE h.id = (SELECT MAX(h2.id) FROM horas_extra_historial h2 WHERE h2.hora_extra_id = d.id)) t;

-- A-21 Jornada dentro de la duración máxima
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(TIMEDIFF(time_out, time_in) BETWEEN '00:01:00' AND @max_jornada) AS A,
         COUNT(*) AS B FROM attendance
  WHERE time_out IS NOT NULL AND time_out <> '00:00:00') t;

-- A-23 Feriados con fecha en el año de la fecha de corte
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(EXISTS (SELECT 1 FROM holiday_dates hd
                     WHERE hd.holiday_id = h.id AND hd.year = YEAR(@fecha_corte))) AS A,
         COUNT(*) AS B FROM holidays h) t;

-- A-24 Salida registrada antes de la fecha de corte
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(time_out IS NOT NULL AND time_out <> '00:00:00') AS A, COUNT(*) AS B
  FROM attendance WHERE date < @fecha_corte) t;
