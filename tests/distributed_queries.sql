-- ============================================================
-- distributed_queries.sql
-- Requêtes distribuées de démonstration
-- À exécuter sur oracle-central (BDDCENTRAL)
-- Prérequis : synonymes créés (synonyms_central.sql)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 220
SET PAGESIZE 60
SET TIMING ON
SET SQLBLANKLINES ON
SET TRIMSPOOL ON
SET TAB OFF
SET WRAP OFF

COLUMN SITE FORMAT A6
COLUMN SOCIETE FORMAT A25
COLUMN CODECLIENT FORMAT A10
COLUMN NOMDECATEGORIE FORMAT A25
COLUMN FRAGMENT FORMAT A22
COLUMN PLAN_TABLE_OUTPUT FORMAT A180
COLUMN IDCLIENT FORMAT 999999 HEADING ID_CL
COLUMN NB_COMMANDES FORMAT 999999 HEADING NB_CMD
COLUMN NB_LIGNES FORMAT 999999 HEADING NB_LIG
COLUMN QTE_TOTALE FORMAT 999999999 HEADING QTE_TOTAL
COLUMN QTE_MOYENNE FORMAT 9999990.99 HEADING QTE_MOY
COLUMN CA_TOTAL_2026 FORMAT 9999999990.99 HEADING CA_TOTAL

-- ============================================================
-- REQUÊTE 1 — Nombre de commandes par client en 2026
-- Version A : avec notation @link explicite
-- ============================================================
PROMPT === REQUÊTE 1A : Commandes par client (notation @link) ===

SELECT
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

-- ============================================================
-- REQUÊTE 1B — Même requête via synonymes (accès transparent)
-- Les synonymes LigneCommandes1, LigneCommandes2 pointent
-- vers les tables distantes sans @link
-- ============================================================
PROMPT === REQUÊTE 1B : Vue distribuée via synonymes (transparent) ===

SELECT
    SITE,
    COUNT(*) AS NB_LIGNES,
    SUM(QUANTITE) AS QTE_TOTALE,
    AVG(QUANTITE) AS QTE_MOYENNE
FROM V_LIGNECOMMANDES_GLOBAL_SYN
GROUP BY SITE
ORDER BY SITE;

-- ============================================================
-- REQUÊTE 2 — EXPLAIN PLAN avant indexation
-- ============================================================
PROMPT === EXPLAIN PLAN : Commandes par client 2026 (SANS index) ===

EXPLAIN PLAN FOR
SELECT
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================================
-- REQUÊTE 3 — Création des index (si non encore créés)
-- ============================================================
PROMPT === Création des index sur COMMANDES ===

