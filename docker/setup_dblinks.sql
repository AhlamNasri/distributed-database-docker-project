-- ============================================================
-- setup_dblinks.sql
-- Configuration des Database Links — Site Central → Site1 & Site2
-- À exécuter sur oracle-central (BDDCENTRAL)
-- Prérequis : grants.sh doit avoir été exécuté au préalable
--             (GRANT CREATE DATABASE LINK TO eshopcentral)
-- ============================================================

-- -------------------------------------------------------
-- 1. Database Link Central → Site 1 (QUANTITE >= 100)
-- -------------------------------------------------------
CREATE DATABASE LINK site1_link
  CONNECT TO eshop1 IDENTIFIED BY eshop1pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site1)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE))
  )';

-- -------------------------------------------------------
-- 2. Database Link Central → Site 2 (QUANTITE < 100)
-- -------------------------------------------------------
CREATE DATABASE LINK site2_link
  CONNECT TO eshop2 IDENTIFIED BY eshop2pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site2)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE2))
  )';

-- -------------------------------------------------------
-- 3. Tests de connectivité
-- -------------------------------------------------------
-- Test Site1 :
-- SELECT COUNT(*) FROM LigneCommandes1@site1_link;
-- Test Site2 :
-- SELECT COUNT(*) FROM LigneCommandes2@site2_link;
-- Test bidirectionnel depuis Site1 vers Central :
-- (se connecter sur oracle-site1 puis :)
-- SELECT COUNT(*) FROM COMMANDES@central_link;

-- -------------------------------------------------------
-- 4. Vue distribuée globale Scénario 2 (UNION des deux sites)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_LIGNECOMMANDES_GLOBAL AS
  SELECT 'SITE1' AS SITE, lc.* FROM LigneCommandes1@site1_link lc
  UNION ALL
  SELECT 'SITE2' AS SITE, lc.* FROM LigneCommandes2@site2_link lc;

-- -------------------------------------------------------
-- 5. Vue distribuée globale Scénario 1 (fragmentation catégorie)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_LIGNECOMMANDES_GLOBAL_SC1 AS
  SELECT 'SITE1' AS SITE, lc.* FROM LigneCommandes1_sc1@site1_link lc
  UNION ALL
  SELECT 'SITE2' AS SITE, lc.* FROM LigneCommandes2_sc1@site2_link lc;

-- -------------------------------------------------------
-- 6. Vue produits globale (union des deux sites — Scénario 2)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_PRODUITS_GLOBAL AS
  SELECT 'SITE1' AS SITE, p.* FROM Produits1@site1_link p
  UNION ALL
  SELECT 'SITE2' AS SITE, p.* FROM Produits2@site2_link p;

-- -------------------------------------------------------
-- 7. Vue commandes globale (union des deux sites — Scénario 2)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_COMMANDES_GLOBAL AS
  SELECT 'SITE1' AS SITE, c.* FROM Commandes1@site1_link c
  UNION ALL
  SELECT 'SITE2' AS SITE, c.* FROM Commandes2@site2_link c;

COMMIT;
