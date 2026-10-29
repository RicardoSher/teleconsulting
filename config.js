/**
 * Centralized Configuration for AeroTeleConsult & Wankilb ProTech Suite
 * Update environment variables and shared settings here.
 * v2.1 — Enhanced with database resilience, phone/ticket sanitizers & offline detection.
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

    // ── Official Payment & Settlement Credentials ──────────────────────────
    PAYMENT: {
        METHOD:               "Lipa na M-PESA (Buy Goods / Paybill)",
        TILL_NUMBER:          "4676122",
        PAYBILL_NUMBER:       "247247",
        ACCOUNT_NUMBER:       "194489",
        BUY_GOODS_NAME:       "Wankilb ProTech / AeroTeleConsult",
        INSTRUCTIONS_TILL:    "Lipa na M-PESA > Buy Goods and Services > Till Number: 4676122",
        INSTRUCTIONS_PAYBILL: "Lipa na M-PESA > Pay Bill > Business No: 247247 > Account No: 194489 (or your Ticket Reference ATC-XXXXXX)",
        INSTRUCTIONS:         "Lipa na M-PESA > Buy Goods Till: 4676122 (or Paybill 247247, Account: 194489)"
    },

    // ── Authorized Secretariat Admins Whitelist ─────────────────────────────
    AUTHORIZED_ADMINS: [
        "info@aeroteleconsult.co.ke",
        "admin@aeroteleconsult.co.ke",
        "secretariat@aeroteleconsult.co.ke",
        "kiuradavis@gmail.com",
        "kilbdynamics@gmail.com",
        "kilbdynamicsltd@gmail.com"
    ],

    // ── Utility Helpers ─────────────────────────────────────────────────────
    /**
     * Sanitizes and normalizes a Kenyan phone number into standard international format (+254 7XX XXX XXX)
     */
    normalizePhone: function(phone) {
        if (!phone) return '';
        const cleaned = phone.replace(/[^\d+]/g, '');
        if (cleaned.startsWith('0')) {
            return '+254 ' + cleaned.substring(1).replace(/(\d{3})(\d{3})(\d{3})/, '$1 $2 $3').trim();
        } else if (cleaned.startsWith('254')) {
            return '+254 ' + cleaned.substring(3).replace(/(\d{3})(\d{3})(\d{3})/, '$1 $2 $3').trim();
        } else if (cleaned.startsWith('+254')) {
            return '+254 ' + cleaned.substring(4).replace(/(\d{3})(\d{3})(\d{3})/, '$1 $2 $3').trim();
        }
        return phone;
    },

    /**
     * Generates a client-safe tracking ticket code if DB default is unavailable
     */
    generateTicketCode: function(prefix) {
        prefix = prefix || 'ATC';
        return prefix + '-' + Math.random().toString(36).substring(2, 8).toUpperCase();
    },

    /**
     * Formats currency in KES
     */
    formatCurrency: function(amount) {
        return 'KES ' + Number(amount || 0).toLocaleString('en-KE');
    }
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

// ── Network Connectivity Monitor ───────────────────────────────────────────
(function setupNetworkMonitor() {
    window.addEventListener('offline', function() {
        console.warn("[Network] Connection lost. Caching local activities.");
        if (typeof showToast === 'function') {
            showToast({
                title: 'Offline Mode',
                message: 'You are currently offline. Check your internet connection.',
                type: 'error',
                duration: 5000
            });
        }
    });

    window.addEventListener('online', function() {
        console.log("[Network] Connection restored.");
        if (typeof showToast === 'function') {
            showToast({
                title: 'Online',
                message: 'Internet connection re-established.',
                type: 'success',
                duration: 3500
            });
        }
    });
})();
