-- ============================================================
-- purge_logs.sql
-- Purge des tables de log — supprime les entrées > 30 jours
-- À exécuter manuellement ou planifier avec DBMS_SCHEDULER
-- ============================================================

SET SERVEROUTPUT ON

DECLARE
    v_seuil     TIMESTAMP := SYSTIMESTAMP - INTERVAL '30' DAY;
    v_deleted   NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PURGE DES LOGS — seuil : ' ||
        TO_CHAR(v_seuil,'DD/MM/YYYY HH24:MI:SS') || ' ===');

    -- ---- LOG_SITE1 ----
    SELECT COUNT(*) INTO v_deleted FROM LOG_SITE1 WHERE DATE_OPERATION < v_seuil;
    DELETE FROM LOG_SITE1 WHERE DATE_OPERATION < v_seuil;
    DBMS_OUTPUT.PUT_LINE('LOG_SITE1 : ' || v_deleted || ' entrée(s) supprimée(s)');

    -- ---- LOG_SITE1_SC1 ----
    SELECT COUNT(*) INTO v_deleted FROM LOG_SITE1_SC1 WHERE DATE_OPERATION < v_seuil;
    DELETE FROM LOG_SITE1_SC1 WHERE DATE_OPERATION < v_seuil;
    DBMS_OUTPUT.PUT_LINE('LOG_SITE1_SC1 : ' || v_deleted || ' entrée(s) supprimée(s)');

    -- ---- LOG_SITE2 ----
    SELECT COUNT(*) INTO v_deleted FROM LOG_SITE2 WHERE DATE_OPERATION < v_seuil;
    DELETE FROM LOG_SITE2 WHERE DATE_OPERATION < v_seuil;
    DBMS_OUTPUT.PUT_LINE('LOG_SITE2 : ' || v_deleted || ' entrée(s) supprimée(s)');

    -- ---- LOG_SITE2_SC1 ----
    SELECT COUNT(*) INTO v_deleted FROM LOG_SITE2_SC1 WHERE DATE_OPERATION < v_seuil;
    DELETE FROM LOG_SITE2_SC1 WHERE DATE_OPERATION < v_seuil;
    DBMS_OUTPUT.PUT_LINE('LOG_SITE2_SC1 : ' || v_deleted || ' entrée(s) supprimée(s)');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== Purge terminée ===');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR lors de la purge : ' || SQLERRM);
        RAISE;
END;
/

-- Vérification des volumes restants
SELECT 'LOG_SITE1'     AS TABLE_NAME, COUNT(*) AS LIGNES_RESTANTES FROM LOG_SITE1     UNION ALL
SELECT 'LOG_SITE1_SC1' AS TABLE_NAME, COUNT(*) AS LIGNES_RESTANTES FROM LOG_SITE1_SC1 UNION ALL
SELECT 'LOG_SITE2'     AS TABLE_NAME, COUNT(*) AS LIGNES_RESTANTES FROM LOG_SITE2     UNION ALL
SELECT 'LOG_SITE2_SC1' AS TABLE_NAME, COUNT(*) AS LIGNES_RESTANTES FROM LOG_SITE2_SC1;
