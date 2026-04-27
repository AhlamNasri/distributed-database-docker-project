-- ============================================================
-- SITE 1 - TESTS (Scenario 2)
-- Tester les procédures CRUD de LigneCommandes1
-- ============================================================

SET SERVEROUTPUT ON;

-- -------------------------------------------------------
-- 1. Insérer données de base (nécessaires pour FK)
-- -------------------------------------------------------

INSERT INTO Categories1 VALUES (1, 'Electronique');
INSERT INTO Categories1 VALUES (2, 'Mobilier');

INSERT INTO Clients1 VALUES (1, 'Dupont', 'Alice', 'alice@mail.com', 'Paris');
INSERT INTO Clients1 VALUES (2, 'Martin', 'Bob',   'bob@mail.com',   'Lyon');

INSERT INTO Produits1 VALUES (1, 'Ordinateur portable', 1200.00, 1);
INSERT INTO Produits1 VALUES (2, 'Bureau ergonomique',  450.00,  2);

INSERT INTO Commandes1 VALUES (1, SYSDATE, 1);
INSERT INTO Commandes1 VALUES (2, SYSDATE, 2);

COMMIT;

-- -------------------------------------------------------
-- 2. Test INSERT valide (Qte >= 100 → OK)
-- -------------------------------------------------------
BEGIN
    insertligne(101, 1, 1, 150, 5);   -- OK : 150 >= 100
    insertligne(102, 1, 2, 200, 0);   -- OK : 200 >= 100
    insertligne(103, 2, 1, 100, 10);  -- OK : exactement 100
END;
/

-- -------------------------------------------------------
-- 3. Test INSERT invalide (Qte < 100 → ERREUR attendue)
-- -------------------------------------------------------
BEGIN
    insertligne(999, 1, 1, 50, 0);  -- DOIT échouer : 50 < 100
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Vérifier les données insérées
-- -------------------------------------------------------
SELECT * FROM LigneCommandes1;

-- -------------------------------------------------------
-- 5. Test UPDATE valide
-- -------------------------------------------------------
BEGIN
    updateligne(101, 1, 300, 10);  -- Modifier Qte à 300
END;
/

SELECT * FROM LigneCommandes1 WHERE idlignecommande = 101;

-- -------------------------------------------------------
-- 6. Test UPDATE invalide (Qte < 100 → ERREUR attendue)
-- -------------------------------------------------------
BEGIN
    updateligne(101, 1, 20, 0);  -- DOIT échouer
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 7. Test DELETE
-- -------------------------------------------------------
BEGIN
    deleteligne(103);  -- Supprimer ligne 103
END;
/

SELECT COUNT(*) AS "Total lignes Site1" FROM LigneCommandes1;

-- -------------------------------------------------------
-- 8. Afficher résumé via procédure SELECT
-- -------------------------------------------------------
BEGIN
    select_lignes_site1;
END;
/
