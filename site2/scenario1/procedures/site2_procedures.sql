-- ============================================================
-- SITE 2 - PROCÉDURES STOCKÉES (Scenario 1)
-- Règle fragment : IDCATEG = 35
-- ============================================================

CREATE OR REPLACE PROCEDURE insertligne2_sc1 (
    p_id        IN LigneCommandes2_sc1.IDLIGNECOMMANDE%TYPE,
    p_idcmd     IN LigneCommandes2_sc1.IDCOMMANDE%TYPE,
    p_idprod    IN LigneCommandes2_sc1.IDPRODUIT%TYPE,
    p_qte       IN LigneCommandes2_sc1.QUANTITE%TYPE,
    p_remise    IN LigneCommandes2_sc1.REMISE%TYPE DEFAULT 0
) AS
    v_cmd_count  NUMBER;
    v_prod_count NUMBER;
BEGIN
    -- Vérification règle de fragmentation : produit catégorie 35
    SELECT COUNT(*) INTO v_prod_count
    FROM Produits2_sc1 WHERE IDPRODUIT = p_idprod;

    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'SITE2 SC1 ERROR: Produit ' || p_idprod || ' n''appartient pas à la catégorie 35. Appartient à Site1.');
    END IF;

    SELECT COUNT(*) INTO v_cmd_count
    FROM Commandes2_sc1 WHERE IDCOMMANDE = p_idcmd;

    IF v_cmd_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Commande ' || p_idcmd || ' introuvable dans Site2 (sc1).');
    END IF;

    INSERT INTO LigneCommandes2_sc1 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (p_id, p_idcmd, p_idprod, p_qte, p_remise);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' inseree dans Site2 sc1 (Produit categ=35)');

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20004, 'Ligne ' || p_id || ' existe deja dans Site2 sc1.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END insertligne2_sc1;
/

CREATE OR REPLACE PROCEDURE updateligne2_sc1 (
    p_id     IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER
) AS
    v_count      NUMBER;
    v_prod_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM LigneCommandes2_sc1 WHERE IDLIGNECOMMANDE = p_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Ligne ' || p_id || ' introuvable dans Site2 sc1.');
    END IF;

    SELECT COUNT(*) INTO v_prod_count FROM Produits2_sc1 WHERE IDPRODUIT = p_idprod;
    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'SITE2 SC1 ERROR: Produit ' || p_idprod || ' n''est pas de catégorie 35. Modifier sur Site1.');
    END IF;

    UPDATE LigneCommandes2_sc1
    SET IDPRODUIT = p_idprod,
        QUANTITE  = p_qte,
        REMISE    = p_remise
    WHERE IDLIGNECOMMANDE = p_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' mise a jour dans Site2 sc1.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END updateligne2_sc1;
/

CREATE OR REPLACE PROCEDURE deleteligne2_sc1 (
    p_id IN NUMBER
) AS
    v_count     NUMBER;
    v_idcmd     NUMBER;
    v_cmd_count NUMBER;
BEGIN
    SELECT COUNT(*), MAX(IDCOMMANDE) INTO v_count, v_idcmd
    FROM LigneCommandes2_sc1 WHERE IDLIGNECOMMANDE = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Ligne ' || p_id || ' introuvable dans Site2 sc1.');
    END IF;

    DELETE FROM LigneCommandes2_sc1 WHERE IDLIGNECOMMANDE = p_id;

    SELECT COUNT(*) INTO v_cmd_count FROM LigneCommandes2_sc1 WHERE IDCOMMANDE = v_idcmd;

    IF v_cmd_count = 0 THEN
        DELETE FROM Commandes2_sc1 WHERE IDCOMMANDE = v_idcmd;
        DBMS_OUTPUT.PUT_LINE('OK - Commande ' || v_idcmd || ' supprimee (plus de lignes).');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' supprimee de Site2 sc1.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END deleteligne2_sc1;
/