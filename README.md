# PlayMatch Backend (Express + MySQL + JWT)

Backend listo para Render con CRUD genérico para **todas** las tablas del esquema PlayMatch y autenticación JWT.

## 🚀 Quick start

```bash
npm install
cp .env.example .env  # o edita .env con tus valores (ya viene preparado)
npm start
```

El servidor expone `http://localhost:3000`.

## 🔑 Autenticación

- `POST /api/auth/login` — body: `{ "email": "...", "password": "..." }` o `{ "username": "...", "password": "..." }`
- Respuesta: `{ token, user }`
- Usa el token en `Authorization: Bearer <token>` para las rutas protegidas.

> **Nota:** si no hay usuarios con `password_hash`, crea uno con `/api/auth/register` (opcional) o inserta en BD con bcrypt.

## 🧰 Endpoints de salud
- `GET /api/health` → `{ status: "ok" }`
- `GET /api/health/db` → `{ db: "up" | "down" }`

## 📦 CRUD genérico (todas las tablas)

- Listar: `GET /api/<table>?limit=50&offset=0&orderBy=id DESC`
- Obtener por ID (PK simple): `GET /api/<table>/<id>`
- Crear: `POST /api/<table>` body = objeto con columnas válidas
- Actualizar:
  - PK simple: `PUT /api/<table>/<id>` body = columnas a actualizar
  - PK compuesta: `PUT /api/<table>` body = `{ pk: { col1, col2, ... }, ...campos }`
- Borrar:
  - PK simple: `DELETE /api/<table>/<id>`
  - PK compuesta: `DELETE /api/<table>` body = `{ pk: { col1, col2, ... } }`

Tablas permitidas (whitelist): `clubs, game_types, modalities, levels, user_role_tags, users, user_groups, user_group_members, user_passes, courts, court_game_types, court_blocks, court_block_slots, matches, match_players, bookings, chats, chat_participants, messages, bar_tables, bar_orders, bar_order_items, cash_drawer_sessions, access_logs, internal_messages, internal_message_readers, themes`.

## 🏷️ Endpoints extra (matches)

- `GET /api/matches/detailed` — lista partidos con joins de club, court, game_type, level, modality
- `GET /api/matches/:matchId/players` — jugadores de un partido

## 🔒 Roles

El middleware incluye `requireRole([...])` si deseas restringir por rol (`superadmin`, `admin`, etc.). Actualmente, el CRUD genérico solo requiere estar autenticado.

## ⚙️ Variables de entorno

```
DB_HOST=...
DB_USER=...
DB_PASSWORD=...
DB_NAME=playmatch
DB_PORT=3306
JWT_SECRET=...
PORT=3000
```

> `.env` está en `.gitignore`. En Render, configúralas en **Environment**.

## 📁 Estructura

```
src/
  db.js
  middleware/auth.js
  routes/
    auth.js
    health.js
    generic.js
    matches_extra.js
server.js
```

## ☁️ Deploy en Render

1. Sube este proyecto a GitHub.
2. En Render → **New Web Service** → Link al repo.
3. Runtime: Node, `Build Command: npm install`, `Start Command: npm start`.
4. Añade las variables de entorno anteriores.
5. Listo.
```

