-- ============================================================
-- SITE 2 - TESTS (Scenario 2)
-- Tester les procédures CRUD de LigneCommandes2
-- Règle fragment : QUANTITE < 100
-- ============================================================

SET SERVEROUTPUT ON;

-- -------------------------------------------------------
-- 0. Nettoyage préalable (si relance du script)
-- -------------------------------------------------------
DELETE FROM LigneCommandes2;
DELETE FROM Commandes2;
DELETE FROM Clients2;
DELETE FROM Produits2;
COMMIT;

-- -------------------------------------------------------
-- 1. Insérer données de base (nécessaires pour FK)
-- -------------------------------------------------------

-- Clients2
INSERT INTO Clients2 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                      ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (3, 'CLI003', 'Société Gamma', 'Charlie Petit', 'Acheteur',
        '8 rue de la Paix', 'Marseille', TO_DATE('1990-05-15','YYYY-MM-DD'),
        'Provence-Alpes-Côte d''Azur', '13001', 'France', '0612345678', NULL);

INSERT INTO Clients2 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                      ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (4, 'CLI004', 'Société Delta', 'Diana Moreau', 'Responsable',
        '45 avenue Victor Hugo', 'Toulouse', TO_DATE('1988-11-22','YYYY-MM-DD'),
        'Occitanie', '31000', 'France', '0623456789', NULL);

-- Produits2
INSERT INTO Produits2 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                       UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (3, 'Souris sans fil', NULL, NULL, 29.99, 800, 0, 100, 0);

INSERT INTO Produits2 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                       UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (4, 'Casque audio', NULL, NULL, 79.50, 250, 0, 30, 0);

-- Commandes2
INSERT INTO Commandes2 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                        DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (3, NULL, 3, TO_DATE('2026-03-10','YYYY-MM-DD'),
        TO_DATE('2026-03-18','YYYY-MM-DD'), 3, NULL);

INSERT INTO Commandes2 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                        DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (4, NULL, 4, TO_DATE('2026-04-05','YYYY-MM-DD'),
        TO_DATE('2026-04-12','YYYY-MM-DD'), 4, NULL);

COMMIT;

DBMS_OUTPUT.PUT_LINE('=== Données de base insérées pour Site2 Scenario 2 ===');

-- -------------------------------------------------------
-- 2. Test INSERT valide (Qte < 100 → OK)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT valides ---');
BEGIN
    insertligne2(301, 3, 3, 45, 0);    -- OK : 45 < 100
    insertligne2(302, 3, 4, 80, 10);   -- OK : 80 < 100
    insertligne2(303, 4, 3, 25, 5);    -- OK : 25 < 100
END;
/

-- Vérification
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes2 ORDER BY IDLIGNECOMMANDE;

-- -------------------------------------------------------
-- 3. Test INSERT invalide (Qte >= 100 → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test INSERT invalide (Qte >= 100) ---');
BEGIN
    insertligne2(999, 3, 3, 150, 0);   -- DOIT échouer
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Test UPDATE valide
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE valide ---');
BEGIN
    updateligne2(301, 3, 60, 15);
END;
/

-- -------------------------------------------------------
-- 5. Test UPDATE invalide (Qte >= 100 → ERREUR attendue)
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test UPDATE invalide (Qte >= 100) ---');
BEGIN
    updateligne2(301, 3, 120, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 6. Test DELETE valide
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test DELETE valide ---');
BEGIN
    deleteligne2(303);  -- Dernière ligne de la commande 4 → commande doit être supprimée
END;
/

SELECT COUNT(*) AS "Total lignes Site2" FROM LigneCommandes2;
SELECT COUNT(*) AS "Commande 4 encore presente" FROM Commandes2 WHERE IDCOMMANDE = 4;

-- -------------------------------------------------------
-- 7. Test TRIGGER INSERT bloqué
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Test TRIGGER INSERT bloqué ---');
BEGIN
    INSERT INTO LigneCommandes2 VALUES (997, 3, 4, 150, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Trigger bloqué : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 8. Résumé final
-- -------------------------------------------------------
DBMS_OUTPUT.PUT_LINE('--- Résumé final Site2 Scenario 2 ---');
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes2 ORDER BY IDLIGNECOMMANDE;

SELECT COUNT(*) AS "Lignes restantes" FROM LigneCommandes2;
SELECT COUNT(*) AS "Commandes restantes" FROM Commandes2;
SELECT COUNT(*) AS "Logs enregistrés" FROM LOG_SITE2;