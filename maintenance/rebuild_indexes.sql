-- ============================================================
-- rebuild_indexes.sql
-- Reconstruction des index fragmentés
-- À exécuter après des lots d'insertions/suppressions massives
-- ============================================================

SET SERVEROUTPUT ON

DECLARE
    PROCEDURE rebuild_if_exists(p_index_name VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM USER_INDEXES WHERE INDEX_NAME = UPPER(p_index_name);

        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER INDEX ' || p_index_name || ' REBUILD';
            DBMS_OUTPUT.PUT_LINE('  ✓ Reconstruit : ' || p_index_name);
        ELSE
            DBMS_OUTPUT.PUT_LINE('  - Absent (skipped) : ' || p_index_name);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  ✗ ERREUR ' || p_index_name || ' : ' || SQLERRM);
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== REBUILD DES INDEX — ' ||
        TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS') || ' ===');

    -- ---- Index Scénario 2 Site1 ----
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- LigneCommandes1 --');
    rebuild_if_exists('IDX_LC1_QUANTITE');
    rebuild_if_exists('IDX_LC1_IDCOMMANDE');
    rebuild_if_exists('IDX_LC1_IDPRODUIT');
    rebuild_if_exists('IDX_LC1_CMD_QTE');

    DBMS_OUTPUT.PUT_LINE('-- Commandes1 --');
    rebuild_if_exists('IDX_CMD1_IDCLIENT');
    rebuild_if_exists('IDX_CMD1_DATE');

    DBMS_OUTPUT.PUT_LINE('-- Produits1 --');
    rebuild_if_exists('IDX_PROD1_IDCATEG');
    rebuild_if_exists('IDX_PROD1_PRIX');

    DBMS_OUTPUT.PUT_LINE('-- Clients1 --');
    rebuild_if_exists('IDX_CLI1_PAYS');
    rebuild_if_exists('IDX_CLI1_VILLE');

    -- ---- Index Scénario 1 Site1 ----
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- LigneCommandes1_sc1 --');
    rebuild_if_exists('IDX_LC1SC1_IDPRODUIT');
    rebuild_if_exists('IDX_LC1SC1_IDCOMMANDE');
    rebuild_if_exists('IDX_LC1SC1_PROD_CMD');

    DBMS_OUTPUT.PUT_LINE('-- Produits1_sc1 --');
    rebuild_if_exists('IDX_PROD1SC1_IDCATEG');
    rebuild_if_exists('IDX_PROD1SC1_PRIX');
    rebuild_if_exists('IDX_PROD1SC1_IDFOUR');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== Rebuild terminé ===');
END;
/

-- Vérification : état de tous les index après rebuild
SELECT INDEX_NAME, STATUS, LAST_ANALYZED
FROM USER_INDEXES
WHERE TABLE_NAME IN (
    'LIGNECOMMANDES1','COMMANDES1','PRODUITS1','CLIENTS1',
    'LIGNECOMMANDES1_SC1','COMMANDES1_SC1','PRODUITS1_SC1','CLIENTS1_SC1'
)
ORDER BY TABLE_NAME, INDEX_NAME;
