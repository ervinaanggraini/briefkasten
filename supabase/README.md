# Migrasi Database Prisma ke Supabase

Folder ini berisi file SQL hasil konversi dari `prisma/schema.prisma` agar siap dijalankan di **Supabase (PostgreSQL)**.

## Struktur Folder

```text
supabase/
├── README.md
└── sql/
    ├── 00_extensions_and_functions.sql   # Extension pgcrypto & fungsi trigger updatedAt
    ├── 01_tables.sql                     # Definisi 8 tabel + Foreign Key constraints
    ├── 02_indexes.sql                    # Unique constraints, indexes, & Full-Text Search GIN index
    ├── 03_triggers.sql                   # Trigger otomatis untuk kolom updatedAt
    ├── 04_rls_policies.sql               # Aktivasi Row Level Security (RLS) & template policy
    └── full_schema.sql                   # Gabungan semua file di atas (siap copy-paste)
```

## Cara Menjalankan di Supabase

### Opsi 1: Sekali Jalan (Paling Mudah)
1. Buka **Supabase Dashboard** → **SQL Editor**.
2. Copy seluruh isi file `sql/full_schema.sql`.
3. Paste ke SQL Editor dan klik **Run**.

### Opsi 2: Bertahap (Modular)
Jalankan file di folder `sql/` secara berurutan:
1. `00_extensions_and_functions.sql`
2. `01_tables.sql`
3. `02_indexes.sql`
4. `03_triggers.sql`
5. `04_rls_policies.sql`

## Penyesuaian dari Prisma ke Supabase

- **Semua field terbaru dari `prisma/schema.prisma` sudah disertakan** (termasuk `Bookmark.imageBlur`, `Account.expires_in`, `Account.ext_expires_in`, serta `updatedAt` di `Bookmark`, `Tag`, `Category`, dan `Account` yang belum ada di file migrasi lama tahun 2022).
- **Foreign Key Native PostgreSQL**: Karena `schema.prisma` sebelumnya memakai `relationMode = "prisma"`, migrasi lama tidak memiliki `FOREIGN KEY`. Di versi Supabase ini, relasi `ON DELETE CASCADE` / `ON DELETE SET NULL` / `ON UPDATE CASCADE` sudah ditambahkan langsung di level database.
- **Auto-generate ID & `updatedAt`**: Kolom `id` tetap menerima CUID dari Prisma, dan memiliki fallback `DEFAULT gen_random_uuid()::text` jika Anda melakukan insert langsung dari Supabase. Kolom `updatedAt` juga otomatis diperbarui oleh trigger PostgreSQL.
- **Row Level Security (RLS)**: RLS diaktifkan di semua tabel untuk mencegah akses publik lewat REST API Supabase (`anon` key). Koneksi Prisma (`DATABASE_URL` dengan user `postgres`) tetap berjalan normal karena otomatis melewati RLS.