DECLARE
    PROCEDURE create_index_safe(p_ddl VARCHAR2, p_name VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
        DBMS_OUTPUT.PUT_LINE('Index créé : ' || p_name);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -955 THEN
                DBMS_OUTPUT.PUT_LINE('Index existe déjà : ' || p_name);
            ELSE
                RAISE;
            END IF;
    END;
BEGIN
    -- Index sur DATECOMMANDE (critère de filtrage)
    create_index_safe(
        'CREATE INDEX idx_cmd_datecommande ON COMMANDES (DATECOMMANDE)',
        'idx_cmd_datecommande');

    -- Index sur IDCLIENT (jointure fréquente)
    create_index_safe(
        'CREATE INDEX idx_cmd_idclient ON COMMANDES (IDCLIENT)',
        'idx_cmd_idclient');

    -- Index composite (couvre les deux critères)
    create_index_safe(
        'CREATE INDEX idx_cmd_client_date ON COMMANDES (IDCLIENT, DATECOMMANDE)',
        'idx_cmd_client_date');

    -- Index FONCTIONNEL sur EXTRACT(YEAR FROM DATECOMMANDE)
    -- CORRECTION : résout le problème d'inutilisation de l'index
    -- par EXTRACT() qui était signalé comme lacune
    create_index_safe(
        'CREATE INDEX idx_cmd_year_func ON COMMANDES (EXTRACT(YEAR FROM DATECOMMANDE))',
        'idx_cmd_year_func');
END;
/

-- ============================================================
-- REQUÊTE 4 — EXPLAIN PLAN après indexation
-- ============================================================
PROMPT === EXPLAIN PLAN : Commandes par client 2026 (AVEC index) ===

EXPLAIN PLAN FOR
SELECT
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================================
-- REQUÊTE 5 — Chiffre d'affaires par catégorie (distribuée)
-- ============================================================
PROMPT === REQUÊTE 5 : CA par catégorie 2026 (requête distribuée) ===

SELECT
    cat.NOMDECATEGORIE,
    SUM(ca.CA_TOTAL) AS CA_TOTAL_2026,
    SUM(ca.NB_LIGNES) AS NB_LIGNES
FROM (
    -- Contribution Site 1 (QUANTITE >= 100)
    SELECT
        p.IDCATEG,
        COUNT(*)                                             AS NB_LIGNES,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes1@site1_link lc
    JOIN Produits1@site1_link       p  ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes1@site1_link      c  ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG

    UNION ALL

    -- Contribution Site 2 (QUANTITE < 100)
    SELECT
        p.IDCATEG,
        COUNT(*)                                             AS NB_LIGNES,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes2@site2_link lc
    JOIN Produits2@site2_link       p  ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes2@site2_link      c  ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG
) ca
JOIN CATEGORIES cat ON ca.IDCATEG = cat.IDCATEG
GROUP BY cat.NOMDECATEGORIE
ORDER BY CA_TOTAL_2026 DESC;

-- ============================================================
-- REQUÊTE 6 — Même requête CA avec synonymes (sans @link)
-- Démontre l'accès transparent grâce aux synonymes
-- ============================================================
PROMPT === REQUÊTE 6 : CA par catégorie via synonymes (transparent) ===

SELECT
    cat.NOMDECATEGORIE,
    SUM(ca.CA_TOTAL) AS CA_TOTAL_2026
FROM (
    SELECT p.IDCATEG,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes1 lc   -- synonyme → Site1
    JOIN Produits1 p ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes1 c ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG
    UNION ALL
    SELECT p.IDCATEG,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes2 lc   -- synonyme → Site2
    JOIN Produits2 p ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes2 c ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG
) ca
JOIN CATEGORIES cat ON ca.IDCATEG = cat.IDCATEG
GROUP BY cat.NOMDECATEGORIE
ORDER BY CA_TOTAL_2026 DESC;

-- ============================================================
-- REQUÊTE 7 — Vérification de la règle de fragmentation
-- Aucun IDLIGNECOMMANDE ne doit apparaître dans les deux sites
-- ============================================================
PROMPT === REQUÊTE 7 : Vérification absence de doublons ===

SELECT
    'Lignes Site1' AS FRAGMENT,
    COUNT(*) AS NB
FROM LigneCommandes1@site1_link
UNION ALL
SELECT
    'Lignes Site2',
    COUNT(*)
FROM LigneCommandes2@site2_link
UNION ALL
SELECT
    'DOUBLONS (attendu=0)',
    COUNT(*)
FROM LigneCommandes1@site1_link lc1
WHERE EXISTS (
    SELECT 1 FROM LigneCommandes2@site2_link lc2
    WHERE lc2.IDLIGNECOMMANDE = lc1.IDLIGNECOMMANDE
);

-- ============================================================
-- ANALYSE : opérations et améliorations apportées
-- ============================================================
PROMPT
PROMPT === ANALYSE DES PLANS D'EXÉCUTION ===
PROMPT
PROMPT  AVANT index :
PROMPT    - FULL TABLE SCAN sur CLIENTS et COMMANDES
PROMPT    - HASH JOIN entre CLIENTS et COMMANDES
PROMPT    - SORT GROUP BY pour le GROUP BY
PROMPT    - SORT ORDER BY pour le ORDER BY DESC
PROMPT
PROMPT  APRÈS index :
PROMPT    - INDEX RANGE SCAN sur idx_cmd_year_func (ou idx_cmd_datecommande)
PROMPT    - NESTED LOOPS ou HASH JOIN avec sonde indexée
PROMPT    - INDEX FAST FULL SCAN possible pour CLIENTS
PROMPT    - Réduction du nombre de Consistent Gets (blocs lus)
PROMPT
PROMPT  Index fonctionnel idx_cmd_year_func :
PROMPT    Résout le problème de non-utilisation des index B-Tree
PROMPT    classiques quand EXTRACT() enveloppe la colonne indexée.
PROMPT    L'optimiseur peut maintenant utiliser l'index directement
PROMPT    pour la prédicat EXTRACT(YEAR FROM DATECOMMANDE) = 2026.
