-- ============================================================
-- site1_synonyms.sql — Site1, Scénario 1 (IDCATEG = 50)
-- Synonymes locaux pour accès transparent
-- ============================================================

-- Accès aux données distantes de Site2 (catég 35) sans @link
CREATE OR REPLACE SYNONYM S2_LigneCommandes_sc1
    FOR LigneCommandes2_sc1@site2_link;

CREATE OR REPLACE SYNONYM S2_Produits_sc1
    FOR Produits2_sc1@site2_link;

CREATE OR REPLACE SYNONYM S2_Commandes_sc1
    FOR Commandes2_sc1@site2_link;

CREATE OR REPLACE SYNONYM S2_Clients_sc1
    FOR Clients2_sc1@site2_link;

-- Vue globale Scénario 1 depuis Site1
CREATE OR REPLACE VIEW V_LIGNES_GLOBAL_SC1 AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM LigneCommandes1_sc1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM S2_LigneCommandes_sc1 lc;

-- Vérification
-- SELECT SYNONYM_NAME, TABLE_OWNER, TABLE_NAME, DB_LINK
-- FROM USER_SYNONYMS ORDER BY SYNONYM_NAME;

COMMIT;
