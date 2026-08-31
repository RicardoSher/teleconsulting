-- 1. Create the authorized admins table
CREATE TABLE IF NOT EXISTS authorized_admins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT DEFAULT 'Compliance Officer',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE authorized_admins ENABLE ROW LEVEL SECURITY;

-- 3. Allow verification reads
CREATE POLICY "Allow public read for admin whitelist verification"
ON authorized_admins FOR SELECT
USING (is_active = true);

-- 4. Insert your initial authorized officers
INSERT INTO authorized_admins (email, full_name, role) VALUES
('info@aeroteleconsult.co.ke', 'Lead Secretariat Desk', 'Lead Officer'),
('admin@aeroteleconsult.co.ke', 'System Administrator', 'Super Admin'),
('kiuradavis@gmail.com', 'Technical Consultant', 'Lead Engineer')
ON CONFLICT (email) DO NOTHING;