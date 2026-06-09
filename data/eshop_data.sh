#!/bin/bash
# ============================================================
# eshop_data.sh — Données initiales EShop
# Connecté comme APP_USER dans la PDB cible
# ============================================================
echo "[eshop_data.sh] Inserting data as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (10, 'Boissons', 'Boissons alcoolisées et non alcoolisées');
INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (20, 'Condiments', 'Sauces sucrées, épices et assaisonnements');
INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (35, 'Accessoires', 'Périphériques et accessoires informatiques');
INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (50, 'Informatique', 'Ordinateurs, tablettes et composants');
INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (60, 'Vêtements', 'Vêtements et accessoires professionnels');
INSERT INTO CATEGORIES (IDCATEG, NOMDECATEGORIE, DESCRIPTION)
VALUES (70, 'Bureautique', 'Fournitures et mobilier de bureau');

INSERT INTO FOURNISSEURS
VALUES (1,'TechDistrib SA','Marc Leroy','Dir. Commercial',
        '15 rue de la Tech','Paris','Île-de-France','75001','France',
        '0145678901','0145678902');
INSERT INTO FOURNISSEURS
VALUES (2,'InfoParts SARL','Sophie Martin','Resp. Ventes',
        '42 av. de la République','Lyon','Auvergne-Rhône-Alpes','69002','France',
        '0478901234','0478901235');
INSERT INTO FOURNISSEURS
VALUES (3,'AccessPro SAS','Pierre Dubois','Gérant',
        '8 place Bellecour','Marseille','PACA','13001','France',
        '0491234567','0491234568');

INSERT INTO EMPLOYES
VALUES (1,'Dupont','Alice','Responsable Ventes','Mme',
        DATE '1985-03-15', DATE '2010-06-01',
        '12 rue de Paris','Paris','France','0601020304');
INSERT INTO EMPLOYES
VALUES (2,'Martin','Bob','Commercial','M.',
        DATE '1979-07-22', DATE '2012-03-15',
        '5 avenue Foch','Lyon','France','0611223344');
INSERT INTO EMPLOYES
VALUES (3,'Bernard','Claire','Chef de secteur','Mme',
        DATE '1988-11-10', DATE '2015-09-01',
        '23 bd Victor Hugo','Marseille','France','0622334455');

INSERT INTO CLIENTS
VALUES (1,'CLI001','Société Alpha','Alice Dupont','Directrice',
        '12 rue de Paris','Paris', DATE '1980-03-20',
        'Île-de-France','75001','France','0601020304',NULL);
INSERT INTO CLIENTS
VALUES (2,'CLI002','Société Beta','Bob Martin','Resp. Achat',
        '5 avenue Foch','Lyon', DATE '1975-07-11',
        'Auvergne-Rhône-Alpes','69001','France','0611223344',NULL);
INSERT INTO CLIENTS
VALUES (3,'CLI003','Société Gamma','Charlie Petit','Acheteur',
        '8 rue de la Paix','Marseille', DATE '1990-05-15',
        'PACA','13001','France','0612345678',NULL);
INSERT INTO CLIENTS
VALUES (4,'CLI004','Société Delta','Diana Moreau','Responsable',
        '45 avenue Victor Hugo','Toulouse', DATE '1988-11-22',
        'Occitanie','31000','France','0623456789',NULL);
INSERT INTO CLIENTS
VALUES (5,'CLI005','Société Epsilon','Emma Laurent','Dir. Achats',
        '22 bd de Strasbourg','Bordeaux', DATE '1992-08-10',
        'Nouvelle-Aquitaine','33000','France','0656789012',NULL);
INSERT INTO CLIENTS
VALUES (6,'CLI006','Société Zeta','Franck Dubois','Resp. Logistique',
        '17 rue Gambetta','Lille', DATE '1987-12-05',
        'Hauts-de-France','59000','France','0678901234',NULL);
INSERT INTO CLIENTS
VALUES (7,'CLI007','Société Eta','Gisèle Fontaine','Dir. Générale',
        '3 place du Marché','Nantes', DATE '1983-01-19',
        'Pays de la Loire','44000','France','0634567890',NULL);
INSERT INTO CLIENTS
VALUES (8,'CLI008','Société Theta','Hugo Renard','Acheteur Senior',
        '9 rue du Commerce','Strasbourg', DATE '1977-04-18',
        'Grand Est','67000','France','0645678901',NULL);

