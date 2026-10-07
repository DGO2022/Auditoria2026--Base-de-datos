-- ============================================================
-- Scripts de evaluación – Auditor 3 – Módulo Desempeño
-- Uso: fase de ejecución, sobre el clon local asistencia_audit
-- Cada consulta devuelve A (registros que cumplen), B (evaluables) y X = A/B
-- Las reglas de definición (D-01, D-04, D-12, D-18, D-22) se verifican en el
-- diccionario de datos y en las restricciones del esquema.
-- ============================================================
USE asistencia_audit;  -- ejecutar con el usuario de solo lectura 'auditor'
SET @fecha_corte = '2026-09-22';  -- dump: 22-09-2026 15:35 UTC (10:35 Lima)
-- Parámetros de fuente Empresa (completar con la regla validada)
SET @nota_min = NULL, @nota_max = NULL;
SET @decimales_nota = NULL;
SET @acciones_validas = '__DEFINIR__'; -- valores separados por coma
SET @anio_min = NULL;
SET @plazo_revision = NULL;            -- días

-- D-02 Decimales de la nota
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(ROUND(nota, @decimales_nota) = nota) AS A, COUNT(*) AS B
  FROM grades WHERE nota IS NOT NULL) t;

-- D-03 Dominio de acciones (valores existentes y cumplimiento)
SELECT action, COUNT(*) FROM grade_history GROUP BY action;
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(FIND_IN_SET(action, @acciones_validas) > 0) AS A, COUNT(*) AS B FROM grade_history) t;

-- D-05 Nota dentro de la escala
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(nota BETWEEN @nota_min AND @nota_max) AS A, COUNT(*) AS B
  FROM grades WHERE nota IS NOT NULL) t;

-- D-06 Calificaciones semanales dentro de la escala (por registro)
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(
    GREATEST(
      COALESCE(sem_1, @nota_min),
      COALESCE(sem_2, @nota_min),
      COALESCE(sem_3, @nota_min),
      COALESCE(sem_4, @nota_min),
      COALESCE(sem_5, @nota_min),
      COALESCE(sem_6, @nota_min),
      COALESCE(sem_7, @nota_min),
      COALESCE(sem_8, @nota_min),
      COALESCE(sem_9, @nota_min),
      COALESCE(sem_10, @nota_min),
      COALESCE(sem_11, @nota_min),
      COALESCE(sem_12, @nota_min),
      COALESCE(sem_13, @nota_min),
      COALESCE(sem_14, @nota_min),
      COALESCE(sem_15, @nota_min),
      COALESCE(sem_16, @nota_min),
      COALESCE(sem_17, @nota_min),
      COALESCE(sem_18, @nota_min),
      COALESCE(sem_19, @nota_min),
      COALESCE(sem_20, @nota_min),
      COALESCE(sem_21, @nota_min),
      COALESCE(sem_22, @nota_min),
      COALESCE(sem_23, @nota_min),
      COALESCE(sem_24, @nota_min),
      COALESCE(sem_25, @nota_min),
      COALESCE(sem_26, @nota_min),
      COALESCE(sem_27, @nota_min),
      COALESCE(sem_28, @nota_min),
      COALESCE(sem_29, @nota_min),
      COALESCE(sem_30, @nota_min)) <= @nota_max
    AND
    LEAST(
      COALESCE(sem_1, @nota_max),
      COALESCE(sem_2, @nota_max),
      COALESCE(sem_3, @nota_max),
      COALESCE(sem_4, @nota_max),
      COALESCE(sem_5, @nota_max),
      COALESCE(sem_6, @nota_max),
      COALESCE(sem_7, @nota_max),
      COALESCE(sem_8, @nota_max),
      COALESCE(sem_9, @nota_max),
      COALESCE(sem_10, @nota_max),
      COALESCE(sem_11, @nota_max),
      COALESCE(sem_12, @nota_max),
      COALESCE(sem_13, @nota_max),
      COALESCE(sem_14, @nota_max),
      COALESCE(sem_15, @nota_max),
      COALESCE(sem_16, @nota_max),
      COALESCE(sem_17, @nota_max),
      COALESCE(sem_18, @nota_max),
      COALESCE(sem_19, @nota_max),
      COALESCE(sem_20, @nota_max),
      COALESCE(sem_21, @nota_max),
      COALESCE(sem_22, @nota_max),
      COALESCE(sem_23, @nota_max),
      COALESCE(sem_24, @nota_max),
      COALESCE(sem_25, @nota_max),
      COALESCE(sem_26, @nota_max),
      COALESCE(sem_27, @nota_max),
      COALESCE(sem_28, @nota_max),
      COALESCE(sem_29, @nota_max),
      COALESCE(sem_30, @nota_max)) >= @nota_min
  ) AS A, COUNT(*) AS B FROM weekly_grades) t;

