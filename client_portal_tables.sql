-- ============================================================
-- AeroTeleConsult Client Portal — Database Setup
-- Run this in Supabase SQL Editor to enable the client portal.
-- ============================================================

-- ── 1. clients (profile per user+ticket) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.clients (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ticket_code     TEXT NOT NULL,
    full_name       TEXT,
    company         TEXT,
    phone           TEXT,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, ticket_code)
);

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- Clients can read/write their own profile rows
CREATE POLICY "clients_own_read"   ON public.clients FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "clients_own_insert" ON public.clients FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "clients_own_update" ON public.clients FOR UPDATE USING (auth.uid() = user_id);

-- Admins can see all client profiles (select by service_role or from admin panel)
CREATE POLICY "clients_admin_read" ON public.clients FOR SELECT USING (true);


-- ── 2. chat_messages ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_code TEXT NOT NULL,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('client', 'officer')),
    sender_name TEXT,
    message     TEXT NOT NULL,
    user_id     UUID REFERENCES auth.users(id),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_ticket ON public.chat_messages (ticket_code, created_at);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read messages for the ticket they hold
CREATE POLICY "chat_authenticated_read"   ON public.chat_messages FOR SELECT USING (auth.role() = 'authenticated');
-- Clients can insert their own messages
CREATE POLICY "chat_client_insert"        ON public.chat_messages FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Enable Realtime on this table (run once)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;


-- ── 3. client_documents ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.client_documents (
    id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_code  TEXT NOT NULL,
    uploaded_by  UUID REFERENCES auth.users(id),
    filename     TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size    BIGINT,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_docs_ticket ON public.client_documents (ticket_code, created_at);

ALTER TABLE public.client_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "docs_authenticated_read"  ON public.client_documents FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "docs_authenticated_insert" ON public.client_documents FOR INSERT WITH CHECK (auth.role() = 'authenticated');


-- ── 4. proforma_invoices ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.proforma_invoices (
    id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_code   TEXT UNIQUE NOT NULL,
    confirmed     BOOLEAN DEFAULT FALSE,
    confirmed_at  TIMESTAMPTZ,
    confirmed_by  UUID REFERENCES auth.users(id),
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.proforma_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoices_authenticated_read"  ON public.proforma_invoices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "invoices_authenticated_upsert" ON public.proforma_invoices FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "invoices_authenticated_update" ON public.proforma_invoices FOR UPDATE USING (auth.role() = 'authenticated');


-- ── 5. Storage bucket: client-documents ──────────────────────────────────────
-- Run in the Supabase Dashboard → Storage → New Bucket:
--   Name: client-documents | Public: false
-- Or via SQL (Supabase storage schema):
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'client-documents',
    'client-documents',
    false,
    52428800, -- 50MB max per file
    ARRAY['application/pdf','image/jpeg','image/png','application/vnd.openxmlformats-officedocument.wordprocessingml.document']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "storage_auth_upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'client-documents' AND auth.role() = 'authenticated');

CREATE POLICY "storage_auth_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'client-documents' AND auth.role() = 'authenticated');

CREATE POLICY "storage_auth_delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'client-documents' AND auth.role() = 'authenticated');


-- ── 6. Ensure intake_submissions has tracking_ticket & status columns ─────────
-- (Already in database_setup.sql but included here for completeness)
ALTER TABLE public.intake_submissions
ADD COLUMN IF NOT EXISTS tracking_ticket TEXT UNIQUE
    DEFAULT ('ATC-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8))),
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'under_review'
    CHECK (status IN ('under_review', 'processing', 'board_review', 'approved', 'rejected', 'action_required')),
ADD COLUMN IF NOT EXISTS status_notes TEXT
    DEFAULT 'Your submission has been received and routed to our engineering secretariat for compliance evaluation.',
ADD COLUMN IF NOT EXISTS assigned_officer TEXT;

-- NOTE: The status CHECK constraint must include 'board_review' for stepper to work.
-- If you get a constraint violation, run:
-- ALTER TABLE public.intake_submissions DROP CONSTRAINT IF EXISTS intake_submissions_status_check;
-- Then re-add the column with the corrected CHECK above.

-- ── 7. Permissions on intake_submissions ──────────────────────────────────────
ALTER TABLE public.intake_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "intake_submissions_select"
ON public.intake_submissions FOR SELECT
USING (true);

CREATE POLICY "intake_submissions_insert"
ON public.intake_submissions FOR INSERT
WITH CHECK (true);

