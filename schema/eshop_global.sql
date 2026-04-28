-- ============================================================
-- Fichier : eshop_global.sql
-- Description : Schema global de la base de données EShop
-- Contenu : CREATE TABLE + contraintes (sans données)
-- ============================================================

-- ============================================================
-- TABLE : CATEGORIES
-- ============================================================
CREATE TABLE CATEGORIES (
    IDCATEG         NUMBER(*,0),
    NOMDECATEGORIE  VARCHAR2(100),
    DESCRIPTION     CLOB
);

-- ============================================================
-- TABLE : FOURNISSEURS
-- ============================================================
CREATE TABLE FOURNISSEURS (
    IDFOUR      NUMBER(*,0),
    SOCIETEFOUR VARCHAR2(100),
    CONTACTFOUR VARCHAR2(100),
    FONCTIONFOUR VARCHAR2(100),
    ADRESSEFOUR VARCHAR2(100),
    VILLEFOUR   VARCHAR2(100),
    REGIONFOUR  VARCHAR2(100),
    CP          VARCHAR2(100),
    PAYSFOUR    VARCHAR2(100),
    TELFOUR     VARCHAR2(100),
    FAXFOUR     VARCHAR2(100)
);

-- ============================================================
-- TABLE : EMPLOYES
-- ============================================================
CREATE TABLE EMPLOYES (
    IDEMPLOYE          NUMBER(*,0),
    NOM                VARCHAR2(100),
    PRENOM             VARCHAR2(100),
    FONCTIONEMPLOYE    VARCHAR2(100),
    TITREDECOURTOISIE  VARCHAR2(100),
    DATEDENAISSANCE    DATE,
    DATEEMBAUCHE       DATE,
    ADRESSEEMPLOYE     VARCHAR2(100),
    VILLEEMPLOYE       VARCHAR2(100),
    PAYSEMPLOYE        VARCHAR2(100),
    TELDOMICILE        VARCHAR2(100)
);

-- ============================================================
-- TABLE : CLIENTS
-- ============================================================
CREATE TABLE CLIENTS (
    IDCLIENT    NUMBER,
    CODECLIENT  VARCHAR2(100),
    SOCIETE     VARCHAR2(100) NOT NULL,
    CONTACT     VARCHAR2(100) NOT NULL,
    FONCTION    VARCHAR2(100) NOT NULL,
    ADRESSE     VARCHAR2(100),
    VILLE       VARCHAR2(100),
    NAISSANCE   DATE,
    REGION      VARCHAR2(100),
    CP          VARCHAR2(10),
    PAYS        VARCHAR2(100),
    TELEPHONE   VARCHAR2(100),
    FAX         VARCHAR2(100)
);

-- ============================================================
-- TABLE : PRODUITS
-- ============================================================
CREATE TABLE PRODUITS (
    IDPRODUIT                  NUMBER(*,0),
    DESIGNATION                VARCHAR2(100),
    IDFOUR                     NUMBER(*,0),
    IDCATEG                    NUMBER(*,0),
    PRIXUNITAIRE               FLOAT(126),
    UNITESENSTOCK              NUMBER(*,0),
    UNITESCOMMANDEES           NUMBER(*,0),
    NIVEAUREAPPROVISIONNEMENT  NUMBER(*,0),
    INDISPONIBLE               NUMBER(*,0),
    CONSTRAINT chk_indisponible CHECK (INDISPONIBLE IN (0,1))
);

-- ============================================================
-- TABLE : COMMANDES
-- ============================================================
CREATE TABLE COMMANDES (
    IDCOMMANDE      NUMBER(*,0),
    IDEMPLOYE       NUMBER(*,0),
    IDCLIENT        NUMBER(*,0),
    DATECOMMANDE    DATE,
    DATELIVRAISON   DATE,
    NMESSAGER       NUMBER(4,0),
    PORTNUMBER      NUMBER(4,0),
    CONSTRAINT chk_dates CHECK (DATELIVRAISON >= DATECOMMANDE)
);

-- ============================================================
-- TABLE : LIGNECOMMANDES
-- ============================================================
CREATE TABLE LIGNECOMMANDES (
    IDLIGNECOMMANDE NUMBER(*,0),
    IDCOMMANDE      NUMBER(*,0),
    IDPRODUIT       NUMBER(*,0),
    QUANTITE        NUMBER(*,0),
    REMISE          FLOAT(126)
);

-- ============================================================
-- CLES PRIMAIRES
-- ============================================================
ALTER TABLE CATEGORIES      ADD PRIMARY KEY (IDCATEG);
ALTER TABLE FOURNISSEURS    ADD PRIMARY KEY (IDFOUR);
ALTER TABLE EMPLOYES        ADD PRIMARY KEY (IDEMPLOYE);
ALTER TABLE CLIENTS         ADD PRIMARY KEY (IDCLIENT);
ALTER TABLE PRODUITS        ADD PRIMARY KEY (IDPRODUIT);
ALTER TABLE COMMANDES       ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE LIGNECOMMANDES  ADD PRIMARY KEY (IDLIGNECOMMANDE);

-- ============================================================
-- CLES ETRANGERES
-- ============================================================
ALTER TABLE PRODUITS ADD FOREIGN KEY (IDFOUR)
    REFERENCES FOURNISSEURS (IDFOUR);

ALTER TABLE PRODUITS ADD FOREIGN KEY (IDCATEG)
    REFERENCES CATEGORIES (IDCATEG);

ALTER TABLE COMMANDES ADD FOREIGN KEY (IDEMPLOYE)
    REFERENCES EMPLOYES (IDEMPLOYE);

ALTER TABLE COMMANDES ADD FOREIGN KEY (IDCLIENT)
    REFERENCES CLIENTS (IDCLIENT);

ALTER TABLE LIGNECOMMANDES ADD FOREIGN KEY (IDCOMMANDE)
    REFERENCES COMMANDES (IDCOMMANDE);

ALTER TABLE LIGNECOMMANDES ADD FOREIGN KEY (IDPRODUIT)
    REFERENCES PRODUITS (IDPRODUIT);
