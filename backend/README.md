
# Ruty Backend (Express + PostgreSQL)

## Kurulum
```bash
npm install
cp .env.example .env
# .env içini doldur (DATABASE_URL, JWT_SECRET)
psql "$DATABASE_URL" -f sql/schema.sql
npm run dev
```

## Uçlar
- GET /health
- POST /auth/register {email,password,display_name}
- POST /auth/login
- GET /habits  (Bearer <JWT>)
- POST /habits
- PATCH /habits/:id
- POST /habits/:id/check
- GET /sync/down?since=ISO
- POST /sync/up
```

## Docker
```bash
docker build -t ruty-api .
docker run -p 8080:8080 --env-file .env ruty-api
```
