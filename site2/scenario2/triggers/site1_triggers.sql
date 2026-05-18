-- ============================================================
-- SITE 1 - TRIGGERS (Scenario 2)
-- Règle fragment : QUANTITE >= 100
-- Table principale : LigneCommandes1
-- ============================================================

-- -------------------------------------------------------
-- 1. trg_check_site1_insert
--    BEFORE INSERT : vérifie que QUANTITE >= 100
--    Bloque toute insertion qui viole la règle de fragmentation
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_site1_insert
BEFORE INSERT ON LigneCommandes1
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE < 100 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'TRIGGER SITE1 - INSERT bloqué : QUANTITE=' || :NEW.QUANTITE ||
            ' < 100. Cette ligne appartient à Site2.');
    END IF;
END;
/

-- -------------------------------------------------------
-- 2. trg_check_site1_update
--    BEFORE UPDATE : vérifie que la nouvelle QUANTITE >= 100
--    Bloque toute mise à jour qui ferait passer la ligne à Site2
-- -------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_site1_update
BEFORE UPDATE ON LigneCommandes1
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE < 100 THEN
        RAISE_APPLICATION_ERROR(-20011,
            'TRIGGER SITE1 - UPDATE bloqué : Nouvelle QUANTITE=' || :NEW.QUANTITE ||
            ' < 100. Modifier sur Site2 à la place.');
    END IF;
END;
/

-- -------------------------------------------------------
-- 3. trg_log_site1_operations
--    AFTER INSERT OR UPDATE OR DELETE
--    Journalise toutes les opérations sur LigneCommandes1
--    pour le monitoring et la traçabilité
-- -------------------------------------------------------

-- Table de log (à créer avant le trigger)
CREATE TABLE IF NOT EXISTS LOG_SITE1 (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    QUANTITE_OLD    NUMBER,
    QUANTITE_NEW    NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
);

CREATE OR REPLACE TRIGGER trg_log_site1_operations
AFTER INSERT OR UPDATE OR DELETE ON LigneCommandes1
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        INSERT INTO LOG_SITE1 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, NULL, :NEW.QUANTITE);

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        INSERT INTO LOG_SITE1 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, :OLD.QUANTITE, :NEW.QUANTITE);

    ELSIF DELETING THEN
        v_operation := 'DELETE';
        INSERT INTO LOG_SITE1 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :OLD.IDLIGNECOMMANDE, :OLD.QUANTITE, NULL);
    END IF;
END;
/

-- -------------------------------------------------------
-- VERIFICATION : lister les triggers créés
-- -------------------------------------------------------
-- SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT
-- FROM USER_TRIGGERS
-- WHERE TABLE_NAME = 'LIGNECOMMANDES1';

COMMIT;
