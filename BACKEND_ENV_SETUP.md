# Backend Environment Setup

## What changed

The backend and Docker Compose setup now read database and auth settings from environment variables instead of hardcoding them in:

- [application.properties](/Users/simeonsimeonov/my_fitness_app/resource-server/mytrainer2/src/main/resources/application.properties)
- [docker-compose.yml](/Users/simeonsimeonov/my_fitness_app/docker-compose.yml)
- [docker-compose.prod.yml](/Users/simeonsimeonov/my_fitness_app/docker-compose.prod.yml)

Local development still works by default because Spring properties include local fallback values.

## Files to use

- Local Docker template:
  - [.env.example](/Users/simeonsimeonov/my_fitness_app/.env.example)
- Hetzner template:
  - [.env.hetzner.example](/Users/simeonsimeonov/my_fitness_app/.env.hetzner.example)

Your real runtime file should be:

```bash
.env
```

That file is already ignored by git.

## Local test commands

1. Create your local env file:

```bash
cd /Users/simeonsimeonov/my_fitness_app
cp .env.example .env
```

2. Build and start locally:

```bash
cd /Users/simeonsimeonov/my_fitness_app
docker compose up --build
```

3. Start detached:

```bash
cd /Users/simeonsimeonov/my_fitness_app
docker compose up -d --build
```

4. Check logs:

```bash
cd /Users/simeonsimeonov/my_fitness_app
docker compose logs -f resource-server
docker compose logs -f keycloak
docker compose logs -f mysql
```

5. Stop:

```bash
cd /Users/simeonsimeonov/my_fitness_app
docker compose down
```

## Hetzner commands

1. Create `.env` on the server:

```bash
cd /path/to/my_fitness_app
cp .env.hetzner.example .env
```

2. Edit `.env` and replace:

- DB passwords
- Keycloak admin password
- public issuer URL
- public web invite URL
- your domain values

3. Start production:

```bash
cd /path/to/my_fitness_app
docker compose -f docker-compose.prod.yml up -d --build
```

4. Check status:

```bash
cd /path/to/my_fitness_app
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f resource-server
docker compose -f docker-compose.prod.yml logs -f keycloak
```

## Notes

- `SPRING_DATASOURCE_URL` should point to `mysql:3306` inside Docker
- `KEYCLOAK_ISSUER_URI` must be the public URL used by clients
- `KEYCLOAK_JWK_SET_URI` can stay internal if only the container needs it
- `KEYCLOAK_ALLOWED_ISSUERS` should match the issuer values your clients and tokens use
