#!/bin/bash
# ============================================================
# site2_procedures.sh — Procédures stockées Site2 Scénario 2
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# ============================================================
echo "[site2_procedures.sh] Creating procedures as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE OR REPLACE PROCEDURE insertligne2 (
    p_id        IN LIGNECOMMANDES2.IDLIGNECOMMANDE%TYPE,
    p_idcmd     IN LIGNECOMMANDES2.IDCOMMANDE%TYPE,
    p_idprod    IN LIGNECOMMANDES2.IDPRODUIT%TYPE,
    p_qte       IN LIGNECOMMANDES2.QUANTITE%TYPE,
    p_remise    IN LIGNECOMMANDES2.REMISE%TYPE DEFAULT 0
) AS
    v_cmd_count  NUMBER;
    v_prod_count NUMBER;
BEGIN
    IF p_qte >= 100 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'SITE2 ERROR: Quantite ' || p_qte || ' >= 100. Cette ligne appartient a Site1.');
    END IF;
    SELECT COUNT(*) INTO v_cmd_count FROM COMMANDES2 WHERE IDCOMMANDE = p_idcmd;
    IF v_cmd_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Commande ' || p_idcmd || ' introuvable dans Site2.');
    END IF;
    SELECT COUNT(*) INTO v_prod_count FROM PRODUITS2 WHERE IDPRODUIT = p_idprod;
    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Produit ' || p_idprod || ' introuvable dans Site2.');
    END IF;
    INSERT INTO LIGNECOMMANDES2 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (p_id, p_idcmd, p_idprod, p_qte, p_remise);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' inseree dans Site2 (Qte=' || p_qte || ')');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20004, 'Ligne ' || p_id || ' existe deja dans Site2.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END insertligne2;
/

CREATE OR REPLACE PROCEDURE updateligne2 (
    p_id     IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER
) AS
    v_count      NUMBER;
    v_prod_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LIGNECOMMANDES2 WHERE IDLIGNECOMMANDE = p_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Ligne ' || p_id || ' introuvable dans Site2.');
    END IF;
    IF p_qte >= 100 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'SITE2 ERROR: Nouvelle quantite ' || p_qte || ' >= 100. Modifier sur Site1.');
    END IF;
    SELECT COUNT(*) INTO v_prod_count FROM PRODUITS2 WHERE IDPRODUIT = p_idprod;
    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Produit ' || p_idprod || ' introuvable dans Site2.');
    END IF;
    UPDATE LIGNECOMMANDES2
    SET IDPRODUIT = p_idprod, QUANTITE = p_qte, REMISE = p_remise
    WHERE IDLIGNECOMMANDE = p_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' mise a jour dans Site2.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END updateligne2;
/

CREATE OR REPLACE PROCEDURE deleteligne2 (
    p_id IN NUMBER
) AS
    v_count     NUMBER;
    v_idcmd     NUMBER;
    v_cmd_count NUMBER;
BEGIN
    SELECT COUNT(*), MAX(IDCOMMANDE) INTO v_count, v_idcmd
    FROM LIGNECOMMANDES2 WHERE IDLIGNECOMMANDE = p_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Ligne ' || p_id || ' introuvable dans Site2.');
    END IF;
    DELETE FROM LIGNECOMMANDES2 WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_cmd_count FROM LIGNECOMMANDES2 WHERE IDCOMMANDE = v_idcmd;
    IF v_cmd_count = 0 THEN
        DELETE FROM COMMANDES2 WHERE IDCOMMANDE = v_idcmd;
        DBMS_OUTPUT.PUT_LINE('OK - Commande ' || v_idcmd || ' supprimee (plus de lignes).');
    END IF;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' supprimee de Site2.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END deleteligne2;
/

EXIT;
SQLEOF

echo "[site2_procedures.sh] Done."
