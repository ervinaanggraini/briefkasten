-- ============================================================================
-- 04_rls_policies.sql
-- Row Level Security (RLS) setup for Supabase
-- ============================================================================
-- NOTE:
-- 1. If you still connect via Prisma (DATABASE_URL using postgres / service_role),
--    Prisma automatically bypasses RLS. Enabling RLS below protects your tables
--    from unauthorized public access via Supabase's auto-generated REST API (anon key).
-- 2. If you migrate from NextAuth to Supabase Auth and query directly using
--    supabase-js from the browser, uncomment the policies below so authenticated
--    users can access their own rows via auth.uid()::text.

ALTER TABLE public."User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Account" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Session" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."VerificationToken" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Category" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Tag" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Bookmark" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."TagsOnBookmarks" ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Optional Policies (Uncomment ONLY if using Supabase Auth + supabase-js client)
-- ============================================================================

-- -- User can read/update their own profile
-- CREATE POLICY "Users can view own profile" ON public."User"
--     FOR SELECT USING (auth.uid()::text = "id");
-- CREATE POLICY "Users can update own profile" ON public."User"
--     FOR UPDATE USING (auth.uid()::text = "id");

-- -- Category: full access to own categories
-- CREATE POLICY "Users manage own categories" ON public."Category"
--     FOR ALL USING (auth.uid()::text = "userId")
--     WITH CHECK (auth.uid()::text = "userId");

-- -- Tag: full access to own tags
-- CREATE POLICY "Users manage own tags" ON public."Tag"
--     FOR ALL USING (auth.uid()::text = "userId")
--     WITH CHECK (auth.uid()::text = "userId");

-- -- Bookmark: full access to own bookmarks
-- CREATE POLICY "Users manage own bookmarks" ON public."Bookmark"
--     FOR ALL USING (auth.uid()::text = "userId")
--     WITH CHECK (auth.uid()::text = "userId");

-- -- TagsOnBookmarks: access if user owns the bookmark
-- CREATE POLICY "Users manage own bookmark tags" ON public."TagsOnBookmarks"
--     FOR ALL USING (
--         EXISTS (
--             SELECT 1 FROM public."Bookmark" b
--             WHERE b."id" = "bookmarkId" AND b."userId" = auth.uid()::text
--         )
--     );
