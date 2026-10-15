/**
 * Centralized Configuration for AeroTeleConsult & Wankilb ProTech Suite
 * Update environment variables and shared settings here.
 * v2.0 — Enhanced with client portal, notifications, chat & invoicing.
 */
window.APP_CONFIG = {
    // ── Supabase Database & Auth Configuration ──────────────────────────────
    SUPABASE_URL: window.ENV_SUPABASE_URL || localStorage.getItem('SP_URL') || "https://tfetuykairghymxmknxc.supabase.co",
    SUPABASE_ANON_KEY: window.ENV_SUPABASE_ANON_KEY || localStorage.getItem('SP_KEY') || "sb_publishable_9ITJB3dba8vSDsZzcF3psw_YPIdstSx",

    // ── Core Table Names ────────────────────────────────────────────────────
    TABLE_SUBMISSIONS:  localStorage.getItem('SP_TABLE') || "intake_submissions",
    TABLE_WORK_ORDERS:  "tech_service_orders",
    TABLE_ADMINS:       "authorized_admins",

    // ── Client Portal Tables ────────────────────────────────────────────────
    TABLE_CLIENTS:      "clients",
    TABLE_CHAT:         "chat_messages",
    TABLE_DOCUMENTS:    "client_documents",
    TABLE_INVOICES:     "proforma_invoices",

    // ── Supabase Storage ────────────────────────────────────────────────────
    STORAGE_BUCKET:     "client-documents",

    // ── Notification Configuration ──────────────────────────────────────────
    NOTIFICATION_EMAIL: "kilbdynamicsltd@gmail.com",
    EDGE_FN_NOTIFY:     "notify-new-ticket",

    // ── Organization Contact Metadata ───────────────────────────────────────
    COMPANY_NAME:       "AeroTeleConsult Kenya",
    TECH_BRAND_NAME:    "Wankilb ProTech & Skills",
    SUPPORT_PHONE:      "+254 723 489 194",
    SUPPORT_PHONE_RAW:  "254723489194",
    SUPPORT_EMAIL:      "kilbdynamicsltd@gmail.com",
    PORTFOLIO_URL:      "https://engineer-david-portfolio.kiuradavis.workers.dev/",

    // ── Service Pricing (KES) for Proforma Invoices ─────────────────────────
    PRICING: {
        aviation:  { label: "Aeronautical Frequency & Station Licensing",   price: 85000  },
        telecom:   { label: "Telecom Operator Licensing (NFP/ASP)",          price: 150000 },
        radionet:  { label: "Private Radio Network (PMR) Licensing",         price: 45000  },
        amateur:   { label: "Amateur Radio Operator Permit",                 price: 25000  },
    },

    // ── Authorized Secretariat Admins Whitelist ─────────────────────────────
    AUTHORIZED_ADMINS: [
        "info@aeroteleconsult.co.ke",
        "admin@aeroteleconsult.co.ke",
        "secretariat@aeroteleconsult.co.ke",
        "kiuradavis@gmail.com",
        "kilbdynamics@gmail.com",
        "kilbdynamicsltd@gmail.com"
    ]
};

// ── Global Supabase Client Initializer Helper ───────────────────────────────
window.getSupabaseClient = function() {
    if (window.supabase && typeof window.supabase.createClient === 'function') {
        try {
            return window.supabase.createClient(
                window.APP_CONFIG.SUPABASE_URL,
                window.APP_CONFIG.SUPABASE_ANON_KEY,
                { auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true } }
            );
        } catch (e) {
            console.warn("Supabase Client Init Warning:", e);
            return null;
        }
    }
    return null;
};

// ── Singleton client (avoids re-initializing on every page) ────────────────
window._supabaseInstance = null;
window.getDb = function() {
    if (!window._supabaseInstance) {
        window._supabaseInstance = window.getSupabaseClient();
    }
    return window._supabaseInstance;
};