-- D-07 Mes y año válidos
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(mes BETWEEN 1 AND 12 AND anio BETWEEN @anio_min AND YEAR(@fecha_corte)) AS A,
         COUNT(*) AS B FROM comentarios_notas_mensuales) t;

-- D-08 Campos informados en grades, por campo
SELECT COUNT(*) AS B,
  SUM(nota IS NOT NULL) AS A_nota, SUM(employee_id IS NOT NULL) AS A_employee_id,
  SUM(id_criterio IS NOT NULL) AS A_id_criterio, SUM(id_subcriterio IS NOT NULL) AS A_id_subcriterio,
  SUM(fecha_inicio_semana IS NOT NULL) AS A_fecha_inicio,
  SUM(fecha_fin_semana IS NOT NULL) AS A_fecha_fin
FROM grades;

-- D-09 Campos informados en criterios y subcriterios, por campo
SELECT 'criterios.nombre_criterio' AS campo,
       SUM(COALESCE(TRIM(nombre_criterio), '') <> '') AS A, COUNT(*) AS B FROM criterios
UNION ALL
SELECT 'subcriterios.nombre_subcriterio',
       SUM(COALESCE(TRIM(nombre_subcriterio), '') <> ''), COUNT(*) FROM subcriterios
UNION ALL
SELECT 'subcriterios.id_criterio', SUM(id_criterio IS NOT NULL), COUNT(*) FROM subcriterios;

-- D-10 Revisor y fecha de revisión en conjunto
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM((revisado_por IS NULL) = (fecha_revision IS NULL)) AS A, COUNT(*) AS B FROM grades) t;

-- D-11 Una nota por practicante, subcriterio y semana (A = combinaciones distintas)
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT COUNT(DISTINCT employee_id, id_subcriterio, fecha_inicio_semana) AS A, COUNT(*) AS B
  FROM grades
  WHERE employee_id IS NOT NULL AND id_subcriterio IS NOT NULL AND fecha_inicio_semana IS NOT NULL) t;

-- D-13 Referencias existentes, por campo
SELECT 'grades.employee_id' AS campo, SUM(e.id IS NOT NULL) AS A, COUNT(*) AS B
FROM grades g LEFT JOIN employees e ON e.id = g.employee_id WHERE g.employee_id IS NOT NULL
UNION ALL
SELECT 'grades.id_criterio', SUM(c.id IS NOT NULL), COUNT(*)
FROM grades g LEFT JOIN criterios c ON c.id = g.id_criterio WHERE g.id_criterio IS NOT NULL
UNION ALL
SELECT 'grades.id_subcriterio', SUM(s.id IS NOT NULL), COUNT(*)
FROM grades g LEFT JOIN subcriterios s ON s.id = g.id_subcriterio WHERE g.id_subcriterio IS NOT NULL
UNION ALL
SELECT 'grade_history.grade_id', SUM(g.id IS NOT NULL), COUNT(*)
FROM grade_history h LEFT JOIN grades g ON g.id = h.grade_id
UNION ALL
SELECT 'weekly_grades.employee_id', SUM(e.id IS NOT NULL), COUNT(*)
FROM weekly_grades w LEFT JOIN employees e ON e.id = w.employee_id
UNION ALL
SELECT 'weekly_grades.id_criterio', SUM(c.id IS NOT NULL), COUNT(*)
FROM weekly_grades w LEFT JOIN criterios c ON c.id = w.id_criterio
UNION ALL
SELECT 'comentarios_notas_mensuales.employee_id', SUM(e.id IS NOT NULL), COUNT(*)
FROM comentarios_notas_mensuales m LEFT JOIN employees e ON e.id = m.employee_id
UNION ALL
SELECT 'subcriterios.id_criterio', SUM(c.id IS NOT NULL), COUNT(*)
FROM subcriterios s LEFT JOIN criterios c ON c.id = s.id_criterio WHERE s.id_criterio IS NOT NULL;

