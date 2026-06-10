#!/bin/bash
# ============================================================
# site2_triggers.sh — Triggers Site2 Scénario 2
# Règle : QUANTITE < 100
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# ============================================================
echo "[site2_triggers.sh] Creating triggers as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE TABLE LOG_SITE2 (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    QUANTITE_OLD    NUMBER,
    QUANTITE_NEW    NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
);

CREATE OR REPLACE TRIGGER trg_check_site2_insert
BEFORE INSERT ON LigneCommandes2
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE >= 100 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'TRIGGER SITE2 - INSERT bloque : QUANTITE=' || :NEW.QUANTITE ||
            ' >= 100. Cette ligne appartient a Site1.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_site2_update
BEFORE UPDATE ON LigneCommandes2
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE >= 100 THEN
        RAISE_APPLICATION_ERROR(-20011,
            'TRIGGER SITE2 - UPDATE bloque : Nouvelle QUANTITE=' || :NEW.QUANTITE ||
            ' >= 100. Modifier sur Site1 a la place.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_log_site2_operations
AFTER INSERT OR UPDATE OR DELETE ON LigneCommandes2
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        INSERT INTO LOG_SITE2 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, NULL, :NEW.QUANTITE);
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        INSERT INTO LOG_SITE2 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :NEW.IDLIGNECOMMANDE, :OLD.QUANTITE, :NEW.QUANTITE);
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        INSERT INTO LOG_SITE2 (OPERATION, IDLIGNECOMMANDE, QUANTITE_OLD, QUANTITE_NEW)
        VALUES (v_operation, :OLD.IDLIGNECOMMANDE, :OLD.QUANTITE, NULL);
    END IF;
END;
/

-- Bloquer tout DML direct sur LIGNECOMMANDES (table globale vide sur ce site)
-- Les inserts doivent passer par V_LIGNECOMMANDES_ROUTAGE sur le Central
CREATE OR REPLACE TRIGGER trg_block_lignecommandes_site2
BEFORE INSERT OR UPDATE OR DELETE ON LIGNECOMMANDES
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20302,
        'DML direct sur LIGNECOMMANDES interdit sur Site2. '
        || 'Utilisez la vue V_LIGNECOMMANDES_ROUTAGE sur le Central.');
END;
/

COMMIT;
EXIT;
SQLEOF

echo "[site2_triggers.sh] Done."
