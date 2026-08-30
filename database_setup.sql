-- 1. Add status and tracking ticket columns
ALTER TABLE public.intake_submissions 
ADD COLUMN IF NOT EXISTS tracking_ticket TEXT UNIQUE DEFAULT ('ATC-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8))),
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'under_review' CHECK (status IN ('under_review', 'processing', 'approved', 'rejected', 'action_required')),
ADD COLUMN IF NOT EXISTS status_notes TEXT DEFAULT 'Your submission has been received and routed to our engineering secretariat for compliance evaluation.';

-- Index for instant ticket lookups
CREATE INDEX IF NOT EXISTS idx_intake_submissions_tracking_ticket 
    ON public.intake_submissions (tracking_ticket);

-- 2. Secure RPC function for public status checks
-- Prevents dumping sensitive table rows while returning application status safely
CREATE OR REPLACE FUNCTION public.check_application_status(ticket_number TEXT)
RETURNS TABLE (
    company_name TEXT,
    sector_track TEXT,
    status TEXT,
    status_notes TEXT,
    created_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.company_name,
        s.sector_track,
        s.status,
        s.status_notes,
        s.created_at
    FROM public.intake_submissions s
    WHERE s.tracking_ticket = UPPER(TRIM(ticket_number));
END;
$$;

-- Grant execution permission to anonymous site visitors
GRANT EXECUTE ON FUNCTION public.check_application_status(TEXT) TO anon, authenticated;