-- D-14 Subcriterio perteneciente al criterio de la nota
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(s.id_criterio = g.id_criterio) AS A, COUNT(*) AS B
  FROM grades g JOIN subcriterios s ON s.id = g.id_subcriterio
  WHERE g.id_criterio IS NOT NULL) t;

-- D-15 Semana de 7 días
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(DATEDIFF(fecha_fin_semana, fecha_inicio_semana) = 6) AS A, COUNT(*) AS B
  FROM grades WHERE fecha_inicio_semana IS NOT NULL AND fecha_fin_semana IS NOT NULL) t;

-- D-16 Revisión posterior al inicio de la semana
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(fecha_revision >= fecha_inicio_semana) AS A, COUNT(*) AS B
  FROM grades WHERE fecha_revision IS NOT NULL AND fecha_inicio_semana IS NOT NULL) t;

-- D-17 Practicante del historial igual al de la nota
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(h.employee_id <=> g.employee_id) AS A, COUNT(*) AS B
  FROM grade_history h JOIN grades g ON g.id = h.grade_id) t;

-- D-19 Último valor del historial igual a la nota vigente
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(ROUND(h.new_value, 2) = ROUND(g.nota, 2)) AS A, COUNT(*) AS B
  FROM grades g JOIN grade_history h ON h.grade_id = g.id
  WHERE h.new_value IS NOT NULL
    AND h.id = (SELECT MAX(h2.id) FROM grade_history h2 WHERE h2.grade_id = g.id)) t;

-- D-20 Practicantes con variación en sus notas (mínimo 10 notas)
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(n_distintas > 1) AS A, COUNT(*) AS B FROM (
    SELECT employee_id, COUNT(DISTINCT nota) AS n_distintas
    FROM grades WHERE nota IS NOT NULL AND employee_id IS NOT NULL
    GROUP BY employee_id HAVING COUNT(*) >= 10) x) t;

-- D-21 Responsable del registro informado, por campo
SELECT 'grades.revisado_por' AS campo, SUM(revisado_por IS NOT NULL) AS A, COUNT(*) AS B
FROM grades WHERE nota IS NOT NULL
UNION ALL
SELECT 'comentarios_notas_mensuales.registrado_por', SUM(registrado_por IS NOT NULL), COUNT(*)
FROM comentarios_notas_mensuales
UNION ALL
SELECT 'grade_history.actor_admin_id', SUM(actor_admin_id IS NOT NULL), COUNT(*)
FROM grade_history;

-- D-23 Revisión dentro del plazo
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(DATEDIFF(fecha_revision, fecha_fin_semana) <= @plazo_revision) AS A, COUNT(*) AS B
  FROM grades WHERE fecha_revision IS NOT NULL AND fecha_fin_semana IS NOT NULL) t;

-- D-24 Calificaciones cerradas para prácticas concluidas
SELECT A, B, ROUND(A/B, 4) AS X FROM (
  SELECT SUM(w.estado <> 'abierto') AS A, COUNT(*) AS B
  FROM weekly_grades w JOIN employees e ON e.id = w.employee_id
  WHERE COALESCE(e.date_out_new, e.date_out) < @fecha_corte) t;
