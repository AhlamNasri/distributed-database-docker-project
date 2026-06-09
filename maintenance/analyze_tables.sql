-- ============================================================
-- analyze_tables.sql
-- Collecte des statistiques pour l'optimiseur Oracle (CBO)
-- À exécuter après chargement initial ou modifications massives
-- ============================================================

SET SERVEROUTPUT ON

DECLARE
    PROCEDURE analyze_table_if_exists(p_table_name VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM USER_TABLES WHERE TABLE_NAME = UPPER(p_table_name);

        IF v_count > 0 THEN
            DBMS_STATS.GATHER_TABLE_STATS(
                ownname   => USER,
                tabname   => p_table_name,
                cascade   => TRUE,     -- analyse aussi les index
                estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                method_opt => 'FOR ALL INDEXED COLUMNS SIZE AUTO'
            );
            DBMS_OUTPUT.PUT_LINE('  ✓ Analysé : ' || p_table_name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('  - Absent : ' || p_table_name);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  ✗ ERREUR ' || p_table_name || ' : ' || SQLERRM);
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ANALYSE DES STATISTIQUES — ' ||
        TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS') || ' ===');

    -- Tables globales
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- Tables globales --');
    analyze_table_if_exists('CATEGORIES');
    analyze_table_if_exists('FOURNISSEURS');
    analyze_table_if_exists('EMPLOYES');
    analyze_table_if_exists('CLIENTS');
    analyze_table_if_exists('PRODUITS');
    analyze_table_if_exists('COMMANDES');
    analyze_table_if_exists('LIGNECOMMANDES');

    -- Fragments Scénario 2
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- Fragments Scénario 2 --');
    analyze_table_if_exists('LIGNECOMMANDES1');
    analyze_table_if_exists('COMMANDES1');
    analyze_table_if_exists('CLIENTS1');
    analyze_table_if_exists('PRODUITS1');

    -- Fragments Scénario 1
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- Fragments Scénario 1 --');
    analyze_table_if_exists('LIGNECOMMANDES1_SC1');
    analyze_table_if_exists('COMMANDES1_SC1');
    analyze_table_if_exists('CLIENTS1_SC1');
    analyze_table_if_exists('PRODUITS1_SC1');
    analyze_table_if_exists('CATEGORIES1_SC1');

    -- Tables de log
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- Tables de log --');
    analyze_table_if_exists('LOG_SITE1');
    analyze_table_if_exists('LOG_SITE1_SC1');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== Analyse terminée ===');
END;
/

-- Vérification des statistiques collectées
SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
FROM USER_TABLES
WHERE TABLE_NAME IN (
    'LIGNECOMMANDES','LIGNECOMMANDES1','LIGNECOMMANDES1_SC1',
    'COMMANDES','COMMANDES1','COMMANDES1_SC1',
    'PRODUITS','PRODUITS1','PRODUITS1_SC1',
    'CLIENTS','CLIENTS1','CLIENTS1_SC1'
)
ORDER BY TABLE_NAME;
