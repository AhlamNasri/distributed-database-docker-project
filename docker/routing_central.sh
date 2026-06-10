#!/bin/bash
# ============================================================
# routing_central.sh - Routage automatique depuis oracle-central
# Regle Scenario 2 :
#   - QUANTITE >= 100 -> Site1
#   - QUANTITE < 100  -> Site2
# Connecte comme APP_USER (eshopcentral) dans BDDCENTRAL
# ============================================================
echo "[routing_central.sh] Creating automatic routing layer as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM USER_TABLES
    WHERE TABLE_NAME = 'ROUTING_LOG';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
CREATE TABLE ROUTING_LOG (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    OPERATION       VARCHAR2(20),
    SITE_CIBLE      VARCHAR2(10),
    IDLIGNECOMMANDE NUMBER,
    IDCOMMANDE      NUMBER,
    IDPRODUIT       NUMBER,
    QUANTITE        NUMBER,
    DATE_OPERATION  TIMESTAMP DEFAULT SYSTIMESTAMP,
    UTILISATEUR     VARCHAR2(100) DEFAULT USER
)]';
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE ensure_site1_refs (
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Clients1@site1_link cl
    WHERE cl.IDCLIENT = (
        SELECT c.IDCLIENT FROM COMMANDES c WHERE c.IDCOMMANDE = p_idcmd
    );

    IF v_count = 0 THEN
        INSERT INTO Clients1@site1_link
        SELECT cl.*
        FROM CLIENTS cl
        JOIN COMMANDES c ON c.IDCLIENT = cl.IDCLIENT
        WHERE c.IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM Commandes1@site1_link
    WHERE IDCOMMANDE = p_idcmd;

    IF v_count = 0 THEN
        INSERT INTO Commandes1@site1_link
        SELECT *
        FROM COMMANDES
        WHERE IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM Produits1@site1_link
    WHERE IDPRODUIT = p_idprod;

    IF v_count = 0 THEN
        INSERT INTO Produits1@site1_link
        SELECT *
        FROM PRODUITS
        WHERE IDPRODUIT = p_idprod;
    END IF;
END ensure_site1_refs;
/

CREATE OR REPLACE PROCEDURE ensure_site2_refs (
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Clients2@site2_link cl
    WHERE cl.IDCLIENT = (
        SELECT c.IDCLIENT FROM COMMANDES c WHERE c.IDCOMMANDE = p_idcmd
    );

    IF v_count = 0 THEN
        INSERT INTO Clients2@site2_link
        SELECT cl.*
        FROM CLIENTS cl
        JOIN COMMANDES c ON c.IDCLIENT = cl.IDCLIENT
        WHERE c.IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM Commandes2@site2_link
    WHERE IDCOMMANDE = p_idcmd;

    IF v_count = 0 THEN
        INSERT INTO Commandes2@site2_link
        SELECT *
        FROM COMMANDES
        WHERE IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM Produits2@site2_link
    WHERE IDPRODUIT = p_idprod;

    IF v_count = 0 THEN
        INSERT INTO Produits2@site2_link
        SELECT *
        FROM PRODUITS
        WHERE IDPRODUIT = p_idprod;
    END IF;
END ensure_site2_refs;
/

CREATE OR REPLACE PROCEDURE route_insert_ligne (
    p_id     IN NUMBER,
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER DEFAULT 0
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
    v_count       NUMBER;
    v_site        VARCHAR2(10);
BEGIN
    SELECT COUNT(*) INTO v_count FROM COMMANDES WHERE IDCOMMANDE = p_idcmd;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Commande ' || p_idcmd || ' introuvable sur le central.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20102, 'Produit ' || p_idprod || ' introuvable sur le central.');
    END IF;

    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2@site2_link WHERE IDLIGNECOMMANDE = p_id;

    IF v_count_site1 + v_count_site2 > 0 THEN
        RAISE_APPLICATION_ERROR(-20103, 'Ligne ' || p_id || ' existe deja dans un site.');
    END IF;

    IF p_qte >= 100 THEN
        v_site := 'SITE1';
        ensure_site1_refs(p_idcmd, p_idprod);
        INSERT INTO LigneCommandes1@site1_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
    ELSE
        v_site := 'SITE2';
        ensure_site2_refs(p_idcmd, p_idprod);
        INSERT INTO LigneCommandes2@site2_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
    END IF;

    INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE)
    VALUES ('INSERT', v_site, p_id, p_idcmd, p_idprod, p_qte);
END route_insert_ligne;
/

CREATE OR REPLACE PROCEDURE route_upsert_ligne (
    p_id     IN NUMBER,
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER DEFAULT 0
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
    v_count       NUMBER;
    v_site        VARCHAR2(10);
BEGIN
    SELECT COUNT(*) INTO v_count FROM COMMANDES WHERE IDCOMMANDE = p_idcmd;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Commande ' || p_idcmd || ' introuvable sur le central.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20102, 'Produit ' || p_idprod || ' introuvable sur le central.');
    END IF;

    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2@site2_link WHERE IDLIGNECOMMANDE = p_id;

    IF p_qte >= 100 THEN
        v_site := 'SITE1';
        ensure_site1_refs(p_idcmd, p_idprod);

        IF v_count_site2 > 0 THEN
            DELETE FROM LigneCommandes2@site2_link WHERE IDLIGNECOMMANDE = p_id;
        END IF;

        IF v_count_site1 > 0 THEN
            UPDATE LigneCommandes1@site1_link
            SET IDCOMMANDE = p_idcmd,
                IDPRODUIT = p_idprod,
                QUANTITE = p_qte,
                REMISE = NVL(p_remise, 0)
            WHERE IDLIGNECOMMANDE = p_id;
        ELSE
            INSERT INTO LigneCommandes1@site1_link
                (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
            VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
        END IF;
    ELSE
        v_site := 'SITE2';
        ensure_site2_refs(p_idcmd, p_idprod);

        IF v_count_site1 > 0 THEN
            DELETE FROM LigneCommandes1@site1_link WHERE IDLIGNECOMMANDE = p_id;
        END IF;

        IF v_count_site2 > 0 THEN
            UPDATE LigneCommandes2@site2_link
            SET IDCOMMANDE = p_idcmd,
                IDPRODUIT = p_idprod,
                QUANTITE = p_qte,
                REMISE = NVL(p_remise, 0)
            WHERE IDLIGNECOMMANDE = p_id;
        ELSE
            INSERT INTO LigneCommandes2@site2_link
                (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
            VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
        END IF;
    END IF;

    INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE)
    VALUES ('UPSERT', v_site, p_id, p_idcmd, p_idprod, p_qte);
END route_upsert_ligne;
/

CREATE OR REPLACE PROCEDURE route_delete_ligne (
    p_id IN NUMBER
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2@site2_link WHERE IDLIGNECOMMANDE = p_id;

    IF v_count_site1 > 0 THEN
        DELETE FROM LigneCommandes1@site1_link WHERE IDLIGNECOMMANDE = p_id;
        INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE)
        VALUES ('DELETE', 'SITE1', p_id);
    ELSIF v_count_site2 > 0 THEN
        DELETE FROM LigneCommandes2@site2_link WHERE IDLIGNECOMMANDE = p_id;
        INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE)
        VALUES ('DELETE', 'SITE2', p_id);
    ELSE
        RAISE_APPLICATION_ERROR(-20104, 'Ligne ' || p_id || ' introuvable dans les sites.');
    END IF;
END route_delete_ligne;
/

CREATE OR REPLACE FORCE VIEW V_LIGNECOMMANDES_ROUTAGE AS
    SELECT SITE, IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
    FROM V_LIGNECOMMANDES_GLOBAL;

CREATE OR REPLACE TRIGGER trg_route_lignecommandes
INSTEAD OF INSERT OR UPDATE OR DELETE ON V_LIGNECOMMANDES_ROUTAGE
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        route_insert_ligne(
            :NEW.IDLIGNECOMMANDE,
            :NEW.IDCOMMANDE,
            :NEW.IDPRODUIT,
            :NEW.QUANTITE,
            :NEW.REMISE
        );
    ELSIF UPDATING THEN
        route_upsert_ligne(
            :NEW.IDLIGNECOMMANDE,
            :NEW.IDCOMMANDE,
            :NEW.IDPRODUIT,
            :NEW.QUANTITE,
            :NEW.REMISE
        );
    ELSIF DELETING THEN
        route_delete_ligne(:OLD.IDLIGNECOMMANDE);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_route_lignecommandes_table
BEFORE INSERT OR UPDATE OR DELETE ON LIGNECOMMANDES
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20300,
        'DML direct sur LIGNECOMMANDES interdit. '
        || 'Utilisez la vue V_LIGNECOMMANDES_ROUTAGE a la place.');
