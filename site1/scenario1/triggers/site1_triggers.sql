-- ============================================================
-- SITE 1 - TRIGGERS (Scenario 1)
-- Règle fragment : IDCATEG = 50 AND QUANTITE > 100
-- Table principale : LigneCommandes1_sc1
-- ============================================================

-- -------------------------------------------------------
-- Table de log (Oracle syntax - CREATE TABLE sans IF NOT EXISTS)
-- -------------------------------------------------------
CREATE TABLE LOG_SITE1_SC1 (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    IDPRODUIT_OLD   NUMBER,
    IDPRODUIT_NEW   NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
);

-- -------------------------------------------------------
-- 1. trg_check_sc1_insert
--    BEFORE INSERT : vérifie que le produit est de catégorie 50
--                    ET que la quantité est > 100
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_sc1_insert
BEFORE INSERT ON LigneCommandes1_sc1
FOR EACH ROW
DECLARE
    v_categ NUMBER;
BEGIN
    -- Vérification règle de fragmentation : quantité
    IF :NEW.QUANTITE <= 100 THEN
        RAISE_APPLICATION_ERROR(-20014,
            'TRIGGER SITE1 SC1 - INSERT bloqué : QUANTITE=' || :NEW.QUANTITE ||
            ' doit être > 100 pour Site1 scénario 1.');
    END IF;

    -- Vérification règle de fragmentation : catégorie
    SELECT IDCATEG INTO v_categ
    FROM Produits1_sc1
    WHERE IDPRODUIT = :NEW.IDPRODUIT;

    IF v_categ != 50 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'TRIGGER SITE1 SC1 - INSERT bloqué : Produit ' || :NEW.IDPRODUIT ||
            ' n''est pas de catégorie 50. Appartient à Site2.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011,
            'TRIGGER SITE1 SC1 - INSERT bloqué : Produit ' || :NEW.IDPRODUIT || ' introuvable dans Site1.');
END;
/

-- -------------------------------------------------------
-- 2. trg_check_sc1_update
--    BEFORE UPDATE : vérifie que le nouveau produit est de catégorie 50
--                    ET que la nouvelle quantité est > 100
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_sc1_update
BEFORE UPDATE ON LigneCommandes1_sc1
FOR EACH ROW
DECLARE
    v_categ NUMBER;
BEGIN
    -- Vérification règle de fragmentation : quantité
    IF :NEW.QUANTITE <= 100 THEN
        RAISE_APPLICATION_ERROR(-20015,
            'TRIGGER SITE1 SC1 - UPDATE bloqué : QUANTITE=' || :NEW.QUANTITE ||
            ' doit être > 100 pour Site1 scénario 1.');
    END IF;

    -- Vérification règle de fragmentation : catégorie
    SELECT IDCATEG INTO v_categ
    FROM Produits1_sc1
    WHERE IDPRODUIT = :NEW.IDPRODUIT;

    IF v_categ != 50 THEN
        RAISE_APPLICATION_ERROR(-20012,
            'TRIGGER SITE1 SC1 - UPDATE bloqué : Produit ' || :NEW.IDPRODUIT ||
            ' n''est pas de catégorie 50. Modifier sur Site2.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20013,
            'TRIGGER SITE1 SC1 - UPDATE bloqué : Produit ' || :NEW.IDPRODUIT || ' introuvable dans Site1.');
END;
/

-- -------------------------------------------------------
-- 3. trg_log_sc1_operations
--    AFTER INSERT OR UPDATE OR DELETE : journalise les opérations
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_log_sc1_operations
AFTER INSERT OR UPDATE OR DELETE ON LigneCommandes1_sc1
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        INSERT INTO LOG_SITE1_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, NULL, :NEW.IDPRODUIT);

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        INSERT INTO LOG_SITE1_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, :OLD.IDPRODUIT, :NEW.IDPRODUIT);

    ELSIF DELETING THEN
        v_operation := 'DELETE';
        INSERT INTO LOG_SITE1_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :OLD.IDLIGNECOMMANDE, :OLD.IDPRODUIT, NULL);
    END IF;
END;
/

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT
-- FROM USER_TRIGGERS
-- WHERE TABLE_NAME = 'LIGNECOMMANDES1_SC1';

COMMIT;