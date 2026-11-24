-- ============================================================================
-- 02_indexes.sql
-- Unique constraints & indexes matching prisma/schema.prisma
-- ============================================================================

-- User
CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key"
    ON public."User"("email");

-- Account
CREATE INDEX IF NOT EXISTS "Account_userId_idx"
    ON public."Account"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Account_provider_providerAccountId_key"
    ON public."Account"("provider", "providerAccountId");

-- Session
CREATE UNIQUE INDEX IF NOT EXISTS "Session_sessionToken_key"
    ON public."Session"("sessionToken");
CREATE INDEX IF NOT EXISTS "Session_userId_idx"
    ON public."Session"("userId");

-- VerificationToken
CREATE UNIQUE INDEX IF NOT EXISTS "VerificationToken_token_key"
    ON public."VerificationToken"("token");
CREATE UNIQUE INDEX IF NOT EXISTS "VerificationToken_identifier_token_key"
    ON public."VerificationToken"("identifier", "token");

-- Category
CREATE INDEX IF NOT EXISTS "Category_userId_idx"
    ON public."Category"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Category_name_userId_key"
    ON public."Category"("name", "userId");

-- Tag
CREATE INDEX IF NOT EXISTS "Tag_userId_idx"
    ON public."Tag"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Tag_name_userId_key"
    ON public."Tag"("name", "userId");

-- Bookmark
CREATE INDEX IF NOT EXISTS "Bookmark_categoryId_idx"
    ON public."Bookmark"("categoryId");
CREATE INDEX IF NOT EXISTS "Bookmark_userId_idx"
    ON public."Bookmark"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Bookmark_url_userId_key"
    ON public."Bookmark"("url", "userId");

-- Optional: GIN index for faster Full-Text Search on Bookmark
CREATE INDEX IF NOT EXISTS "Bookmark_fts_idx"
    ON public."Bookmark"
    USING GIN (to_tsvector('simple', COALESCE("title", '') || ' ' || COALESCE("desc", '') || ' ' || COALESCE("url", '')));

-- TagsOnBookmarks
CREATE INDEX IF NOT EXISTS "TagsOnBookmarks_bookmarkId_idx"
    ON public."TagsOnBookmarks"("bookmarkId");
CREATE INDEX IF NOT EXISTS "TagsOnBookmarks_tagId_idx"
    ON public."TagsOnBookmarks"("tagId");
