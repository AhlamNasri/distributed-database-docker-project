#!/bin/bash
# ============================================================
# site1_triggers.sh — Triggers Site1 Scénario 2
# Règle : QUANTITE >= 100
# Connecté comme APP_USER (eshop1) dans BDDVENTE
# ============================================================
echo "[site1_triggers.sh] Creating triggers as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE TABLE LOG_SITE1 (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    QUANTITE_OLD    NUMBER,
    QUANTITE_NEW    NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
);

CREATE OR REPLACE TRIGGER trg_check_site1_insert
BEFORE INSERT ON LigneCommandes1
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE < 100 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'TRIGGER SITE1 - INSERT bloque : QUANTITE=' || :NEW.QUANTITE ||
            ' < 100. Cette ligne appartient a Site2.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_site1_update
BEFORE UPDATE ON LigneCommandes1
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE < 100 THEN
        RAISE_APPLICATION_ERROR(-20011,
            'TRIGGER SITE1 - UPDATE bloque : Nouvelle QUANTITE=' || :NEW.QUANTITE ||
            ' < 100. Modifier sur Site2 a la place.');
    END IF;
END;
/

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

COMMIT;
EXIT;
SQLEOF

echo "[site1_triggers.sh] Done."