END;
/

DECLARE
    v_sc1_site1 NUMBER;
    v_sc1_site2 NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_sc1_site1
    FROM USER_TABLES@site1_link
    WHERE TABLE_NAME IN ('CATEGORIES1_SC1', 'PRODUITS1_SC1', 'COMMANDES1_SC1', 'CLIENTS1_SC1', 'LIGNECOMMANDES1_SC1');

    SELECT COUNT(*) INTO v_sc1_site2
    FROM USER_TABLES@site2_link
    WHERE TABLE_NAME IN ('CATEGORIES2_SC1', 'PRODUITS2_SC1', 'COMMANDES2_SC1', 'CLIENTS2_SC1', 'LIGNECOMMANDES2_SC1');

    IF v_sc1_site1 = 5 AND v_sc1_site2 = 5 THEN
        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PROCEDURE ensure_site1_refs_sc1 (
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER
) AS
    v_count  NUMBER;
    v_idcat  NUMBER;
BEGIN
    SELECT IDCATEG INTO v_idcat FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    IF v_idcat != 50 THEN
        RAISE_APPLICATION_ERROR(-20201, 'Produit ' || p_idprod || ' non route vers Site1 sc1 : IDCATEG=' || v_idcat);
    END IF;

    SELECT COUNT(*) INTO v_count FROM Categories1_sc1@site1_link WHERE IDCATEG = v_idcat;
    IF v_count = 0 THEN
        INSERT INTO Categories1_sc1@site1_link SELECT * FROM CATEGORIES WHERE IDCATEG = v_idcat;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Produits1_sc1@site1_link WHERE IDPRODUIT = p_idprod;
    IF v_count = 0 THEN
        INSERT INTO Produits1_sc1@site1_link SELECT * FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Clients1_sc1@site1_link cl
    WHERE cl.IDCLIENT = (SELECT c.IDCLIENT FROM COMMANDES c WHERE c.IDCOMMANDE = p_idcmd);
    IF v_count = 0 THEN
        INSERT INTO Clients1_sc1@site1_link
        SELECT cl.*
        FROM CLIENTS cl
        JOIN COMMANDES c ON c.IDCLIENT = cl.IDCLIENT
        WHERE c.IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Commandes1_sc1@site1_link WHERE IDCOMMANDE = p_idcmd;
    IF v_count = 0 THEN
        INSERT INTO Commandes1_sc1@site1_link SELECT * FROM COMMANDES WHERE IDCOMMANDE = p_idcmd;
    END IF;
