SET SERVEROUTPUT ON
PROMPT === LIGNECOMMANDES (doit etre vide) ===
SELECT COUNT(*) AS LIGNECOMMANDES_CENTRAL FROM LIGNECOMMANDES;

PROMPT === Fragment Site1 via DB Link (doit avoir 12 lignes) ===
SELECT COUNT(*) AS LIGNECOMMANDES1_SITE1 FROM LigneCommandes1@site1_link;

PROMPT === Fragment Site2 via DB Link (doit avoir 13 lignes) ===
SELECT COUNT(*) AS LIGNECOMMANDES2_SITE2 FROM LigneCommandes2@site2_link;

PROMPT === Vue globale (doit avoir 25 lignes au total) ===
SELECT SITE, COUNT(*) AS NB_LIGNES
FROM V_LIGNECOMMANDES_GLOBAL_SYN
GROUP BY SITE ORDER BY SITE;

EXIT;
