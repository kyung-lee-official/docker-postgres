# PostgreSQL with Docker Compose

A lightweight PostgreSQL 18 deployment using Docker Compose, ready for Ubuntu 24.04 VPS.

## Prerequisites

- Docker & Docker Compose installed on your VPS
- Git

## Deployment Steps

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd docker-postgres
```

### 2. Configure environment variables

Copy the example env file and edit it with your own values:

```bash
cp .env.example .env
nano .env
```

### 3. Start the container

```bash
docker compose up -d
```

### 4. Verify it's running

```bash
docker ps
```

You should see `c-postgres-db` with status `Up`.

### 5. Test the connection

```bash
docker exec -it c-postgres-db psql -U postgres -d postgres -c "SELECT version();"
```

### 6. (Optional) View logs

```bash
docker compose logs -f
```

## Useful Commands

| Command                                                      | Description                                    |
| ------------------------------------------------------------ | ---------------------------------------------- |
| `docker compose up -d`                                       | Start PostgreSQL in background                 |
| `docker compose down`                                        | Stop and remove the container (data persists)  |
| `docker compose down -v`                                     | Stop and **delete all data** (⚠️ irreversible) |
| `docker compose logs -f`                                     | Tail logs                                      |
| `docker compose restart`                                     | Restart the container                          |
| `docker exec -it c-postgres-db psql -U postgres -d postgres` | Open interactive PostgreSQL shell              |

## Resource Limits

This container is configured for a **2-core, 2GB RAM VPS**:

- **Memory limit**: 512MB
- **Shared memory (`shm_size`)**: 128MB
- **Restart policy**: Auto-restart unless manually stopped

## Data Persistence

Database files are stored in a Docker named volume (`postgres-data`). Your data survives container restarts and re-creates. To back it up:

```bash
docker exec -t c-postgres-db pg_dumpall -U postgres > backup.sql
```

To restore:

```bash
cat backup.sql | docker exec -i c-postgres-db psql -U postgres
```

## Flags Reference

| Flag | Meaning                                                             | Used In                             |
| ---- | ------------------------------------------------------------------- | ----------------------------------- |
| `-d` | **Detached** — runs container in the background                     | `docker compose up -d`              |
| `-v` | **Volumes** — removes associated volumes (⚠️ deletes data)          | `docker compose down -v`            |
| `-f` | **Follow** — tails logs in real-time                                | `docker compose logs -f`            |
| `-i` | **Interactive** — keeps STDIN open, allows sending input            | `docker exec -it`                   |
| `-t` | **TTY** — allocates a pseudo-terminal, needed for interactive shell | `docker exec -it`, `docker exec -t` |
| `-U` | **Username** — specifies the PostgreSQL user to connect as          | `psql -U postgres`                  |
| `-d` | **Database** — specifies the database name to connect to            | `psql -d postgres`                  |
| `-c` | **Command** — runs a single SQL command and exits                   | `psql -c "SELECT version();"`       |

> Note: `-i` and `-t` are almost always used together as `-it` to get an interactive terminal session inside the container.
