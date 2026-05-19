-- ============================================================
-- Nombre de commandes par client en 2026
-- À exécuter sur oracle-central (BDDCENTRAL)
-- Utilise la vue distribuée V_LIGNECOMMANDES_GLOBAL
-- ============================================================

SELECT 
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

-- ============================================================
-- EXPLAIN PLAN de la requête commandes par client en 2026
-- ============================================================

-- 1. Générer le plan
EXPLAIN PLAN FOR
SELECT 
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

-- 2. Afficher le plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================================
-- ANALYSE : opérations coûteuses attendues
-- - FULL TABLE SCAN sur CLIENTS et COMMANDES (pas encore d'index)
-- - HASH JOIN entre CLIENTS et COMMANDES
-- - SORT GROUP BY pour le GROUP BY
-- - SORT ORDER BY pour le ORDER BY DESC
-- ============================================================

-- 3. Créer les index pour améliorer les performances
-- Index sur DATECOMMANDE (critère de filtrage principal)
CREATE INDEX idx_cmd_datecommande
    ON COMMANDES (DATECOMMANDE);

-- Index sur IDCLIENT dans COMMANDES (jointure fréquente)
CREATE INDEX idx_cmd_idclient
    ON COMMANDES (IDCLIENT);

-- Index composite (IDCLIENT + DATECOMMANDE) pour couvrir les deux critères
CREATE INDEX idx_cmd_client_date
    ON COMMANDES (IDCLIENT, DATECOMMANDE);

-- 4. Afficher le plan APRÈS les index
EXPLAIN PLAN FOR
SELECT 
    cl.IDCLIENT,
    cl.SOCIETE,
    cl.CODECLIENT,
    COUNT(DISTINCT c.IDCOMMANDE) AS NB_COMMANDES
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
GROUP BY cl.IDCLIENT, cl.SOCIETE, cl.CODECLIENT
ORDER BY NB_COMMANDES DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================================
-- Chiffre d'affaires total par catégorie de produit en 2026
-- Requête distribuée : somme des contributions Site1 + Site2
-- À exécuter sur oracle-central (BDDCENTRAL)
-- ============================================================

SELECT
    cat.NOMDECATEGORIE,
    SUM(ca.CA_TOTAL) AS CA_TOTAL_2026
FROM (
    -- Contribution Site 1 (QUANTITE >= 100)
    SELECT
        p.IDCATEG,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes1@site1_link lc
    JOIN Produits1@site1_link p ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes1@site1_link c ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG

    UNION ALL

    -- Contribution Site 2 (QUANTITE < 100)
    SELECT
        p.IDCATEG,
        SUM(lc.QUANTITE * p.PRIXUNITAIRE * (1 - lc.REMISE)) AS CA_TOTAL
    FROM LigneCommandes2@site2_link lc
    JOIN Produits2@site2_link p ON lc.IDPRODUIT = p.IDPRODUIT
    JOIN Commandes2@site2_link c ON lc.IDCOMMANDE = c.IDCOMMANDE
    WHERE EXTRACT(YEAR FROM c.DATECOMMANDE) = 2026
    GROUP BY p.IDCATEG
) ca
JOIN CATEGORIES cat ON ca.IDCATEG = cat.IDCATEG
GROUP BY cat.NOMDECATEGORIE
ORDER BY CA_TOTAL_2026 DESC;