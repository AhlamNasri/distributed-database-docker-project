# Distributed Database Project — EShop (Oracle PL/SQL + Docker)

## Description

Simule un environnement Oracle distribué pour un système EShop. Couvre la fragmentation
horizontale, les procédures stockées, les triggers, les index et les database links
bidirectionnels entre trois nœuds Oracle XE.

## Architecture

```
┌─────────────────┐        DB LINK        ┌─────────────────┐
│  oracle-site1   │◄─────────────────────►│  oracle-site2   │
│  172.20.0.10    │                        │  172.20.0.11    │
│  BDDVENTE:1521  │                        │  BDDVENTE2:1522 │
│  eshop1         │                        │  eshop2         │
│  Sc2: QTE>=100  │                        │  Sc2: QTE<100   │
│  Sc1: categ=50  │                        │  Sc1: categ=35  │
└────────┬────────┘                        └────────┬────────┘
         │              DB LINK                     │
         └──────────────────┬───────────────────────┘
                            │
                 ┌──────────▼────────┐
                 │  oracle-central   │
                 │  172.20.0.12      │
                 │  BDDCENTRAL:1523  │
                 │  eshopcentral     │
                 │  Vues distribuées │
                 │  Synonymes        │
                 └───────────────────┘
```

## Scénarios de fragmentation

| Scénario | Site 1 | Site 2 |
|----------|--------|--------|
| **Sc1** — par catégorie | `IDCATEG = 50` (Informatique) | `IDCATEG = 35` (Accessoires) |
| **Sc2** — par volume   | `QUANTITE >= 100` (Grossistes) | `QUANTITE < 100` (Détaillants) |

**Docker Compose déploie le Scénario 2** (volumes montés vers `scenario2/`).
Pour Scénario 1, modifier les chemins dans `docker-compose.yml`.

## Prérequis

- Docker Desktop ≥ 4.x
- Docker Compose ≥ 2.x
- 8 Go RAM disponibles (Oracle XE consomme ~2 Go par conteneur)
- Sur Linux/Mac : `bash` disponible

## Démarrage rapide

```bash
# 1. Cloner le dépôt
git clone <url>
cd distributed-database-docker-project-main

# 2. Rendre les scripts exécutables (Linux/Mac uniquement)
chmod +x docker/grants.sh
chmod +x monitoring/check_health.sh
chmod +x scripts/connectivity_test.sh
chmod +x scripts/start.sh

# 3. Démarrer le cluster (depuis la RACINE du projet)
bash scripts/start.sh

# -- OU manuellement --
docker-compose up -d

# 4. Attendre que les 3 conteneurs soient healthy (~3-5 min)
docker-compose ps

# 5. Vérifier la connectivité
bash scripts/connectivity_test.sh
```

> **Note Windows** : les scripts `.sh` s'exécutent via Git Bash ou WSL.
> Pour démarrer depuis PowerShell : `docker-compose up -d`

## Structure du projet

