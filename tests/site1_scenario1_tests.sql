-- ============================================================
-- SITE 1 - TESTS (Scenario 1)
-- Tester les procédures CRUD de LigneCommandes1_sc1
-- Règle fragment : IDCATEG = 50
-- Tables : LigneCommandes1_sc1, Commandes1_sc1, Clients1_sc1,
--          Produits1_sc1, Categories1_sc1
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 180
SET PAGESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET WRAP OFF

COLUMN IDLIGNECOMMANDE FORMAT 9999999999 HEADING ID_LIGNE
COLUMN IDCOMMANDE FORMAT 999999999 HEADING ID_CMD
COLUMN IDPRODUIT FORMAT 999999999 HEADING ID_PROD
COLUMN QUANTITE FORMAT 9999999 HEADING QTE
COLUMN REMISE FORMAT 990.99
COLUMN NB_LIGNES FORMAT 999999
COLUMN NB_COMMANDES FORMAT 999999
COLUMN NB_LOGS FORMAT 999999
COLUMN CMD1_PRESENTE FORMAT 999999
COLUMN CMD2_PRESENTE FORMAT 999999

-- -------------------------------------------------------
-- 0. Nettoyage préalable (si relance du script)
-- -------------------------------------------------------
DELETE FROM LigneCommandes1_sc1;
DELETE FROM Commandes1_sc1;
DELETE FROM Clients1_sc1;
DELETE FROM Produits1_sc1;
DELETE FROM Categories1_sc1;
COMMIT;

-- -------------------------------------------------------
-- 1. Insérer données de base (nécessaires pour FK)
--    Respect des schémas réels issus de eshop_global.sql
-- -------------------------------------------------------

-- Categories1_sc1 : critère de fragmentation IDCATEG = 50
INSERT INTO Categories1_sc1 (IDCATEG, NOMDECATEGORIE)
VALUES (50, 'Informatique');

