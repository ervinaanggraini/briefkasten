-- ============================================================================
-- 03_triggers.sql
-- Auto-update "updatedAt" triggers for tables with @updatedAt in Prisma
-- ============================================================================

DROP TRIGGER IF EXISTS set_updated_at_account ON public."Account";
CREATE TRIGGER set_updated_at_account
    BEFORE UPDATE ON public."Account"
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_category ON public."Category";
CREATE TRIGGER set_updated_at_category
    BEFORE UPDATE ON public."Category"
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_tag ON public."Tag";
CREATE TRIGGER set_updated_at_tag
    BEFORE UPDATE ON public."Tag"
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_bookmark ON public."Bookmark";
CREATE TRIGGER set_updated_at_bookmark
    BEFORE UPDATE ON public."Bookmark"
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