```
.
├── docker-compose.yml              ← Configuration des 3 services
├── schema/
│   └── eshop_global.sql            ← DDL : CREATE TABLE + contraintes
├── data/
│   └── eshop_data.sql              ← DML : INSERT données initiales (25 LC)
├── docker/
│   ├── grants.sh                   ← GRANT privilèges SYS → APP_USER
│   ├── setup_dblinks.sql           ← DB Links Central → Site1/Site2
│   └── synonyms_central.sql        ← Synonymes pour accès transparent
├── site1/
│   ├── dblinks/site1_dblinks.sql   ← DB Links Site1 → Site2 + Central
│   ├── scenario1/
│   │   ├── fragments/              ← Fragmentation par IDCATEG=50
│   │   ├── procedures/             ← INSERT/UPDATE/DELETE avec règles
│   │   ├── triggers/               ← Contrôle catégorie + log
│   │   ├── indexes/                ← Index catégorie/jointure
│   │   └── synonyms/               ← Synonymes distants (Site2)
│   └── scenario2/
│       ├── fragments/              ← Fragmentation QUANTITE>=100
│       ├── procedures/             ← INSERT/UPDATE/DELETE avec règles
│       ├── triggers/               ← Contrôle quantité + log
│       ├── indexes/                ← Index quantité/jointure/composite
│       └── synonyms/               ← Synonymes distants (Site2)
├── site2/                          ← Structure miroir de site1
├── tests/
│   ├── site1_scenario1_tests.sql   ← Tests CRUD + triggers Site1 Sc1
│   ├── site1_scenario2_tests.sql   ← Tests CRUD + triggers Site1 Sc2
│   ├── site2_scenario1_tests.sql   ← Tests CRUD + triggers Site2 Sc1
│   ├── site2_scenario2_tests.sql   ← Tests CRUD + triggers Site2 Sc2
│   ├── distributed_queries.sql     ← Requêtes distribuées + EXPLAIN PLAN
│   └── performance_analysis.sql    ← Analyse comparative AVANT/APRÈS index
├── monitoring/
│   ├── check_dblinks.sql           ← Test connectivité DB Links
│   ├── monitor_logs.sql            ← Surveillance tables de log
│   └── check_health.sh             ← Health check complet du cluster
├── maintenance/
│   ├── purge_logs.sql              ← Purge entrées log > 30 jours
│   ├── rebuild_indexes.sql         ← Reconstruction des index
│   └── analyze_tables.sql          ← Collecte statistiques (DBMS_STATS)
└── scripts/
    ├── start.sh                    ← Démarrage ordonné du cluster
    └── connectivity_test.sh        ← Tests ping + SQL*Plus + DB Links
```

## Connexion aux bases de données

```bash
# Site 1
docker exec -it oracle-site1 sqlplus eshop1/eshop1pass@//localhost:1521/BDDVENTE

# Site 2
docker exec -it oracle-site2 sqlplus eshop2/eshop2pass@//localhost:1521/BDDVENTE2

# Central
docker exec -it oracle-central sqlplus eshopcentral/centralpass@//localhost:1521/BDDCENTRAL

# Depuis la machine hôte (client SQL*Plus local)
sqlplus eshop1/eshop1pass@//localhost:1521/BDDVENTE
sqlplus eshop2/eshop2pass@//localhost:1522/BDDVENTE2
sqlplus eshopcentral/centralpass@//localhost:1523/BDDCENTRAL
```

## Exécution des tests

```bash
# Tests CRUD complets — Site1 Scénario 2
docker exec oracle-site1 sqlplus eshop1/eshop1pass@//localhost:1521/BDDVENTE \
    @/docker-entrypoint-initdb.d/site1_scenario2_tests.sql

# Tests de connectivité réseau
bash scripts/connectivity_test.sh

# Surveillance des DB Links (depuis oracle-central)
docker exec oracle-central sqlplus eshopcentral/centralpass@//localhost:1521/BDDCENTRAL \
    @/path/to/monitoring/check_dblinks.sql

# Health check complet
bash monitoring/check_health.sh
```

## Ordre d'initialisation des scripts (critique)

L'image `gvenzl/oracle-xe` exécute les fichiers de `/docker-entrypoint-initdb.d/`
**par ordre alphabétique**. Les répertoires sont préfixés numériquement pour garantir
l'ordre correct :

```
01_schema/    → CREATE TABLE (tables vides)
02_data/      → INSERT données
03_grants.sh  → GRANT CREATE DATABASE LINK, SYNONYM, VIEW
04_dblinks/   → CREATE DATABASE LINK
05_fragments/ → CREATE TABLE AS SELECT (nécessite données en 02)
06_procedures/→ CREATE PROCEDURE
07_triggers/  → CREATE TRIGGER
08_indexes/   → CREATE INDEX
09_synonyms/  → CREATE SYNONYM
```

