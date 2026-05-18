-- ============================================================
-- Configuration des Database Links
-- Site Central → Site1 et Site2
-- À exécuter sur oracle-central (BDDCENTRAL)
-- ============================================================

-- -------------------------------------------------------
-- 1. Database Link vers Site 1 (QUANTITE >= 100)
-- -------------------------------------------------------
CREATE DATABASE LINK site1_link
  CONNECT TO eshop1 IDENTIFIED BY eshop1pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site1)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE))
  )';

-- -------------------------------------------------------
-- 2. Database Link vers Site 2 (QUANTITE < 100)
-- -------------------------------------------------------
CREATE DATABASE LINK site2_link
  CONNECT TO eshop2 IDENTIFIED BY eshop2pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site2)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE2))
  )';

-- -------------------------------------------------------
-- 3. Test des liens
-- -------------------------------------------------------
-- Tester site1 :
-- SELECT COUNT(*) FROM LigneCommandes1@site1_link;

-- Tester site2 :
-- SELECT COUNT(*) FROM LigneCommandes2@site2_link;

-- -------------------------------------------------------
-- 4. Vue distribuée globale (UNION des deux sites)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW V_LIGNECOMMANDES_GLOBAL AS
  SELECT * FROM LigneCommandes1@site1_link
  UNION ALL
  SELECT * FROM LigneCommandes2@site2_link;

COMMIT;
