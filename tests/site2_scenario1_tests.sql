-- ============================================================
-- SITE 2 - TESTS (Scenario 1)
-- Tester les procédures CRUD de LigneCommandes2_sc1
-- Règle fragment : IDCATEG = 35
-- ============================================================

SET SERVEROUTPUT ON;

-- -------------------------------------------------------
-- 0. Nettoyage préalable (si relance du script)
-- -------------------------------------------------------
DELETE FROM LigneCommandes2_sc1;
DELETE FROM Commandes2_sc1;
DELETE FROM Clients2_sc1;
DELETE FROM Produits2_sc1;
DELETE FROM Categories2_sc1;
COMMIT;

-- -------------------------------------------------------
-- 1. Insérer données de base (nécessaires pour FK)
-- -------------------------------------------------------

-- Categories2_sc1 : critère de fragmentation IDCATEG = 35
INSERT INTO Categories2_sc1 (IDCATEG, NOMDECATEGORIE)
VALUES (35, 'Accessoires');

-- Produits2_sc1 : catégorie 35
INSERT INTO Produits2_sc1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                            UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (20, 'Clé USB 128Go', NULL, 35, 19.99, 600, 0, 50, 0);

INSERT INTO Produits2_sc1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                            UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (21, 'Chargeur sans fil', NULL, 35, 34.99, 350, 0, 30, 0);

-- Clients2_sc1
INSERT INTO Clients2_sc1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                           ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (5, 'CLI005', 'Société Epsilon', 'Emma Laurent', 'Directrice Achats',
        '22 bd de Strasbourg', 'Bordeaux', TO_DATE('1992-08-10','YYYY-MM-DD'),
        'Nouvelle-Aquitaine', '33000', 'France', '0656789012', NULL);

INSERT INTO Clients2_sc1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                           ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (6, 'CLI006', 'Société Zeta', 'Franck Dubois', 'Responsable Logistique',
        '17 rue Gambetta', 'Lille', TO_DATE('1987-12-05','YYYY-MM-DD'),
        'Hauts-de-France', '59000', 'France', '0678901234', NULL);

-- Commandes2_sc1
INSERT INTO Commandes2_sc1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                             DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (5, NULL, 5, TO_DATE('2026-05-12','YYYY-MM-DD'),
        TO_DATE('2026-05-20','YYYY-MM-DD'), 5, NULL);

INSERT INTO Commandes2_sc1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                             DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (6, NULL, 6, TO_DATE('2026-06-01','YYYY-MM-DD'),
        TO_DATE('2026-06-10','YYYY-MM-DD'), 6, NULL);

COMMIT;

DBMS_OUTPUT.PUT_LINE('=== Données de base insérées pour Site2 Scenario 1 ===');

-- -------------------------------------------------------
-- 2. Test INSERT valide (produit catégorie 35 + Qte <= 100 → OK)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT valides ---');
BEGIN
    insertligne2_sc1(401, 5, 20, 45, 0);
    insertligne2_sc1(402, 5, 21, 80, 5);
    insertligne2_sc1(403, 6, 20, 30, 10);
END;
/

-- Vérification
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes2_sc1 ORDER BY IDLIGNECOMMANDE;

-- -------------------------------------------------------
-- 3. Test INSERT invalide (produit hors catégorie 35 → ERREUR)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (produit hors catégorie 35) ---');
BEGIN
    insertligne2_sc1(999, 5, 10, 50, 0);  -- Produit catégorie 50
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Test INSERT invalide (commande inexistante → ERREUR)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (commande inexistante) ---');
BEGIN
    insertligne2_sc1(998, 999, 20, 40, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 5. Test INSERT invalide (doublon PK → ERREUR)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (doublon PK) ---');
BEGIN
    insertligne2_sc1(401, 5, 20, 50, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur doublon attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 6. Test UPDATE valide
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE valide ---');
BEGIN
    updateligne2_sc1(401, 21, 90, 15);
END;
/

SELECT IDLIGNECOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes2_sc1 WHERE IDLIGNECOMMANDE = 401;

-- -------------------------------------------------------
-- 7. Test UPDATE invalide (produit hors catégorie 35 → ERREUR)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE invalide (mauvaise catégorie) ---');
BEGIN
    updateligne2_sc1(401, 10, 50, 0);   -- Produit catégorie 50
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 8. Test UPDATE invalide (ligne inexistante → ERREUR)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE invalide (ligne inexistante) ---');
BEGIN
    updateligne2_sc1(9999, 20, 40, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 9. Test DELETE valide (cascade commande vide)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE valide (cascade commande) ---');
BEGIN
    deleteligne2_sc1(403);  -- Dernière ligne de commande 6
END;
/

SELECT COUNT(*) AS "Total lignes Site2 sc1" FROM LigneCommandes2_sc1;
SELECT COUNT(*) AS "Commande 6 encore presente" FROM Commandes2_sc1 WHERE IDCOMMANDE = 6;

-- -------------------------------------------------------
-- 10. Test DELETE valide (commande conservée)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE valide (commande conservée) ---');
BEGIN
    deleteligne2_sc1(402);
END;
/

SELECT COUNT(*) AS "Commande 5 encore presente" FROM Commandes2_sc1 WHERE IDCOMMANDE = 5;

-- -------------------------------------------------------
-- 11. Test DELETE invalide (ligne inexistante)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE invalide ---');
BEGIN
    deleteligne2_sc1(9999);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur DELETE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 12. Test TRIGGER INSERT bloqué (mauvaise catégorie)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test TRIGGER INSERT bloqué (catégorie) ---');
BEGIN
    INSERT INTO LigneCommandes2_sc1 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (997, 5, 10, 50, 0);   -- Produit hors catégorie 35
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Trigger INSERT bloqué : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 13. Test TRIGGER INSERT bloqué (quantité > 100)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test TRIGGER INSERT bloqué (quantité) ---');
BEGIN
    INSERT INTO LigneCommandes2_sc1 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (996, 5, 20, 150, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Trigger INSERT bloqué (Qte) : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 14. Résumé final
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Résumé final Site2 Scenario 1 ---');
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes2_sc1 ORDER BY IDLIGNECOMMANDE;

SELECT COUNT(*) AS "Lignes restantes" FROM LigneCommandes2_sc1;
SELECT COUNT(*) AS "Commandes restantes" FROM Commandes2_sc1;
SELECT COUNT(*) AS "Logs enregistrés" FROM LOG_SITE2_SC1;