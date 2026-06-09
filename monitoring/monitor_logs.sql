-- ============================================================
-- monitor_logs.sql
-- Surveillance des tables de log sur chaque site
-- À exécuter sur le site concerné (Site1 ou Site2)
-- ============================================================

SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 50

PROMPT ====================================================
PROMPT  MONITORING DES LOGS D'OPÉRATIONS
PROMPT  Site : Scénario 2 (LigneCommandes1 / LigneCommandes2)
PROMPT ====================================================

-- -------------------------------------------------------
-- 1. Résumé global du log Site1 Scénario 2
-- -------------------------------------------------------
PROMPT
PROMPT Résumé LOG_SITE1 (Scénario 2)
SELECT
    OPERATION,
    COUNT(*)           AS NB_OPERATIONS,
    MIN(DATE_OPERATION) AS PREMIERE_OP,
    MAX(DATE_OPERATION) AS DERNIERE_OP
FROM LOG_SITE1
GROUP BY OPERATION
ORDER BY NB_OPERATIONS DESC;

-- -------------------------------------------------------
-- 2. 20 dernières opérations — Site1 Sc2
-- -------------------------------------------------------
PROMPT
PROMPT 20 dernières opérations LOG_SITE1
SELECT
    ID_LOG,
    OPERATION,
    IDLIGNECOMMANDE,
    QUANTITE_OLD,
    QUANTITE_NEW,
    TO_CHAR(DATE_OPERATION,'DD/MM/YYYY HH24:MI:SS') AS DATE_OP,
    UTILISATEUR
FROM LOG_SITE1
ORDER BY ID_LOG DESC
FETCH FIRST 20 ROWS ONLY;

-- -------------------------------------------------------
-- 3. Résumé global du log Site1 Scénario 1
-- -------------------------------------------------------
PROMPT
PROMPT Résumé LOG_SITE1_SC1 (Scénario 1)
SELECT
    OPERATION,
    COUNT(*)           AS NB_OPERATIONS,
    MIN(DATE_OPERATION) AS PREMIERE_OP,
    MAX(DATE_OPERATION) AS DERNIERE_OP
FROM LOG_SITE1_SC1
GROUP BY OPERATION
ORDER BY NB_OPERATIONS DESC;

-- -------------------------------------------------------
-- 4. Activité par utilisateur
-- -------------------------------------------------------
PROMPT
PROMPT Activité par utilisateur (LOG_SITE1)
SELECT
    UTILISATEUR,
    COUNT(*)     AS NB_TOTAL,
    SUM(CASE WHEN OPERATION = 'INSERT' THEN 1 ELSE 0 END) AS NB_INSERT,
    SUM(CASE WHEN OPERATION = 'UPDATE' THEN 1 ELSE 0 END) AS NB_UPDATE,
    SUM(CASE WHEN OPERATION = 'DELETE' THEN 1 ELSE 0 END) AS NB_DELETE
FROM LOG_SITE1
GROUP BY UTILISATEUR
ORDER BY NB_TOTAL DESC;

-- -------------------------------------------------------
-- 5. Alertes : opérations des dernières 24h
-- -------------------------------------------------------
PROMPT
PROMPT Opérations récentes (< 24h)
SELECT COUNT(*) AS OPS_RECENTES_24H
FROM LOG_SITE1
WHERE DATE_OPERATION > SYSTIMESTAMP - INTERVAL '1' DAY;

-- -------------------------------------------------------
-- 6. Taille approximative des tables de log
-- -------------------------------------------------------
PROMPT
PROMPT Volume des tables de log
SELECT 'LOG_SITE1'     AS LOG_TABLE, COUNT(*) AS NB_LIGNES FROM LOG_SITE1     UNION ALL
SELECT 'LOG_SITE1_SC1' AS LOG_TABLE, COUNT(*) AS NB_LIGNES FROM LOG_SITE1_SC1 UNION ALL
SELECT 'LOG_SITE2'     AS LOG_TABLE, COUNT(*) AS NB_LIGNES FROM LOG_SITE2     UNION ALL
SELECT 'LOG_SITE2_SC1' AS LOG_TABLE, COUNT(*) AS NB_LIGNES FROM LOG_SITE2_SC1;

PROMPT
PROMPT ====================================================
PROMPT  Monitoring terminé — SYSTIMESTAMP:
SELECT TO_CHAR(SYSTIMESTAMP,'DD/MM/YYYY HH24:MI:SS') FROM DUAL;
PROMPT ====================================================
