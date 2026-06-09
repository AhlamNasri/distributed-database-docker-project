-- ============================================================
-- site2_synonyms.sql — Site2, Scénario 1 (IDCATEG = 35)
-- Synonymes locaux pour accès transparent
-- ============================================================

-- Accès aux données distantes de Site1 (catég 50) sans @link
CREATE OR REPLACE SYNONYM S1_LigneCommandes_sc1
    FOR LigneCommandes1_sc1@site1_link;

CREATE OR REPLACE SYNONYM S1_Produits_sc1
    FOR Produits1_sc1@site1_link;

CREATE OR REPLACE SYNONYM S1_Commandes_sc1
    FOR Commandes1_sc1@site1_link;

CREATE OR REPLACE SYNONYM S1_Clients_sc1
    FOR Clients1_sc1@site1_link;

-- Vue globale Scénario 1 depuis Site2
CREATE OR REPLACE VIEW V_LIGNES_GLOBAL_SC1 AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM S1_LigneCommandes_sc1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM LigneCommandes2_sc1 lc;

-- Vérification
-- SELECT SYNONYM_NAME, TABLE_OWNER, TABLE_NAME, DB_LINK
-- FROM USER_SYNONYMS ORDER BY SYNONYM_NAME;

COMMIT;