> **Problème corrigé** : l'ordre alphabétique brut (`fragments/ < schema/`)
> aurait exécuté les fragments AVANT le schéma, causant des erreurs.

## Database Links — Architecture bidirectionnelle

| Depuis | Vers | Lien |
|--------|------|------|
| oracle-central | oracle-site1 | `site1_link` |
| oracle-central | oracle-site2 | `site2_link` |
| oracle-site1 | oracle-site2 | `site2_link` |
| oracle-site1 | oracle-central | `central_link` |
| oracle-site2 | oracle-site1 | `site1_link` |
| oracle-site2 | oracle-central | `central_link` |

## Routage automatique depuis le central

Le central expose des vues ecrivables qui redirigent les insertions,
modifications et suppressions vers le bon site via les DB links. Les ecritures
directes dans la table centrale `LIGNECOMMANDES` sont aussi interceptees par un
trigger et routees vers le fragment distant correspondant.

Scenario 2, deploye par defaut dans `docker-compose.yml` :

- Vue centrale : `V_LIGNECOMMANDES_ROUTAGE`
- `QUANTITE >= 100` est route vers `oracle-site1`.
- `QUANTITE < 100` est route vers `oracle-site2`.

Scenario 1, disponible quand les chemins Docker sont bascules vers `scenario1/` :

- Vue centrale : `V_LIGNECOMMANDES_ROUTAGE_SC1`
- `IDCATEG = 50` est route vers `oracle-site1`.
- `IDCATEG = 35` est route vers `oracle-site2`.

Dans les deux cas, les references manquantes du fragment cible (`Clients`,
`Commandes`, `Produits`, et `Categories` pour Scenario 1) sont copiees
automatiquement depuis les tables globales du central. Les operations sont
tracees dans `ROUTING_LOG`.

Exemple Scenario 2 depuis `oracle-central` :

```sql
INSERT INTO V_LIGNECOMMANDES_ROUTAGE
    (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
VALUES
    (9001, 1, 1, 150, 0);
COMMIT;

UPDATE V_LIGNECOMMANDES_ROUTAGE
SET QUANTITE = 25
WHERE IDLIGNECOMMANDE = 9001;
COMMIT;
```

Test de demonstration :

```bash
docker cp tests/central_routing_tests.sql oracle-central:/tmp/central_routing_tests.sql
docker exec oracle-central sqlplus eshopcentral/centralpass@//localhost:1521/BDDCENTRAL \
    @/tmp/central_routing_tests.sql
```

Test des ecritures directes dans la table centrale :

```bash
docker cp tests/central_direct_table_routing_tests.sql oracle-central:/tmp/central_direct_table_routing_tests.sql
docker exec oracle-central sqlplus eshopcentral/centralpass@//localhost:1521/BDDCENTRAL \
    @/tmp/central_direct_table_routing_tests.sql
```

Test Scenario 1 apres deploiement des fragments `scenario1/` :

```bash
docker cp tests/central_routing_sc1_tests.sql oracle-central:/tmp/central_routing_sc1_tests.sql
docker exec oracle-central sqlplus eshopcentral/centralpass@//localhost:1521/BDDCENTRAL \
    @/tmp/central_routing_sc1_tests.sql
```

## Schéma de données

25 lignes de commande réparties :

| Fragment | Critère | Lignes | Produits |
|----------|---------|--------|---------|
| Site1 Sc2 | `QUANTITE >= 100` | 12 | catég 50 + 35 + autres |
| Site2 Sc2 | `QUANTITE < 100` | 13 | catég 50 + 35 + autres |
| Site1 Sc1 | `IDCATEG = 50` | 10 | Informatique |
| Site2 Sc1 | `IDCATEG = 35` | 10 | Accessoires |

## Arrêt du cluster

```bash
# Arrêt sans suppression des données
docker-compose stop

# Arrêt avec suppression des volumes (reset complet)
docker-compose down -v
```
