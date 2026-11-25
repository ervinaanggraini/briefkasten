import fs from "node:fs"
import path from "node:path"
import { defineConfig } from "prisma/config"

if (fs.existsSync(".env")) {
  process.loadEnvFile(".env")
}

export default defineConfig({
  schema: path.join("prisma", "schema.prisma"),
  migrations: {
    path: path.join("prisma", "migrations"),
  },
  datasource: {
    // process.env (not prisma's env()) so `prisma generate` works without
    // DATABASE_URL set, e.g. during docker build. migrate/db commands still
    // need it set at runtime. Prefer DIRECT_URL for migrations (Supabase
    // session pooler) and fall back to DATABASE_URL.
    url: process.env.DIRECT_URL ?? process.env.DATABASE_URL ?? "",
  },
})
