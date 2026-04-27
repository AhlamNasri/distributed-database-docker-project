-- ============================================================
-- SITE 1 - PROCÉDURES STOCKÉES (Scenario 2)
-- CRUD sur LigneCommandes1
-- À exécuter sur : Docker container site1 (port 1522)
-- ============================================================

-- -------------------------------------------------------
-- 1. INSERT : Ajouter une ligne commande dans Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE insertligne (
    p_id        IN LigneCommandes1.idlignecommande%TYPE,
    p_idcmd     IN LigneCommandes1.idcommande%TYPE,
    p_idprod    IN LigneCommandes1.idproduit%TYPE,
    p_qte       IN LigneCommandes1.quantite%TYPE,
    p_remise    IN LigneCommandes1.remise%TYPE DEFAULT 0
) AS
BEGIN
    -- Vérification règle de fragmentation
    IF p_qte < 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'SITE1 ERROR: Quantite ' || p_qte || ' < 100. Cette ligne appartient à Site2.');
    END IF;

    INSERT INTO LigneCommandes1 (idlignecommande, idcommande, idproduit, quantite, remise)
    VALUES (p_id, p_idcmd, p_idprod, p_qte, p_remise);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✔ Ligne ' || p_id || ' insérée dans Site1 (Qte=' || p_qte || ')');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ligne ' || p_id || ' existe déjà dans Site1.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END insertligne;
/

-- -------------------------------------------------------
-- 2. UPDATE : Modifier une ligne commande dans Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE updateligne (
    p_id        IN NUMBER,
    p_idprod    IN NUMBER,
    p_qte       IN NUMBER,
    p_remise    IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    -- Vérifier que la ligne existe
    SELECT COUNT(*) INTO v_count
    FROM LigneCommandes1
    WHERE idlignecommande = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ligne ' || p_id || ' introuvable dans Site1.');
    END IF;

    -- Vérifier règle de fragmentation
    IF p_qte < 100 THEN
        RAISE_APPLICATION_ERROR(-20004, 
            'SITE1 ERROR: Nouvelle quantité ' || p_qte || ' < 100. Doit rester >= 100 dans Site1.');
    END IF;

    UPDATE LigneCommandes1
    SET idproduit = p_idprod,
        quantite  = p_qte,
        remise    = p_remise
    WHERE idlignecommande = p_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✔ Ligne ' || p_id || ' mise à jour dans Site1.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END updateligne;
/

-- -------------------------------------------------------
-- 3. DELETE : Supprimer une ligne commande de Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE deleteligne (
    p_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM LigneCommandes1
    WHERE idlignecommande = p_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Ligne ' || p_id || ' introuvable dans Site1.');
    END IF;

    DELETE FROM LigneCommandes1
    WHERE idlignecommande = p_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✔ Ligne ' || p_id || ' supprimée de Site1.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END deleteligne;
/

-- -------------------------------------------------------
-- 4. SELECT : Consulter les lignes de Site1
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE select_lignes_site1 AS
BEGIN
    FOR rec IN (
        SELECT lc.idlignecommande, lc.idcommande, lc.idproduit,
               lc.quantite, lc.remise,
               p.libproduit, p.prixunitaire,
               (lc.quantite * p.prixunitaire * (1 - lc.remise/100)) AS montant
        FROM LigneCommandes1 lc
        JOIN Produits1 p ON lc.idproduit = p.idproduit
        ORDER BY lc.idlignecommande
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Ligne=' || rec.idlignecommande ||
            ' | Cmd=' || rec.idcommande ||
            ' | Produit=' || rec.libproduit ||
            ' | Qte=' || rec.quantite ||
            ' | Montant=' || ROUND(rec.montant, 2)
        );
    END LOOP;
END select_lignes_site1;
/

COMMIT;
