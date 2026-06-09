-- ============================================================
-- performance_analysis.sql
-- Analyse comparative AVANT / APRÈS indexation
-- À exécuter sur oracle-central (BDDCENTRAL)
-- Mesure : temps d'exécution + plan d'exécution
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 220
SET PAGESIZE 60
SET SQLBLANKLINES ON
SET TRIMSPOOL ON
SET TAB OFF
SET WRAP OFF

COLUMN SOCIETE FORMAT A25
COLUMN INDEX_NAME FORMAT A24
COLUMN INDEX_TYPE FORMAT A22
COLUMN STATUS FORMAT A8
COLUMN PLAN_TABLE_OUTPUT FORMAT A180
COLUMN IDCLIENT FORMAT 999999 HEADING ID_CL
COLUMN NB_COMMANDES FORMAT 999999 HEADING NB_CMD

PROMPT ====================================================
PROMPT  ANALYSE COMPARATIVE DES PERFORMANCES
PROMPT  Requête : CA par catégorie en 2026 (requête distribuée)
PROMPT ====================================================

-- ============================================================
-- PHASE 1 — MESURE AVANT INDEXATION
-- Supprimer les index existants sur COMMANDES (si présents)
-- ============================================================

PROMPT
PROMPT Phase 1 : Suppression des index de test
DECLARE
    PROCEDURE drop_if_exists(p_index VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX ' || p_index;
        DBMS_OUTPUT.PUT_LINE('Index supprimé : ' || p_index);
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
BEGIN
    drop_if_exists('IDX_CMD_DATECOMMANDE');
    drop_if_exists('IDX_CMD_IDCLIENT');
    drop_if_exists('IDX_CMD_CLIENT_DATE');
    drop_if_exists('IDX_CMD_YEAR_FUNC');
END;
/

-- Invalider les statistiques pour forcer un full scan
BEGIN
    DBMS_STATS.DELETE_TABLE_STATS(USER, 'COMMANDES');
    DBMS_STATS.DELETE_TABLE_STATS(USER, 'CLIENTS');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- -------------------------------------------------------
-- EXPLAIN PLAN AVANT indexation
-- -------------------------------------------------------
PROMPT
PROMPT EXPLAIN PLAN : Commandes par client en 2026 (SANS index)
EXPLAIN PLAN SET STATEMENT_ID = 'AVANT_INDEX' FOR
SELECT
    cl.IDCLIENT,
    cl.SOCIETE,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE
ORDER BY NB_COMMANDES DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'AVANT_INDEX',
    format       => 'TYPICAL +ROWS +COST'
));

-- -------------------------------------------------------
-- Exécution avec TIMING (mesure du temps réel)
-- -------------------------------------------------------
PROMPT
PROMPT Exécution SANS index (TIMING ON)
DECLARE
    t_start  TIMESTAMP;
    t_end    TIMESTAMP;
    v_elapsed NUMBER;
    v_count  NUMBER;
BEGIN
    t_start := SYSTIMESTAMP;

    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT
            cl.IDCLIENT,
            cl.SOCIETE,
            COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
        FROM CLIENTS cl
        JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
        WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
        GROUP BY cl.IDCLIENT, cl.SOCIETE
    );

    t_end := SYSTIMESTAMP;
    v_elapsed := EXTRACT(SECOND FROM (t_end - t_start)) * 1000;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== RÉSULTAT PHASE 1 (SANS INDEX) ===');
    DBMS_OUTPUT.PUT_LINE('  Lignes retournées : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('  Temps écoulé     : ' || ROUND(v_elapsed, 3) || ' ms');
    DBMS_OUTPUT.PUT_LINE('  Opération Oracle : FULL TABLE SCAN attendu');
END;
/

-- ============================================================
-- PHASE 2 — CRÉATION DES INDEX
-- ============================================================
PROMPT
PROMPT ====================================================
PROMPT Phase 2 : Création des index

-- Index simple sur DATECOMMANDE
CREATE INDEX IDX_CMD_DATECOMMANDE
    ON COMMANDES (DATECOMMANDE);

-- Index sur IDCLIENT (jointure fréquente)
CREATE INDEX IDX_CMD_IDCLIENT
    ON COMMANDES (IDCLIENT);

-- Index composite (couvre les deux critères simultanément)
CREATE INDEX IDX_CMD_CLIENT_DATE
    ON COMMANDES (IDCLIENT, DATECOMMANDE);

-- Index fonctionnel sur EXTRACT(YEAR FROM DATECOMMANDE)
-- Résout le problème de non-utilisation de l'index par EXTRACT()
CREATE INDEX IDX_CMD_YEAR_FUNC
    ON COMMANDES (EXTRACT(YEAR FROM DATECOMMANDE));

PROMPT Index créés :
SELECT INDEX_NAME, INDEX_TYPE, STATUS
FROM USER_INDEXES
WHERE TABLE_NAME = 'COMMANDES'
ORDER BY INDEX_NAME;

-- Recollecte des statistiques
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'COMMANDES', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CLIENTS',   CASCADE => TRUE);
END;
/

-- ============================================================
-- PHASE 3 — MESURE APRÈS INDEXATION
-- ============================================================

PROMPT
PROMPT ====================================================
PROMPT Phase 3 : Mesure APRÈS indexation

-- -------------------------------------------------------
-- EXPLAIN PLAN APRÈS indexation
-- -------------------------------------------------------
PROMPT
PROMPT EXPLAIN PLAN : Commandes par client en 2026 (AVEC index)
EXPLAIN PLAN SET STATEMENT_ID = 'APRES_INDEX' FOR
SELECT
    cl.IDCLIENT,
    cl.SOCIETE,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE
ORDER BY NB_COMMANDES DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'APRES_INDEX',
    format       => 'TYPICAL +ROWS +COST'
));

