-- ============================================================
-- SITE 1 - PROCÉDURES STOCKÉES (Scenario 1)
-- Règle fragment : IDCATEG = 50
-- Tables : LigneCommandes1_sc1, Commandes1_sc1, Clients1_sc1,
--          Produits1_sc1, Categories1_sc1
-- ============================================================

-- -------------------------------------------------------
-- 1. insertligne_sc1 : Insérer une ligne de commande dans Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE insertligne_sc1 (
    p_id        IN LigneCommandes1_sc1.IDLIGNECOMMANDE%TYPE,
    p_idcmd     IN LigneCommandes1_sc1.IDCOMMANDE%TYPE,
    p_idprod    IN LigneCommandes1_sc1.IDPRODUIT%TYPE,
    p_qte       IN LigneCommandes1_sc1.QUANTITE%TYPE,
    p_remise    IN LigneCommandes1_sc1.REMISE%TYPE DEFAULT 0
) AS
    v_cmd_count  NUMBER;
    v_prod_count NUMBER;
BEGIN
    -- Vérification règle de fragmentation : produit doit être de catégorie 50
    SELECT COUNT(*) INTO v_prod_count
    FROM Produits1_sc1 WHERE IDPRODUIT = p_idprod;

    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'SITE1 SC1 ERROR: Produit ' || p_idprod || ' n''appartient pas à la catégorie 50. Appartient à Site2.');
    END IF;

    -- Vérification contrainte référentielle : commande existe
    SELECT COUNT(*) INTO v_cmd_count
    FROM Commandes1_sc1 WHERE IDCOMMANDE = p_idcmd;

    IF v_cmd_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Commande ' || p_idcmd || ' introuvable dans Site1 (sc1).');
    END IF;

    INSERT INTO LigneCommandes1_sc1 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (p_id, p_idcmd, p_idprod, p_qte, p_remise);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' inseree dans Site1 sc1 (Produit categ=50)');

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20004, 'Ligne ' || p_id || ' existe deja dans Site1 sc1.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END insertligne_sc1;
/

-- -------------------------------------------------------
-- 2. updateligne_sc1 : Modifier une ligne de commande dans Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE updateligne_sc1 (
    p_id     IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER
) AS
    v_count      NUMBER;
    v_prod_count NUMBER;
BEGIN
    -- Vérifier que la ligne existe
    SELECT COUNT(*) INTO v_count
    FROM LigneCommandes1_sc1
    WHERE IDLIGNECOMMANDE = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Ligne ' || p_id || ' introuvable dans Site1 sc1.');
    END IF;

    -- Vérifier que le nouveau produit est bien de catégorie 50
    SELECT COUNT(*) INTO v_prod_count
    FROM Produits1_sc1 WHERE IDPRODUIT = p_idprod;

    IF v_prod_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'SITE1 SC1 ERROR: Produit ' || p_idprod || ' n''est pas de catégorie 50. Modifier sur Site2.');
    END IF;

    UPDATE LigneCommandes1_sc1
    SET IDPRODUIT = p_idprod,
        QUANTITE  = p_qte,
        REMISE    = p_remise
    WHERE IDLIGNECOMMANDE = p_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' mise a jour dans Site1 sc1.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END updateligne_sc1;
/

-- -------------------------------------------------------
-- 3. deleteligne_sc1 : Supprimer une ligne de commande de Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE deleteligne_sc1 (
    p_id IN NUMBER
) AS
    v_count     NUMBER;
    v_idcmd     NUMBER;
    v_cmd_count NUMBER;
BEGIN
    -- Vérifier que la ligne existe
    SELECT COUNT(*), MAX(IDCOMMANDE) INTO v_count, v_idcmd
    FROM LigneCommandes1_sc1
    WHERE IDLIGNECOMMANDE = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Ligne ' || p_id || ' introuvable dans Site1 sc1.');
    END IF;

    -- Supprimer la ligne
    DELETE FROM LigneCommandes1_sc1
    WHERE IDLIGNECOMMANDE = p_id;

    -- Si la commande n'a plus de lignes, supprimer la commande
    SELECT COUNT(*) INTO v_cmd_count
    FROM LigneCommandes1_sc1
    WHERE IDCOMMANDE = v_idcmd;

    IF v_cmd_count = 0 THEN
        DELETE FROM Commandes1_sc1 WHERE IDCOMMANDE = v_idcmd;
        DBMS_OUTPUT.PUT_LINE('OK - Commande ' || v_idcmd || ' supprimee (plus de lignes).');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK - Ligne ' || p_id || ' supprimee de Site1 sc1.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END deleteligne_sc1;
/
