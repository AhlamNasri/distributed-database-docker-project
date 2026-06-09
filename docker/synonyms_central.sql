-- ============================================================
-- synonyms_central.sql
-- À exécuter sur oracle-central APRÈS setup_dblinks.sql
-- Crée des synonymes locaux → tables distantes via DB links
-- Objectif : accès transparent sans notation @link
-- ============================================================

-- -------------------------------------------------------
-- Synonymes vers Site 1 (QUANTITE >= 100 — Scénario 2)
-- -------------------------------------------------------
CREATE OR REPLACE SYNONYM LigneCommandes1
    FOR LigneCommandes1@site1_link;

CREATE OR REPLACE SYNONYM Commandes1
    FOR Commandes1@site1_link;

CREATE OR REPLACE SYNONYM Clients1
    FOR Clients1@site1_link;

CREATE OR REPLACE SYNONYM Produits1
    FOR Produits1@site1_link;

-- -------------------------------------------------------
-- Synonymes vers Site 2 (QUANTITE < 100 — Scénario 2)
-- -------------------------------------------------------
CREATE OR REPLACE SYNONYM LigneCommandes2
    FOR LigneCommandes2@site2_link;

CREATE OR REPLACE SYNONYM Commandes2
    FOR Commandes2@site2_link;

CREATE OR REPLACE SYNONYM Clients2
    FOR Clients2@site2_link;

CREATE OR REPLACE SYNONYM Produits2
    FOR Produits2@site2_link;

-- -------------------------------------------------------
-- Synonymes Scénario 1 (fragmentation par catégorie)
-- -------------------------------------------------------
CREATE OR REPLACE SYNONYM LigneCommandes1_sc1
    FOR LigneCommandes1_sc1@site1_link;

CREATE OR REPLACE SYNONYM Produits1_sc1
    FOR Produits1_sc1@site1_link;

CREATE OR REPLACE SYNONYM Categories1_sc1
    FOR Categories1_sc1@site1_link;

CREATE OR REPLACE SYNONYM LigneCommandes2_sc1
    FOR LigneCommandes2_sc1@site2_link;

CREATE OR REPLACE SYNONYM Produits2_sc1
    FOR Produits2_sc1@site2_link;

CREATE OR REPLACE SYNONYM Categories2_sc1
    FOR Categories2_sc1@site2_link;

-- -------------------------------------------------------
-- Vue globale avec synonymes (sans @link)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_LIGNECOMMANDES_GLOBAL_SYN AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM LigneCommandes1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM LigneCommandes2 lc;

-- -------------------------------------------------------
-- Vérification
-- -------------------------------------------------------
-- SELECT SYNONYM_NAME, TABLE_OWNER, TABLE_NAME, DB_LINK
-- FROM USER_SYNONYMS
-- ORDER BY SYNONYM_NAME;

COMMIT;