-- -------------------------------------------------------
-- Exécution AVEC index
-- -------------------------------------------------------
PROMPT
PROMPT Exécution AVEC index
DECLARE
    t_start  TIMESTAMP;
    t_end    TIMESTAMP;
    v_elapsed NUMBER;
    v_count  NUMBER;
BEGIN
    t_start := SYSTIMESTAMP;

    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT
            cl.IDCLIENT,
            cl.SOCIETE,
            COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
        FROM CLIENTS cl
        JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
        WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
        GROUP BY cl.IDCLIENT, cl.SOCIETE
    );

    t_end := SYSTIMESTAMP;
    v_elapsed := EXTRACT(SECOND FROM (t_end - t_start)) * 1000;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== RÉSULTAT PHASE 3 (AVEC INDEX) ===');
    DBMS_OUTPUT.PUT_LINE('  Lignes retournées : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('  Temps écoulé     : ' || ROUND(v_elapsed, 3) || ' ms');
    DBMS_OUTPUT.PUT_LINE('  Opération Oracle : INDEX RANGE SCAN attendu');
END;
/

-- ============================================================
-- PHASE 4 — REQUÊTE DISTRIBUÉE AVEC TIMING
-- ============================================================
PROMPT
PROMPT ====================================================
PROMPT Phase 4 : Requête distribuée (CA par catégorie 2026)

DECLARE
    t_start  TIMESTAMP;
    t_end    TIMESTAMP;
    v_elapsed NUMBER;
    v_count  NUMBER;
BEGIN
    t_start := SYSTIMESTAMP;

    SELECT COUNT(*) INTO v_count FROM (
        SELECT cat.NOMDECATEGORIE, SUM(ca.CA_TOTAL) AS CA_TOTAL_2026
        FROM (
            SELECT p.IDCATEG,
                SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
            FROM LigneCommandes1@site1_link lc
            JOIN Produits1@site1_link p ON lc.IDPRODUIT = p.IDPRODUIT
            JOIN Commandes1@site1_link c ON lc.IDCOMMANDE = c.IDCOMMANDE
            WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
            GROUP BY p.IDCATEG
            UNION ALL
            SELECT p.IDCATEG,
                SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
            FROM LigneCommandes2@site2_link lc
            JOIN Produits2@site2_link p ON lc.IDPRODUIT = p.IDPRODUIT
            JOIN Commandes2@site2_link c ON lc.IDCOMMANDE = c.IDCOMMANDE
            WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
            GROUP BY p.IDCATEG
        ) ca
        JOIN CATEGORIES cat ON ca.IDCATEG = cat.IDCATEG
        GROUP BY cat.NOMDECATEGORIE
    );

    t_end := SYSTIMESTAMP;
    v_elapsed := EXTRACT(SECOND FROM (t_end - t_start)) * 1000;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== REQUÊTE DISTRIBUÉE ===');
    DBMS_OUTPUT.PUT_LINE('  Catégories traitées : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('  Temps total (2 sites) : ' || ROUND(v_elapsed, 3) || ' ms');
    DBMS_OUTPUT.PUT_LINE('  Note : inclut la latence réseau inter-conteneurs');
END;
/

-- ============================================================
-- RÉSUMÉ COMPARATIF
-- ============================================================
PROMPT
PROMPT ====================================================
PROMPT  RÉSUMÉ : Impact de l'indexation
PROMPT ====================================================
PROMPT
PROMPT  Phase 1 (SANS index) : FULL TABLE SCAN sur COMMANDES + CLIENTS
PROMPT  Phase 3 (AVEC index) : INDEX RANGE SCAN + INDEX FAST FULL SCAN
PROMPT
PROMPT  Améliorations attendues :
PROMPT  - Réduction des blocs lus (Consistent Gets)
PROMPT  - Élimination du tri complet (Sort Order By → Index Order By)
PROMPT  - Index fonctionnel IDX_CMD_YEAR_FUNC optimise EXTRACT(YEAR FROM ...)
PROMPT
PROMPT  Voir les plans générés ci-dessus pour la comparaison détaillée.
PROMPT ====================================================
