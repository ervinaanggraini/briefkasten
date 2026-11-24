-- ============================================================================
-- 01_tables.sql
-- Converted from prisma/schema.prisma for Supabase PostgreSQL
-- ============================================================================

-- 1. User (NextAuth + App Owner)
CREATE TABLE IF NOT EXISTS public."User" (
    "id"            TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "name"          TEXT,
    "email"         TEXT,
    "emailVerified" TIMESTAMPTZ(3),
    "image"         TEXT,
    "createdAt"     TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- 2. Account (NextAuth)
CREATE TABLE IF NOT EXISTS public."Account" (
    "id"                TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "userId"            TEXT NOT NULL,
    "type"              TEXT NOT NULL,
    "provider"          TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token"     TEXT,
    "access_token"      TEXT,
    "expires_at"        INTEGER,
    "expires_in"        INTEGER,
    "ext_expires_in"    INTEGER,
    "token_type"        TEXT,
    "scope"             TEXT,
    "id_token"          TEXT,
    "session_state"     TEXT,
    "createdAt"         TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"         TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Account_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES public."User"("id")
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 3. Session (NextAuth)
CREATE TABLE IF NOT EXISTS public."Session" (
    "id"           TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "sessionToken" TEXT NOT NULL,
    "userId"       TEXT NOT NULL,
    "expires"      TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Session_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES public."User"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. VerificationToken (NextAuth)
CREATE TABLE IF NOT EXISTS public."VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token"      TEXT NOT NULL,
    "expires"    TIMESTAMPTZ(3) NOT NULL
);

-- 5. Category
CREATE TABLE IF NOT EXISTS public."Category" (
    "id"          TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "name"        TEXT NOT NULL,
    "description" TEXT,
    "userId"      TEXT NOT NULL,
    "createdAt"   TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"   TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Category_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES public."User"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6. Tag
CREATE TABLE IF NOT EXISTS public."Tag" (
    "id"        TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "name"      TEXT NOT NULL,
    "emoji"     TEXT,
    "userId"    TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Tag_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Tag_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES public."User"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 7. Bookmark
CREATE TABLE IF NOT EXISTS public."Bookmark" (
    "id"         TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "title"      TEXT,
    "url"        TEXT NOT NULL,
    "image"      TEXT,
    "imageBlur"  TEXT,
    "desc"       TEXT,
    "categoryId" TEXT,
    "userId"     TEXT NOT NULL,
    "createdAt"  TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"  TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Bookmark_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Bookmark_categoryId_fkey"
        FOREIGN KEY ("categoryId") REFERENCES public."Category"("id")
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Bookmark_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES public."User"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 8. TagsOnBookmarks (Many-to-Many Join Table)
CREATE TABLE IF NOT EXISTS public."TagsOnBookmarks" (
    "bookmarkId" TEXT NOT NULL,
    "tagId"      TEXT NOT NULL,

    CONSTRAINT "TagsOnBookmarks_pkey" PRIMARY KEY ("bookmarkId", "tagId"),
    CONSTRAINT "TagsOnBookmarks_bookmarkId_fkey"
        FOREIGN KEY ("bookmarkId") REFERENCES public."Bookmark"("id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "TagsOnBookmarks_tagId_fkey"
        FOREIGN KEY ("tagId") REFERENCES public."Tag"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);