-- Produits1_sc1 : (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
--                  UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
INSERT INTO Produits1_sc1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                            UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (10, 'Ordinateur portable', NULL, 50, 1200.00, 500, 0, 50, 0);

INSERT INTO Produits1_sc1 (IDPRODUIT, DESIGNATION, IDFOUR, IDCATEG, PRIXUNITAIRE,
                            UNITESENSTOCK, UNITESCOMMANDEES, NIVEAUREAPPROVISIONNEMENT, INDISPONIBLE)
VALUES (11, 'Clavier mécanique', NULL, 50, 89.99, 300, 0, 30, 0);

-- Clients1_sc1 : (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
--                 ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
INSERT INTO Clients1_sc1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                           ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (1, 'CLI001', 'Société Alpha', 'Alice Dupont', 'Directrice',
        '12 rue de Paris', 'Paris', TO_DATE('1985-03-20','YYYY-MM-DD'),
        'Île-de-France', '75001', 'France', '0601020304', NULL);

INSERT INTO Clients1_sc1 (IDCLIENT, CODECLIENT, SOCIETE, CONTACT, FONCTION,
                           ADRESSE, VILLE, NAISSANCE, REGION, CP, PAYS, TELEPHONE, FAX)
VALUES (2, 'CLI002', 'Société Beta', 'Bob Martin', 'Responsable Achat',
        '5 avenue Foch', 'Lyon', TO_DATE('1979-07-11','YYYY-MM-DD'),
        'Auvergne-Rhône-Alpes', '69001', 'France', '0611223344', NULL);

-- Commandes1_sc1 : (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
--                   DATELIVRAISON, NMESSAGER, PORTNUMBER)
INSERT INTO Commandes1_sc1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                             DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (1, NULL, 1, TO_DATE('2026-01-10','YYYY-MM-DD'),
        TO_DATE('2026-01-20','YYYY-MM-DD'), 1, NULL);

INSERT INTO Commandes1_sc1 (IDCOMMANDE, IDEMPLOYE, IDCLIENT, DATECOMMANDE,
                             DATELIVRAISON, NMESSAGER, PORTNUMBER)
VALUES (2, NULL, 2, TO_DATE('2026-02-05','YYYY-MM-DD'),
        TO_DATE('2026-02-15','YYYY-MM-DD'), 2, NULL);

COMMIT;

PROMPT === Donnees de base inserees ===

-- -------------------------------------------------------
-- 2. Test INSERT valide (produit de catégorie 50 → OK)
-- -------------------------------------------------------
PROMPT Test INSERT valides
BEGIN
insertligne_sc1(201, 1, 10, 150, 0);
insertligne_sc1(202, 1, 11, 200, 5);
insertligne_sc1(203, 2, 10, 120, 10);
END;
/

-- Vérification
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1_sc1
ORDER BY IDLIGNECOMMANDE;

-- -------------------------------------------------------
-- 3. Test INSERT invalide (produit hors catégorie 50 → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test INSERT invalide (produit hors categorie 50)
BEGIN
    -- Produit 99 n'existe pas dans Produits1_sc1 (appartient à Site2)
    insertligne_sc1(999, 1, 99, 3, 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 4. Test INSERT invalide (commande inexistante → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test INSERT invalide (commande inexistante)
BEGIN
    insertligne_sc1(998, 999, 10, 3, 0);  -- commande 999 n'existe pas dans Commandes1_sc1
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 5. Test INSERT invalide (doublon PK → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test INSERT invalide (doublon PK)
BEGIN
    insertligne_sc1(201, 1, 10, 5, 0);  -- ligne 201 existe déjà
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur INSERT doublon attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 6. Test UPDATE valide
-- -------------------------------------------------------
PROMPT Test UPDATE valide
BEGIN
    updateligne_sc1(201, 11, 150, 15);
END;
/

SELECT IDLIGNECOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1_sc1
WHERE IDLIGNECOMMANDE = 201;

-- -------------------------------------------------------
-- 7. Test UPDATE invalide (nouveau produit hors catégorie 50 → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test UPDATE invalide (produit hors categorie 50)
BEGIN
    updateligne_sc1(201, 99, 10, 0);  -- produit 99 n'est pas dans Produits1_sc1
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 8. Test UPDATE invalide (ligne inexistante → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test UPDATE invalide (ligne inexistante)
BEGIN
    updateligne_sc1(9999, 10, 5, 0);  -- ligne 9999 n'existe pas
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur UPDATE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 9. Test DELETE valide
--    Ligne 203 est la seule ligne de commande 2
--    → commande 2 doit être supprimée automatiquement
-- -------------------------------------------------------
PROMPT Test DELETE valide (cascade commande vide)
BEGIN
    deleteligne_sc1(203);
END;
/

SELECT COUNT(*) AS NB_LIGNES FROM LigneCommandes1_sc1;
-- Commande 2 doit avoir disparu :
SELECT COUNT(*) AS CMD2_PRESENTE FROM Commandes1_sc1 WHERE IDCOMMANDE = 2;

-- -------------------------------------------------------
-- 10. Test DELETE valide (ligne simple, commande conservée)
-- -------------------------------------------------------
PROMPT Test DELETE valide (commande conservee)
BEGIN
    deleteligne_sc1(202);  -- commande 1 a encore la ligne 201 → doit rester
END;
/

-- Commande 1 doit toujours exister :
SELECT COUNT(*) AS CMD1_PRESENTE FROM Commandes1_sc1 WHERE IDCOMMANDE = 1;

-- -------------------------------------------------------
-- 11. Test DELETE invalide (ligne inexistante → ERREUR attendue)
-- -------------------------------------------------------
PROMPT Test DELETE invalide (ligne inexistante)
BEGIN
    deleteligne_sc1(9999);  -- ligne 9999 n'existe pas
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Erreur DELETE attendue : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 12. Vérification triggers : INSERT bloqué via trigger
-- -------------------------------------------------------
PROMPT Test TRIGGER INSERT bloque (produit hors categorie 50)
BEGIN
    -- Insertion directe sans passer par la procédure
    -- Le trigger trg_check_sc1_insert doit bloquer
    INSERT INTO LigneCommandes1_sc1 (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES (997, 1, 99, 5, 0);  -- produit 99 hors catégorie 50
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Trigger INSERT bloqué : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 13. Vérification triggers : UPDATE bloqué via trigger
-- -------------------------------------------------------
PROMPT Test TRIGGER UPDATE bloque (produit hors categorie 50)
BEGIN
    UPDATE LigneCommandes1_sc1
    SET IDPRODUIT = 99  -- produit 99 hors catégorie 50
    WHERE IDLIGNECOMMANDE = 201;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✔ Trigger UPDATE bloqué : ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- 14. Résumé final
-- -------------------------------------------------------
PROMPT Resume final
SELECT IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
FROM LigneCommandes1_sc1
ORDER BY IDLIGNECOMMANDE;

SELECT COUNT(*) AS NB_LIGNES FROM LigneCommandes1_sc1;
SELECT COUNT(*) AS NB_COMMANDES FROM Commandes1_sc1;
SELECT COUNT(*) AS NB_LOGS FROM LOG_SITE1_SC1;
