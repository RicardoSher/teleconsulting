/**
 * Centralized Configuration for AeroTeleConsult & Wankilb ProTech Suite
 * Update environment variables and shared settings here.
 */
window.APP_CONFIG = {
    // Supabase Database & Auth Configuration
    SUPABASE_URL: window.ENV_SUPABASE_URL || localStorage.getItem('SP_URL') || "https://tfetuykairghymxmknxc.supabase.co",
    SUPABASE_ANON_KEY: window.ENV_SUPABASE_ANON_KEY || localStorage.getItem('SP_KEY') || "sb_publishable_9ITJB3dba8vSDsZzcF3psw_YPIdstSx",
    
    // Database Table Names
    TABLE_SUBMISSIONS: localStorage.getItem('SP_TABLE') || "intake_submissions",
    TABLE_WORK_ORDERS: "tech_service_orders",
    TABLE_ADMINS: "authorized_admins",

    // Organization Contact Metadata
    COMPANY_NAME: "AeroTeleConsult Kenya",
    TECH_BRAND_NAME: "Wankilb ProTech & Skills",
    SUPPORT_PHONE: "+254 726 661 849",
    SUPPORT_PHONE_RAW: "254726661849",
    SUPPORT_EMAIL: "info@aeroteleconsult.co.ke",
    PORTFOLIO_URL: "https://engineer-david-portfolio.kiuradavis.workers.dev/",

    // Authorized Secretariat Admins Whitelist
    AUTHORIZED_ADMINS: [
        "info@aeroteleconsult.co.ke",
        "admin@aeroteleconsult.co.ke",
        "secretariat@aeroteleconsult.co.ke",
        "kiuradavis@gmail.com"
    ]
};

// Global Supabase Client Initializer Helper
window.getSupabaseClient = function() {
    if (window.supabase && typeof window.supabase.createClient === 'function') {
        try {
            return window.supabase.createClient(window.APP_CONFIG.SUPABASE_URL, window.APP_CONFIG.SUPABASE_ANON_KEY);
        } catch (e) {
            console.warn("Supabase Client Init Warning:", e);
            return null;
        }
    }
    return null;
};
