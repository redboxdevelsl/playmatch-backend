# PlayMatch Backend (Express + MySQL)

Backend listo para desplegar en **Render**, conectado a **MySQL en CDmon**.

## 1) Requisitos
- Node.js 18+
- Credenciales de MySQL (CDmon): host, puerto (3306), usuario, contraseña, base de datos.
  - Asegúrate de que tu usuario MySQL permite **accesos remotos** y que el firewall de CDmon lo permite.

## 2) Configuración local (opcional)
```bash
cp .env.example .env
# Rellena las variables con tus datos de CDmon
npm install
npm run dev
```
- `GET http://localhost:10000/` → "PlayMatch API running"
- `GET http://localhost:10000/health/db` → {"db":"up"} si la DB conecta.

## 3) Endpoints
- `POST /api/auth/register` { email, password, full_name, username? }
- `POST /api/auth/login` { email, password } → { token, user }
- (Protegidos por JWT: añadir header `Authorization: Bearer <token>`)
  - `GET /api/users`
  - `GET /api/clubs`
  - `POST /api/clubs` { name, city?, country?, status? }
  - `GET /api/matches`
  - `POST /api/matches` { club_id, court_id, date(YYYY-MM-DD), time_slot, status? }

## 4) Despliegue en Render (paso a paso)
1. Sube esta carpeta a un repo GitHub, por ejemplo `playmatch-backend`.
2. En Render: **New → Web Service** → conecta el repo.
3. Configura:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment**: Node
4. En **Environment Variables**, crea estas claves con tus valores de CDmon:
   - `PORT` = 10000 (opcional)
   - `DB_HOST` = host de MySQL en CDmon
   - `DB_PORT` = 3306
   - `DB_USER` = usuario
   - `DB_PASSWORD` = contraseña
   - `DB_NAME` = nombre de la base de datos (playmatch)
   - `JWT_SECRET` = una cadena aleatoria larga
5. Haz Deploy. Prueba:
   - `GET https://tu-backend.onrender.com/`
   - `GET https://tu-backend.onrender.com/health/db`

## 5) Conectar el Frontend
- Configura una variable (por ejemplo `VITE_API_URL`) en tu frontend con la URL de este backend.
- En cada petición, si el endpoint está protegido, añade `Authorization: Bearer <token>`.

## 6) Esquema de la BBDD
- El backend asume el esquema de `playmatch_schema_mysql.sql` tal como lo tienes.
- Importa tu SQL en CDmon antes de usar los endpoints.
