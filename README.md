# 🏋️‍♀️  **my\_fitness\_app** — spin‑up, sweat, commit 💦

*clone → `compose up` → ship code → go lift.*

---

## ⚡  Quick flex (TL;DR)

```bash
# 1. grab the code
git clone https://github.com/your-handle/my_fitness_app.git
cd my_fitness_app

# 2. one‑time bake – bundles the Keycloak SPI jar
docker compose build keycloak

# 3. light the stack on fire 🔥
docker compose up -d
```

| 🛰️ Service        | 🌍 URL                                                         | creds                |
| ------------------ | -------------------------------------------------------------- | -------------------- |
| **Keycloak admin** | [http://localhost:8081/admin](http://localhost:8081/admin)     | `admin / adminpass`  |
| **Spring API**     | [http://localhost:8080/api/\*\*](http://localhost:8080/api/**) | bearer token from KC |
| **Flutter Web**    | [http://localhost/](http://localhost/)                         | *(open web app)*     |

> **Pro‑tip:** MySQL listens on **localhost:3307** (root/r00tpass) if you need raw DB vibes.

---

## 🔍  Tech stack

| Layer          | Version\*     | Source                                                                        |
| -------------- | ------------- | ----------------------------------------------------------------------------- |
| Keycloak       | 26.x          | `keycloak/Dockerfile` → `quay.io/keycloak/keycloak:latest` (currently 26.1.4) |
| MySQL          | 8             | `docker-compose.yml` → `image: mysql:8`                                       |
| Spring Boot    | 3.x (Java 17) | backend Dockerfile pulls `amazoncorretto:17`                                  |
| Flutter        | 3.24.4        | frontend Dockerfile `git checkout 3.24.4`                                     |
| Docker Compose | v2+           | orchestrator                                                                  |

*Pump the versions by editing Dockerfiles whenever you wanna ride the new hotness 😎*

---

## 🗂️  Repo map

```text
my_fitness_app/
├─ db/                       🌱 seed SQL & KC realm dumps
│  ├─ init-YYYYMMDD.sql
│  └─ myrealm-realm-YYYYMMDD.json
│
├─ keycloak/                 🔐 custom KC image + SPI
│  ├─ Dockerfile
│  └─ keycloak-trainer-provisioning-spi-1.0.0.jar
│
├─ resource-server/          ⚙️  Spring backend
│  ├─ Dockerfile
│  └─ mytrainer2/…
│
├─ flutter-client/           📱 Flutter web (and mobile if you want)
│  ├─ Dockerfile
│  └─ mytrainer2client/…
│
├─ scripts/
│  └─ export-state.ps1       🧙 one‑liner to re‑dump DB + realm
└─ docker-compose.yml        🎛️ service orchestrator
```

---

## 🚀  First ride (detailed)

1. **Clone** the repo
2. **Build Keycloak** once (includes the trainer‑provisioning SPI JAR)
3. **Compose up** – waits for MySQL & Keycloak healthchecks, then boots the Spring API and Flutter web client.

```bash
git clone https://github.com/your-handle/my_fitness_app.git
cd my_fitness_app
docker compose build keycloak
docker compose up -d
```

✅ MySQL + seed data

✅ Keycloak realm auto‑imported

✅ Spring API + Flutter already hooked up

---

## ✍️  Dev flow

### 💻  Regular code change

```bash
git add .
git commit -m "✨ feat: add dark‑mode toggle"
git push
```

### 🌱  DB / realm update

1. Boot the stack and tweak data/users/etc. in admin UIs.
2. Freeze the new state:

```powershell
scripts\export-state.ps1
```

↳ drops fresh `db/init-*.sql` & `db/*-realm-*.json`

3. Commit the goodies

```bash
git add db/*.sql db/*-realm-*.json
git commit -m "seed: refresh demo data (dark‑mode edition)"
git push
```

### 👯‍♀️  Team sync

```bash
git pull
docker compose down --volumes
docker compose up -d
```

Boom – everybody’s DB & realm stay 💯 in sync.

---

## 🛟  Troubleshooting cheatsheet

| Symptom                         | Quick fix                                                                    |
| ------------------------------- | ---------------------------------------------------------------------------- |
| **Keycloak 404** on `/admin`    | Did you expose port 8081? Check `docker compose ps`.                         |
| **Spring API screams about DB** | MySQL not healthy yet – wait a sec or peek with `docker compose logs mysql`. |
| **Flutter web white‑screens**   | Auth env wrong? Verify `KEYCLOAK_AUTH_URL` in `resource-server` and CORS.    |
| **Port already in use**         | Change the host ports in `docker-compose.yml` (left side before `:`).        |

---

## 🤝  Contributing

Pull requests welcome – just keep the commit messages meme‑worthy and the code swole.

---

## 📜  License

MIT – do whatever, just don’t sue me if you drop a dumbbell on your foot.

---

Happy hacking & heavy lifting! 🏋️‍♂️🚀
