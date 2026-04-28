-- ============================================================
-- SITE 1 - TESTS (Scenario 2)
-- Tester les procédures CRUD de LigneCommandes1
-- Règle fragment : QUANTITE >= 100
-- ============================================================

SET SERVEROUTPUT ON;

-- -------------------------------------------------------
-- 0. Nettoyage préalable (si relance du script)
-- -------------------------------------------------------
DELETE FROM LigneCommandes1;
DELETE FROM Commandes1;
DELETE FROM Clients1;
DELETE FROM Produits1;
COMMIT;

-- -------------------------------------------------------
-- 1. Insérer données de base (nécessaires pour FK)
--    Respect des schémas réels issus de eshop_global.sql
-- -------------------------------------------------------

-- Clients1 : (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
--             ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
INSERT INTO Clients1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                      ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (1, 'CLI001', 'Société Alpha', 'Alice Dupont', 'Directrice',
        '12 rue de Paris', 'Paris', TO_DATE('1985-03-20','YYYY-MM-DD'),
        'Île-de-France', '75001', 'France', '0601020304', NULL);

INSERT INTO Clients1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                      ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (2, 'CLI002', 'Société Beta', 'Bob Martin', 'Responsable Achat',
        '5 avenue Foch', 'Lyon', TO_DATE('1979-07-11','YYYY-MM-DD'),
        'Auvergne-Rhône-Alpes', '69001', 'France', '0611223344', NULL);

-- Produits1 : (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
--              UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
-- Note: IDFOUR et IDCATEG sont NULLables (pas de FK vers Fournisseurs/Categories dans les fragments)
INSERT INTO Produits1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                       UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (1, 'Ordinateur portable', NULL, NULL, 1200.00, 500, 0, 50, 0);

INSERT INTO Produits1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                       UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (2, 'Bureau ergonomique', NULL, NULL, 450.00, 200, 0, 20, 0);

-- Commandes1 : (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
--               DATELIVRAISON, NMESSAGER, PORTNUMBER)
-- Note: IDEMPLOYE NULLable (pas de FK vers Employes dans les fragments)
-- DATELIVRAISON >= DATECOMMANDE (contrainte CHECK du schéma global)
INSERT INTO Commandes1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                        DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (1, NULL, 1, TO_DATE('2026-01-10','YYYY-MM-DD'),
        TO_DATE('2026-01-20','YYYY-MM-DD'), 1, NULL);

INSERT INTO Commandes1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                        DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (2, NULL, 2, TO_DATE('2026-02-05','YYYY-MM-DD'),
        TO_DATE('2026-02-15','YYYY-MM-DD'), 2, NULL);

COMMIT;

DBMS_OUTPUT.PUT_LINE('=== Données de base insérées ===');

-- -------------------------------------------------------
-- 2. Test INSERT valide (Qte >= 100 → OK)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT valides ---');
BEGIN
    insertligne(101, 1, 1, 150, 5);   -- OK : 150 >= 100
    insertligne(102, 1, 2, 200, 0);   -- OK : 200 >= 100
    insertligne(103, 2, 1, 100, 10);  -- OK : exactement 100
END;
/

-- Vérification
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1
ORDER BY IDLIGNECOMMANDE;

-- -------------------------------------------------------
-- 3. Test INSERT invalide (Qte < 100 → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (Qte < 100) ---');
BEGIN
    insertligne(999, 1, 1, 50, 0);  -- DOIT échouer : 50 < 100
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Test INSERT invalide (commande inexistante → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (commande inexistante) ---');
BEGIN
    insertligne(998, 999, 1, 150, 0);  -- DOIT échouer : commande 999 n'existe pas
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 5. Test UPDATE valide
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE valide ---');
BEGIN
    updateligne(101, 1, 300, 10);  -- Modifier Qte à 300, remise à 10
END;
/

SELECT IDLIGNECOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1
WHERE IDLIGNECOMMANDE = 101;

-- -------------------------------------------------------
-- 6. Test UPDATE invalide (Qte < 100 → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE invalide (Qte < 100) ---');
BEGIN
    updateligne(101, 1, 20, 0);  -- DOIT échouer : 20 < 100
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 7. Test UPDATE invalide (ligne inexistante → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE invalide (ligne inexistante) ---');
BEGIN
    updateligne(9999, 1, 150, 0);  -- DOIT échouer : ligne 9999 n'existe pas
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 8. Test DELETE valide
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE valide ---');
BEGIN
    deleteligne(103);  -- Supprimer ligne 103 (dernière ligne de commande 2)
    -- La commande 2 n'aura plus de lignes → doit être supprimée aussi
END;
/

SELECT COUNT(*) AS "Total lignes Site1" FROM LigneCommandes1;
-- Commande 2 doit avoir disparu :
SELECT COUNT(*) AS "Commande 2 encore presente" FROM Commandes1 WHERE IDCOMMANDE = 2;

-- -------------------------------------------------------
-- 9. Test DELETE invalide (ligne inexistante → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE invalide (ligne inexistante) ---');
BEGIN
    deleteligne(9999);  -- DOIT échouer : ligne 9999 n'existe pas
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur DELETE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 10. Résumé final
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Résumé final ---');
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1
ORDER BY IDLIGNECOMMANDE;