END ensure_site1_refs_sc1;]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PROCEDURE ensure_site2_refs_sc1 (
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER
) AS
    v_count  NUMBER;
    v_idcat  NUMBER;
BEGIN
    SELECT IDCATEG INTO v_idcat FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    IF v_idcat != 35 THEN
        RAISE_APPLICATION_ERROR(-20202, 'Produit ' || p_idprod || ' non route vers Site2 sc1 : IDCATEG=' || v_idcat);
    END IF;

    SELECT COUNT(*) INTO v_count FROM Categories2_sc1@site2_link WHERE IDCATEG = v_idcat;
    IF v_count = 0 THEN
        INSERT INTO Categories2_sc1@site2_link SELECT * FROM CATEGORIES WHERE IDCATEG = v_idcat;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Produits2_sc1@site2_link WHERE IDPRODUIT = p_idprod;
    IF v_count = 0 THEN
        INSERT INTO Produits2_sc1@site2_link SELECT * FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Clients2_sc1@site2_link cl
    WHERE cl.IDCLIENT = (SELECT c.IDCLIENT FROM COMMANDES c WHERE c.IDCOMMANDE = p_idcmd);
    IF v_count = 0 THEN
        INSERT INTO Clients2_sc1@site2_link
        SELECT cl.*
        FROM CLIENTS cl
        JOIN COMMANDES c ON c.IDCLIENT = cl.IDCLIENT
        WHERE c.IDCOMMANDE = p_idcmd;
    END IF;

    SELECT COUNT(*) INTO v_count FROM Commandes2_sc1@site2_link WHERE IDCOMMANDE = p_idcmd;
    IF v_count = 0 THEN
        INSERT INTO Commandes2_sc1@site2_link SELECT * FROM COMMANDES WHERE IDCOMMANDE = p_idcmd;
    END IF;
