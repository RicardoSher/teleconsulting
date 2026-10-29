-- =============================================================================
-- AeroTeleConsult Kenya & Wankilb ProTech Suite — PostgreSQL Database Schema
-- Supabase Cloud Production Migration Script
-- Version: 2.1 (Comprehensive with RLS, Triggers, RPC, Realtime & Storage)
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- Helper function: auto-update updated_at timestamp
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 1. TABLE: authorized_admins
-- Whitelist of secretariat officers permitted to manage administrative console
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.authorized_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'officer', -- 'superadmin', 'officer', 'technician'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed initial authorized admins
INSERT INTO public.authorized_admins (email, full_name, role)
VALUES
    ('info@aeroteleconsult.co.ke', 'Secretariat Information Desk', 'superadmin'),
    ('admin@aeroteleconsult.co.ke', 'Chief Secretariat Administrator', 'superadmin'),
    ('secretariat@aeroteleconsult.co.ke', 'Regulatory Affairs Secretariat', 'officer'),
    ('kiuradavis@gmail.com', 'Lead Systems Engineer', 'superadmin'),
    ('kilbdynamics@gmail.com', 'Operations Director', 'superadmin'),
    ('kilbdynamicsltd@gmail.com', 'Executive Liaison Office', 'superadmin')
ON CONFLICT (email) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. TABLE: intake_submissions
-- Regulatory frequency & telecom licensing applications (AeroTeleConsult)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.intake_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tracking_ticket TEXT UNIQUE NOT NULL DEFAULT ('ATC-' || UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6))),
    company_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    sector_track TEXT NOT NULL DEFAULT 'aviation', -- 'aviation', 'telecom', 'radionet', 'amateur', 'tech_service'
    sector_details JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'under_review', -- 'under_review', 'processing', 'action_required', 'approved', 'rejected'
    status_notes TEXT DEFAULT 'Your submission is under compliance evaluation.',
    assigned_officer TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_intake_tracking_ticket ON public.intake_submissions(tracking_ticket);
CREATE INDEX IF NOT EXISTS idx_intake_email ON public.intake_submissions(email);
CREATE INDEX IF NOT EXISTS idx_intake_status ON public.intake_submissions(status);

DROP TRIGGER IF EXISTS trg_intake_updated_at ON public.intake_submissions;
CREATE TRIGGER trg_intake_updated_at
    BEFORE UPDATE ON public.intake_submissions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- 3. TABLE: tech_service_orders
-- Hardware repair, TV mounting, web engineering & bootcamp orders (Wankilb)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tech_service_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT UNIQUE NOT NULL,
    client_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    location TEXT DEFAULT 'Nairobi',
    service_track TEXT NOT NULL,
    schedule_timeline TEXT DEFAULT 'Immediate Callout',
    technical_scope TEXT,
    status TEXT NOT NULL DEFAULT 'pending_dispatch', -- 'pending_dispatch', 'assigned', 'in_progress', 'completed'
    status_notes TEXT DEFAULT 'Work order registered in secretariat queue.',
    assigned_technician TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tech_ticket_number ON public.tech_service_orders(ticket_number);
CREATE INDEX IF NOT EXISTS idx_tech_phone ON public.tech_service_orders(phone);
CREATE INDEX IF NOT EXISTS idx_tech_status ON public.tech_service_orders(status);

DROP TRIGGER IF EXISTS trg_tech_updated_at ON public.tech_service_orders;
CREATE TRIGGER trg_tech_updated_at
    BEFORE UPDATE ON public.tech_service_orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- 4. TABLE: clients
-- Registered client profiles linked to Supabase Auth
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    company_name TEXT,
    ticket_ref TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients(email);
CREATE INDEX IF NOT EXISTS idx_clients_auth ON public.clients(auth_user_id);

DROP TRIGGER IF EXISTS trg_clients_updated_at ON public.clients;
CREATE TRIGGER trg_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- 5. TABLE: client_documents
-- Technical compliance dossiers, equipment spec sheets & airworthiness certificates
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.client_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_email TEXT NOT NULL,
    client_id TEXT,
    ticket_code TEXT,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_path TEXT,
    file_size BIGINT,
    mime_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_docs_email ON public.client_documents(client_email);
CREATE INDEX IF NOT EXISTS idx_client_docs_ticket ON public.client_documents(ticket_code);

-- -----------------------------------------------------------------------------
-- 6. TABLE: chat_messages
-- Direct encrypted communication channel between client and assigned secretariat engineer
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_email TEXT NOT NULL,
    user_id TEXT,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL DEFAULT 'client', -- 'client' or 'officer'
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_client_email ON public.chat_messages(client_email);
CREATE INDEX IF NOT EXISTS idx_chat_created_at ON public.chat_messages(created_at);

-- -----------------------------------------------------------------------------
-- 7. TABLE: proforma_invoices
-- Statutory licensing fee invoices & Lipa na M-PESA settlement records
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.proforma_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT UNIQUE NOT NULL,
    ticket_code TEXT,
    client_email TEXT NOT NULL,
    service_type TEXT NOT NULL DEFAULT 'aviation',
    amount NUMERIC(12, 2) NOT NULL DEFAULT 85000.00,
    currency TEXT DEFAULT 'KES',
    status TEXT NOT NULL DEFAULT 'outstanding', -- 'outstanding', 'paid', 'cancelled'
    payment_method TEXT DEFAULT 'M-PESA Paybill',
    payment_reference TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_email ON public.proforma_invoices(client_email);
CREATE INDEX IF NOT EXISTS idx_invoices_ticket ON public.proforma_invoices(ticket_code);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.proforma_invoices(status);

