-- ============================================================
-- SITE 1 - INDEXES (Scenario 2)
-- Règle fragment : QUANTITE >= 100
-- Tables : LigneCommandes1, Commandes1, Clients1, Produits1
-- ============================================================

-- -------------------------------------------------------
-- 1. Index sur LigneCommandes1
-- -------------------------------------------------------

-- Index sur QUANTITE (critère principal de fragmentation)
CREATE INDEX idx_lc1_quantite
    ON LigneCommandes1 (QUANTITE);

-- Index sur IDCOMMANDE (jointure fréquente avec Commandes1)
CREATE INDEX idx_lc1_idcommande
    ON LigneCommandes1 (IDCOMMANDE);

-- Index sur IDPRODUIT (jointure fréquente avec Produits1)
CREATE INDEX idx_lc1_idproduit
    ON LigneCommandes1 (IDPRODUIT);

-- Index composite (IDCOMMANDE + QUANTITE) pour les requêtes filtrées
CREATE INDEX idx_lc1_cmd_qte
    ON LigneCommandes1 (IDCOMMANDE, QUANTITE);

-- -------------------------------------------------------
-- 2. Index sur Commandes1
-- -------------------------------------------------------

-- Index sur IDCLIENT (jointure fréquente avec Clients1)
CREATE INDEX idx_cmd1_idclient
    ON Commandes1 (IDCLIENT);

-- Index sur DATECOMMANDE (requêtes par période)
CREATE INDEX idx_cmd1_date
    ON Commandes1 (DATECOMMANDE);

-- -------------------------------------------------------
-- 3. Index sur Produits1
-- -------------------------------------------------------

-- Index sur IDCATEG (filtrage par catégorie)
CREATE INDEX idx_prod1_idcateg
    ON Produits1 (IDCATEG);

-- Index sur PRIXUNITAIRE (requêtes de tri/filtrage par prix)
CREATE INDEX idx_prod1_prix
    ON Produits1 (PRIXUNITAIRE);

-- -------------------------------------------------------
-- 4. Index sur Clients1
-- -------------------------------------------------------

-- Index sur PAYS (filtrage géographique)
CREATE INDEX idx_cli1_pays
    ON Clients1 (PAYS);

-- Index sur VILLE
CREATE INDEX idx_cli1_ville
    ON Clients1 (VILLE);

-- -------------------------------------------------------
-- VERIFICATION : lister les index créés
-- -------------------------------------------------------
-- SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME
-- FROM USER_IND_COLUMNS
-- WHERE TABLE_NAME IN ('LIGNECOMMANDES1','COMMANDES1','PRODUITS1','CLIENTS1')
-- ORDER BY TABLE_NAME, INDEX_NAME;

COMMIT;