END ensure_site2_refs_sc1;]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PROCEDURE route_upsert_ligne_sc1 (
    p_id     IN NUMBER,
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER DEFAULT 0
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
    v_count       NUMBER;
    v_idcat       NUMBER;
    v_site        VARCHAR2(10);
BEGIN
    SELECT COUNT(*) INTO v_count FROM COMMANDES WHERE IDCOMMANDE = p_idcmd;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20203, 'Commande ' || p_idcmd || ' introuvable sur le central.');
    END IF;

    SELECT IDCATEG INTO v_idcat FROM PRODUITS WHERE IDPRODUIT = p_idprod;
    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1_sc1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2_sc1@site2_link WHERE IDLIGNECOMMANDE = p_id;

    IF v_idcat = 50 THEN
        v_site := 'SITE1';
        ensure_site1_refs_sc1(p_idcmd, p_idprod);
        IF v_count_site2 > 0 THEN
            DELETE FROM LigneCommandes2_sc1@site2_link WHERE IDLIGNECOMMANDE = p_id;
        END IF;
        IF v_count_site1 > 0 THEN
            UPDATE LigneCommandes1_sc1@site1_link
            SET IDCOMMANDE = p_idcmd, IDPRODUIT = p_idprod, QUANTITE = p_qte, REMISE = NVL(p_remise, 0)
            WHERE IDLIGNECOMMANDE = p_id;
        ELSE
            INSERT INTO LigneCommandes1_sc1@site1_link
                (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
            VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
        END IF;
    ELSIF v_idcat = 35 THEN
        v_site := 'SITE2';
        ensure_site2_refs_sc1(p_idcmd, p_idprod);
        IF v_count_site1 > 0 THEN
            DELETE FROM LigneCommandes1_sc1@site1_link WHERE IDLIGNECOMMANDE = p_id;
        END IF;
        IF v_count_site2 > 0 THEN
            UPDATE LigneCommandes2_sc1@site2_link
            SET IDCOMMANDE = p_idcmd, IDPRODUIT = p_idprod, QUANTITE = p_qte, REMISE = NVL(p_remise, 0)
            WHERE IDLIGNECOMMANDE = p_id;
        ELSE
            INSERT INTO LigneCommandes2_sc1@site2_link
                (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
            VALUES (p_id, p_idcmd, p_idprod, p_qte, NVL(p_remise, 0));
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20204, 'Scenario 1 ne route que IDCATEG=50 vers Site1 et IDCATEG=35 vers Site2. IDCATEG=' || v_idcat);
    END IF;

    INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE)
    VALUES ('UPSERT_SC1', v_site, p_id, p_idcmd, p_idprod, p_qte);
END route_upsert_ligne_sc1;]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PROCEDURE route_insert_ligne_sc1 (
    p_id     IN NUMBER,
    p_idcmd  IN NUMBER,
    p_idprod IN NUMBER,
    p_qte    IN NUMBER,
    p_remise IN NUMBER DEFAULT 0
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1_sc1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2_sc1@site2_link WHERE IDLIGNECOMMANDE = p_id;
    IF v_count_site1 + v_count_site2 > 0 THEN
        RAISE_APPLICATION_ERROR(-20205, 'Ligne ' || p_id || ' existe deja dans un site sc1.');
    END IF;
    route_upsert_ligne_sc1(p_id, p_idcmd, p_idprod, p_qte, p_remise);
END route_insert_ligne_sc1;]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE PROCEDURE route_delete_ligne_sc1 (
    p_id IN NUMBER
) AS
    v_count_site1 NUMBER;
    v_count_site2 NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_site1 FROM LigneCommandes1_sc1@site1_link WHERE IDLIGNECOMMANDE = p_id;
    SELECT COUNT(*) INTO v_count_site2 FROM LigneCommandes2_sc1@site2_link WHERE IDLIGNECOMMANDE = p_id;

    IF v_count_site1 > 0 THEN
        DELETE FROM LigneCommandes1_sc1@site1_link WHERE IDLIGNECOMMANDE = p_id;
        INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE)
        VALUES ('DELETE_SC1', 'SITE1', p_id);
    ELSIF v_count_site2 > 0 THEN
        DELETE FROM LigneCommandes2_sc1@site2_link WHERE IDLIGNECOMMANDE = p_id;
        INSERT INTO ROUTING_LOG (OPERATION, SITE_CIBLE, IDLIGNECOMMANDE)
        VALUES ('DELETE_SC1', 'SITE2', p_id);
    ELSE
        RAISE_APPLICATION_ERROR(-20206, 'Ligne ' || p_id || ' introuvable dans les sites sc1.');
    END IF;
END route_delete_ligne_sc1;]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE VIEW V_LIGNECOMMANDES_ROUTAGE_SC1 AS
    SELECT SITE, IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE
    FROM V_LIGNECOMMANDES_GLOBAL_SC1]';

        EXECUTE IMMEDIATE q'[
CREATE OR REPLACE TRIGGER trg_route_lignecommandes_sc1
INSTEAD OF INSERT OR UPDATE OR DELETE ON V_LIGNECOMMANDES_ROUTAGE_SC1
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        route_insert_ligne_sc1(:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT, :NEW.QUANTITE, :NEW.REMISE);
    ELSIF UPDATING THEN
        route_upsert_ligne_sc1(:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT, :NEW.QUANTITE, :NEW.REMISE);
    ELSIF DELETING THEN
        route_delete_ligne_sc1(:OLD.IDLIGNECOMMANDE);
    END IF;
END;]';

        DBMS_OUTPUT.PUT_LINE('Routage Scenario 1 cree : V_LIGNECOMMANDES_ROUTAGE_SC1.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Routage Scenario 1 ignore : fragments _sc1 absents sur les deux sites.');
    END IF;
END;
/

-- Suppression des 25 lignes redondantes sur le Central
-- Le routage via V_LIGNECOMMANDES_ROUTAGE est desormais le seul point d'entree
TRUNCATE TABLE LIGNECOMMANDES;

COMMIT;
EXIT;
SQLEOF

echo "[routing_central.sh] Done."