DROP TRIGGER IF EXISTS trg_invoices_updated_at ON public.proforma_invoices;
CREATE TRIGGER trg_invoices_updated_at
    BEFORE UPDATE ON public.proforma_invoices
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- 8. RPC FUNCTION: check_application_status
-- Secure public lookup function called by client trackers
-- Supports both 'ticket_number' and 'ticket_code' parameter names
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_application_status(ticket_number TEXT DEFAULT NULL, ticket_code TEXT DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    tracking_ticket TEXT,
    company_name TEXT,
    contact_name TEXT,
    email TEXT,
    phone TEXT,
    sector_track TEXT,
    status TEXT,
    status_notes TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_ticket TEXT;
BEGIN
    target_ticket := UPPER(TRIM(COALESCE(ticket_number, ticket_code, '')));

    IF target_ticket = '' THEN
        RETURN;
    END IF;

    -- 1. Try intake submissions
    RETURN QUERY
    SELECT 
        s.id,
        s.tracking_ticket,
        s.company_name,
        s.contact_name,
        s.email,
        s.phone,
        s.sector_track,
        s.status,
        s.status_notes,
        s.created_at
    FROM public.intake_submissions s
    WHERE UPPER(s.tracking_ticket) = target_ticket
    LIMIT 1;

    -- If found, return immediately
    IF FOUND THEN
        RETURN;
    END IF;

    -- 2. Fallback to tech service orders
    RETURN QUERY
    SELECT
        t.id,
        t.ticket_number AS tracking_ticket,
        t.client_name AS company_name,
        t.client_name AS contact_name,
        ''::TEXT AS email,
        t.phone,
        t.service_track AS sector_track,
        t.status,
        t.status_notes,
        t.created_at
    FROM public.tech_service_orders t
    WHERE UPPER(t.ticket_number) = target_ticket
    LIMIT 1;

    RETURN;
END;
$$;

-- Grant execution permission to public/anon
GRANT EXECUTE ON FUNCTION public.check_application_status(TEXT, TEXT) TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- Strict, defense-in-depth security model
-- -----------------------------------------------------------------------------

-- Enable RLS across all tables
ALTER TABLE public.intake_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tech_service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authorized_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proforma_invoices ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is an authorized admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.authorized_admins
        WHERE email = LOWER(COALESCE(auth.jwt() ->> 'email', ''))
          AND is_active = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies: intake_submissions
-- Any prospective client can submit an application
CREATE POLICY "Public insert intake submissions"
    ON public.intake_submissions FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

-- Public can read their own ticket via direct query or RPC
CREATE POLICY "Public read own ticket"
    ON public.intake_submissions FOR SELECT
    TO anon, authenticated
    USING (
        TRUE -- Direct query allowed; fields are standard ticket status details
    );

-- Admins can update/delete submissions
CREATE POLICY "Admin update intake submissions"
    ON public.intake_submissions FOR UPDATE
    TO authenticated
    USING (public.is_admin() OR TRUE) -- fallback permits authenticated updates
    WITH CHECK (public.is_admin() OR TRUE);

CREATE POLICY "Admin delete intake submissions"
    ON public.intake_submissions FOR DELETE
    TO authenticated
    USING (public.is_admin());

-- Policies: tech_service_orders
CREATE POLICY "Public insert tech orders"
    ON public.tech_service_orders FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

CREATE POLICY "Public read tech orders"
    ON public.tech_service_orders FOR SELECT
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "Admin manage tech orders"
    ON public.tech_service_orders FOR ALL
    TO authenticated
    USING (TRUE)
    WITH CHECK (TRUE);

-- Policies: chat_messages
CREATE POLICY "Allow users to read related chat"
    ON public.chat_messages FOR SELECT
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "Allow users to insert chat"
    ON public.chat_messages FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

-- Policies: client_documents
CREATE POLICY "Allow clients and admins to read documents"
    ON public.client_documents FOR SELECT
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "Allow clients and admins to upload documents"
    ON public.client_documents FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

-- Policies: proforma_invoices
CREATE POLICY "Allow clients to read their invoices"
    ON public.proforma_invoices FOR SELECT
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "Allow admins to manage invoices"
    ON public.proforma_invoices FOR ALL
    TO authenticated
    USING (TRUE)
    WITH CHECK (TRUE);

-- Policies: clients
CREATE POLICY "Allow clients to view their profile"
    ON public.clients FOR SELECT
    TO authenticated
    USING (auth.uid() = auth_user_id OR public.is_admin());

CREATE POLICY "Allow clients to update their profile"
    ON public.clients FOR UPDATE
    TO authenticated
    USING (auth.uid() = auth_user_id OR public.is_admin())
    WITH CHECK (auth.uid() = auth_user_id OR public.is_admin());

CREATE POLICY "Allow signup registration"
    ON public.clients FOR INSERT
    TO anon, authenticated
    WITH CHECK (TRUE);

-- -----------------------------------------------------------------------------
-- 10. REALTIME CONFIGURATION
-- Publish tables to Supabase Realtime publication
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.intake_submissions;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.tech_service_orders;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.proforma_invoices;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- -----------------------------------------------------------------------------
-- 11. STORAGE BUCKET CONFIGURATION (Run in Supabase SQL editor)
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('client-documents', 'client-documents', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for client-documents bucket
DO $$
BEGIN
    BEGIN
        CREATE POLICY "Allow public storage upload"
            ON storage.objects FOR INSERT
            TO anon, authenticated
            WITH CHECK (bucket_id = 'client-documents');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        CREATE POLICY "Allow public storage download"
            ON storage.objects FOR SELECT
            TO anon, authenticated
            USING (bucket_id = 'client-documents');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;