INSERT INTO PRODUITS VALUES (1,'Ordinateur portable Dell XPS',1,50,1299.99,50,10,15,0);
INSERT INTO PRODUITS VALUES (2,'Tablette Samsung 12 pouces',2,50,599.99,80,20,25,0);
INSERT INTO PRODUITS VALUES (3,'Clavier mécanique Logitech',1,50,129.99,200,50,60,0);
INSERT INTO PRODUITS VALUES (4,'Clé USB 128Go Kingston',3,35,19.99,500,100,120,0);
INSERT INTO PRODUITS VALUES (5,'Chargeur sans fil 20W Belkin',3,35,34.99,300,80,100,0);
INSERT INTO PRODUITS VALUES (6,'Hub USB-C 7 ports Anker',3,35,59.99,250,60,80,0);
INSERT INTO PRODUITS VALUES (7,'Bureau ergonomique ajustable',2,70,449.99,30,5,10,0);
INSERT INTO PRODUITS VALUES (8,'Chaise de bureau ergonomique',2,70,299.99,40,8,12,0);
INSERT INTO PRODUITS VALUES (9,'Eau minérale lot 24x50cl',1,10,8.99,1000,200,300,0);
INSERT INTO PRODUITS VALUES (10,'Stylos BIC lot 50 unités',3,20,12.99,400,100,150,0);

INSERT INTO COMMANDES VALUES (1, 1, 1, DATE '2026-01-10', DATE '2026-01-20', 1, NULL);
INSERT INTO COMMANDES VALUES (2, 1, 2, DATE '2026-01-15', DATE '2026-01-25', 1, NULL);
INSERT INTO COMMANDES VALUES (3, 2, 1, DATE '2026-02-05', DATE '2026-02-15', 2, NULL);
INSERT INTO COMMANDES VALUES (4, 2, 3, DATE '2026-02-10', DATE '2026-02-20', 2, NULL);
INSERT INTO COMMANDES VALUES (5, 3, 2, DATE '2026-03-01', DATE '2026-03-10', 3, NULL);
INSERT INTO COMMANDES VALUES (6, 1, 4, DATE '2026-03-15', DATE '2026-03-25', 1, NULL);
INSERT INTO COMMANDES VALUES (7, 2, 5, DATE '2026-04-01', DATE '2026-04-10', 2, NULL);
INSERT INTO COMMANDES VALUES (8, 3, 6, DATE '2026-04-15', DATE '2026-04-25', 3, NULL);
INSERT INTO COMMANDES VALUES (9, 1, 7, DATE '2026-05-05', DATE '2026-05-15', 1, NULL);
INSERT INTO COMMANDES VALUES (10, 2, 8, DATE '2026-05-20', DATE '2026-05-30', 2, NULL);

INSERT INTO LIGNECOMMANDES VALUES (1,  1, 1, 150, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (2,  1, 2, 200, 0   );
INSERT INTO LIGNECOMMANDES VALUES (3,  2, 1, 120, 0.10);
INSERT INTO LIGNECOMMANDES VALUES (4,  2, 3, 500, 0   );
INSERT INTO LIGNECOMMANDES VALUES (5,  3, 2, 300, 0.15);
INSERT INTO LIGNECOMMANDES VALUES (6,  3, 1,  50, 0   );
INSERT INTO LIGNECOMMANDES VALUES (7,  4, 3,  80, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (8,  4, 1,  30, 0.10);
INSERT INTO LIGNECOMMANDES VALUES (9,  5, 2,  25, 0   );
INSERT INTO LIGNECOMMANDES VALUES (10, 5, 3,  45, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (11, 6, 4, 150, 0   );
INSERT INTO LIGNECOMMANDES VALUES (12, 6, 5, 200, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (13, 7, 6, 100, 0   );
INSERT INTO LIGNECOMMANDES VALUES (14, 7, 4, 250, 0.10);
INSERT INTO LIGNECOMMANDES VALUES (15, 8, 5, 180, 0   );
INSERT INTO LIGNECOMMANDES VALUES (16, 8, 4,  60, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (17, 9, 5,  45, 0   );
INSERT INTO LIGNECOMMANDES VALUES (18, 9, 6,  30, 0.10);
INSERT INTO LIGNECOMMANDES VALUES (19,10, 4,  80, 0   );
INSERT INTO LIGNECOMMANDES VALUES (20,10, 6,  15, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (21, 1, 7,   3, 0   );
INSERT INTO LIGNECOMMANDES VALUES (22, 2, 9,1000, 0   );
INSERT INTO LIGNECOMMANDES VALUES (23, 3,10, 500, 0.05);
INSERT INTO LIGNECOMMANDES VALUES (24, 8, 8,   5, 0   );
INSERT INTO LIGNECOMMANDES VALUES (25,10, 7,   2, 0.10);

COMMIT;
EXIT;
SQLEOF

echo "[eshop_data.sh] Done."
