# Distributed Database Project — EShop (Oracle PL/SQL + Docker)

## Description
Simulates a distributed Oracle database environment for an EShop system using Docker.
Covers horizontal fragmentation, stored procedures, triggers, and indexes across two database nodes.

## Scenarios
- **Scenario 1** — Fragmentation by category (`idcateg = 50` vs `idcateg = 35`)
- **Scenario 2** — Fragmentation by volume (`Quantite ≥ 100` vs `Quantite < 100`)

## Project Structure
- `docker/` — Docker Compose files and network configuration
- `scenario1/` — Fragments, indexes, procedures, triggers (category-based)
- `scenario2/` — Fragments, indexes, procedures, triggers (volume-based)
- `tests/` — Connectivity tests and distributed query tests
- `rapport/` — Project report

## Prerequisites
- Docker & Docker Compose
- Oracle Database image (e.g., `gvenzl/oracle-xe`)

## Getting Started
```bash
cd docker/
docker-compose up -d
```
