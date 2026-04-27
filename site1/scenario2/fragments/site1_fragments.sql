-- ============================================================
-- SITE 1 - FRAGMENTATION HORIZONTALE (Scenario 2)
-- Règle : LigneCommandes avec Quantite >= 100
-- À exécuter sur : Docker container site1 (port 1522)
-- ============================================================

-- Connexion : sqlplus system/oracle@localhost:1522/XEPDB1

-- -------------------------------------------------------
-- 1. Création du USER pour le projet
-- -------------------------------------------------------
CREATE USER eshop1 IDENTIFIED BY oracle;
GRANT CONNECT, RESOURCE, DBA TO eshop1;

-- -------------------------------------------------------
-- 2. Tables de base (copies structure sans données)
-- -------------------------------------------------------

CREATE TABLE Categories1 (
    idcateg     NUMBER PRIMARY KEY,
    libcateg    VARCHAR2(100) NOT NULL
);

CREATE TABLE Clients1 (
    idclient    NUMBER PRIMARY KEY,
    nomclient   VARCHAR2(100) NOT NULL,
    prenomclient VARCHAR2(100),
    email       VARCHAR2(150),
    ville       VARCHAR2(100)
);

CREATE TABLE Produits1 (
    idproduit   NUMBER PRIMARY KEY,
    libproduit  VARCHAR2(200) NOT NULL,
    prixunitaire NUMBER(10,2) NOT NULL,
    idcateg     NUMBER,
    CONSTRAINT fk_prod1_categ FOREIGN KEY (idcateg) REFERENCES Categories1(idcateg)
);

CREATE TABLE Commandes1 (
    idcommande      NUMBER PRIMARY KEY,
    datecommande    DATE NOT NULL,
    idclient        NUMBER NOT NULL,
    CONSTRAINT fk_cmd1_client FOREIGN KEY (idclient) REFERENCES Clients1(idclient)
);

-- -------------------------------------------------------
-- 3. Table fragmentée : LigneCommandes1
--    RÈGLE : seulement les lignes où Quantite >= 100
-- -------------------------------------------------------

CREATE TABLE LigneCommandes1 (
    idlignecommande NUMBER PRIMARY KEY,
    idcommande      NUMBER NOT NULL,
    idproduit       NUMBER NOT NULL,
    quantite        NUMBER NOT NULL,
    remise          NUMBER(5,2) DEFAULT 0,
    CONSTRAINT fk_lc1_cmd  FOREIGN KEY (idcommande) REFERENCES Commandes1(idcommande),
    CONSTRAINT fk_lc1_prod FOREIGN KEY (idproduit)  REFERENCES Produits1(idproduit),
    CONSTRAINT chk_site1_quantite CHECK (Quantite >= 100)
);

-- -------------------------------------------------------
-- 4. Commentaires (documentation)
-- -------------------------------------------------------
COMMENT ON TABLE LigneCommandes1 IS 'Fragment Site1 - Lignes commandes avec Quantite >= 100';
COMMENT ON COLUMN LigneCommandes1.quantite IS 'Quantité commandée - toujours >= 100 sur Site1';

COMMIT;
