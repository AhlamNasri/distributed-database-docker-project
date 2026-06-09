-- ============================================================
-- check_dblinks.sql
-- Script de surveillance des Database Links
-- À exécuter sur oracle-central (eshopcentral@BDDCENTRAL)
-- ============================================================

SET SERVEROUTPUT ON
SET LINESIZE 120
SET PAGESIZE 40

PROMPT ====================================================
PROMPT  VERIFICATION DES DATABASE LINKS — oracle-central
PROMPT ====================================================

-- -------------------------------------------------------
-- 1. Liste des liens déclarés dans le dictionnaire
-- -------------------------------------------------------
PROMPT
PROMPT Liens déclarés (USER_DB_LINKS)
SELECT DB_LINK, USERNAME, HOST, CREATED
FROM USER_DB_LINKS
ORDER BY DB_LINK;

-- -------------------------------------------------------
-- 2. Test de connectivité Site1
-- -------------------------------------------------------
PROMPT
PROMPT Test connexion Site1 (site1_link)
DECLARE
    v_count NUMBER;
    v_result VARCHAR2(100);
BEGIN
    SELECT COUNT(*) INTO v_count FROM LigneCommandes1@site1_link;
    v_result := 'OK — ' || v_count || ' ligne(s) dans LigneCommandes1@Site1';
    DBMS_OUTPUT.PUT_LINE('Site1 : ' || v_result);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Site1 ERREUR : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 3. Test de connectivité Site2
-- -------------------------------------------------------
DECLARE
    v_count NUMBER;
    v_result VARCHAR2(100);
BEGIN
    SELECT COUNT(*) INTO v_count FROM LigneCommandes2@site2_link;
    v_result := 'OK — ' || v_count || ' ligne(s) dans LigneCommandes2@Site2';
    DBMS_OUTPUT.PUT_LINE('Site2 : ' || v_result);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Site2 ERREUR : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Compte global via les deux liens
-- -------------------------------------------------------
PROMPT
PROMPT Comptage global via la vue distribuée
SELECT
    'SITE1' AS SITE,
    COUNT(*) AS NB_LIGNES,
    MIN(QUANTITE) AS QTE_MIN,
    MAX(QUANTITE) AS QTE_MAX,
    SUM(QUANTITE) AS QTE_TOTAL
FROM LigneCommandes1@site1_link
UNION ALL
SELECT
    'SITE2' AS SITE,
    COUNT(*) AS NB_LIGNES,
    MIN(QUANTITE) AS QTE_MIN,
    MAX(QUANTITE) AS QTE_MAX,
    SUM(QUANTITE) AS QTE_TOTAL
FROM LigneCommandes2@site2_link;

-- -------------------------------------------------------
-- 5. Vérification de la règle de fragmentation
--    (aucune ligne ne doit être dans les deux sites)
-- -------------------------------------------------------
PROMPT
PROMPT Vérification absence de doublons inter-sites
SELECT COUNT(*) AS DOUBLONS_ATTENDUS_0
FROM LigneCommandes1@site1_link lc1
WHERE EXISTS (
    SELECT 1
    FROM LigneCommandes2@site2_link lc2
    WHERE lc2.IDLIGNECOMMANDE = lc1.IDLIGNECOMMANDE
);

-- -------------------------------------------------------
-- 6. Latence estimée des requêtes distantes
-- -------------------------------------------------------
PROMPT
PROMPT Latence réseau estimée
DECLARE
    t_start TIMESTAMP;
    t_end   TIMESTAMP;
    v_dummy NUMBER;
BEGIN
    t_start := SYSTIMESTAMP;
    SELECT COUNT(*) INTO v_dummy FROM DUAL@site1_link;
    t_end := SYSTIMESTAMP;
    DBMS_OUTPUT.PUT_LINE('Latence Site1 : ' ||
        EXTRACT(SECOND FROM (t_end - t_start)) * 1000 || ' ms (approx)');

    t_start := SYSTIMESTAMP;
    SELECT COUNT(*) INTO v_dummy FROM DUAL@site2_link;
    t_end := SYSTIMESTAMP;
    DBMS_OUTPUT.PUT_LINE('Latence Site2 : ' ||
        EXTRACT(SECOND FROM (t_end - t_start)) * 1000 || ' ms (approx)');
END;
/

PROMPT
PROMPT ====================================================
PROMPT  Vérification terminée
PROMPT ====================================================
