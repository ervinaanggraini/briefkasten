-- ============================================================================
-- full_schema.sql
-- Combined all-in-one script for Supabase SQL Editor
-- Converted from prisma/schema.prisma
-- ============================================================================

-- 1. Extensions & Helper Functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Tables
CREATE TABLE IF NOT EXISTS public."User" (
    "id"            TEXT NOT NULL DEFAULT gen_random_uuid()::text,
    "name"          TEXT,
    "email"         TEXT,
    "emailVerified" TIMESTAMPTZ(3),
    "image"         TEXT,
    "createdAt"     TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

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

CREATE TABLE IF NOT EXISTS public."VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token"      TEXT NOT NULL,
    "expires"    TIMESTAMPTZ(3) NOT NULL
);

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

-- 3. Indexes & Unique Constraints
CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key" ON public."User"("email");

CREATE INDEX IF NOT EXISTS "Account_userId_idx" ON public."Account"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Account_provider_providerAccountId_key" ON public."Account"("provider", "providerAccountId");

CREATE UNIQUE INDEX IF NOT EXISTS "Session_sessionToken_key" ON public."Session"("sessionToken");
CREATE INDEX IF NOT EXISTS "Session_userId_idx" ON public."Session"("userId");

CREATE UNIQUE INDEX IF NOT EXISTS "VerificationToken_token_key" ON public."VerificationToken"("token");
CREATE UNIQUE INDEX IF NOT EXISTS "VerificationToken_identifier_token_key" ON public."VerificationToken"("identifier", "token");

CREATE INDEX IF NOT EXISTS "Category_userId_idx" ON public."Category"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Category_name_userId_key" ON public."Category"("name", "userId");

CREATE INDEX IF NOT EXISTS "Tag_userId_idx" ON public."Tag"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Tag_name_userId_key" ON public."Tag"("name", "userId");

CREATE INDEX IF NOT EXISTS "Bookmark_categoryId_idx" ON public."Bookmark"("categoryId");
CREATE INDEX IF NOT EXISTS "Bookmark_userId_idx" ON public."Bookmark"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Bookmark_url_userId_key" ON public."Bookmark"("url", "userId");
CREATE INDEX IF NOT EXISTS "Bookmark_fts_idx"
    ON public."Bookmark"
    USING GIN (to_tsvector('simple', COALESCE("title", '') || ' ' || COALESCE("desc", '') || ' ' || COALESCE("url", '')));

CREATE INDEX IF NOT EXISTS "TagsOnBookmarks_bookmarkId_idx" ON public."TagsOnBookmarks"("bookmarkId");
CREATE INDEX IF NOT EXISTS "TagsOnBookmarks_tagId_idx" ON public."TagsOnBookmarks"("tagId");

-- 4. Triggers for updatedAt
DROP TRIGGER IF EXISTS set_updated_at_account ON public."Account";
CREATE TRIGGER set_updated_at_account
    BEFORE UPDATE ON public."Account"
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_category ON public."Category";
CREATE TRIGGER set_updated_at_category
    BEFORE UPDATE ON public."Category"
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_tag ON public."Tag";
CREATE TRIGGER set_updated_at_tag
    BEFORE UPDATE ON public."Tag"
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_bookmark ON public."Bookmark";
CREATE TRIGGER set_updated_at_bookmark
    BEFORE UPDATE ON public."Bookmark"
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Row Level Security (RLS)
ALTER TABLE public."User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Account" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Session" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."VerificationToken" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Category" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Tag" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Bookmark" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."TagsOnBookmarks" ENABLE ROW LEVEL SECURITY;
