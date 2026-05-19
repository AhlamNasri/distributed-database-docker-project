-- ============================================================
-- SITE 2 - TRIGGERS (Scenario 1)
-- Règle fragment : IDCATEG = 35 AND QUANTITE <= 100
-- ============================================================

-- Table de log
CREATE TABLE LOG_SITE2_SC1 (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    IDPRODUIT_OLD   NUMBER,
    IDPRODUIT_NEW   NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
);

-- Trigger BEFORE INSERT
CREATE OR REPLACE TRIGGER trg_check_sc1_site2_insert
BEFORE INSERT ON LigneCommandes2_sc1
FOR EACH ROW
DECLARE
    v_categ NUMBER;
BEGIN
    IF :NEW.QUANTITE > 100 THEN
        RAISE_APPLICATION_ERROR(-20014,
            'TRIGGER SITE2 SC1 - INSERT bloqué : QUANTITE=' || :NEW.QUANTITE ||
            ' doit être <= 100 pour Site2 scénario 1.');
    END IF;

    SELECT IDCATEG INTO v_categ
    FROM Produits2_sc1 WHERE IDPRODUIT = :NEW.IDPRODUIT;

    IF v_categ != 35 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'TRIGGER SITE2 SC1 - INSERT bloqué : Produit ' || :NEW.IDPRODUIT ||
            ' n''est pas de catégorie 35. Appartient à Site1.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'TRIGGER SITE2 SC1 - Produit introuvable dans Site2.');
END;
/

-- Trigger BEFORE UPDATE
CREATE OR REPLACE TRIGGER trg_check_sc1_site2_update
BEFORE UPDATE ON LigneCommandes2_sc1
FOR EACH ROW
DECLARE
    v_categ NUMBER;
BEGIN
    IF :NEW.QUANTITE > 100 THEN
        RAISE_APPLICATION_ERROR(-20015,
            'TRIGGER SITE2 SC1 - UPDATE bloqué : QUANTITE=' || :NEW.QUANTITE ||
            ' doit être <= 100 pour Site2 scénario 1.');
    END IF;

    SELECT IDCATEG INTO v_categ
    FROM Produits2_sc1 WHERE IDPRODUIT = :NEW.IDPRODUIT;

    IF v_categ != 35 THEN
        RAISE_APPLICATION_ERROR(-20012,
            'TRIGGER SITE2 SC1 - UPDATE bloqué : Produit ' || :NEW.IDPRODUIT ||
            ' n''est pas de catégorie 35.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20013, 'TRIGGER SITE2 SC1 - Produit introuvable.');
END;
/

-- Trigger LOG
CREATE OR REPLACE TRIGGER trg_log_sc1_site2_operations
AFTER INSERT OR UPDATE OR DELETE ON LigneCommandes2_sc1
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        INSERT INTO LOG_SITE2_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, NULL, :NEW.IDPRODUIT);
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        INSERT INTO LOG_SITE2_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, :OLD.IDPRODUIT, :NEW.IDPRODUIT);
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        INSERT INTO LOG_SITE2_SC1 (OPERATION, IDLIGNECOMMANDE, IDPRODUIT_OLD, IDPRODUIT_NEW)
        VALUES (v_operation, :OLD.IDLIGNECOMMANDE, :OLD.IDPRODUIT, NULL);
    END IF;
END;
/

COMMIT;