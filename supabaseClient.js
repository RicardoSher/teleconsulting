// supabaseClient.js

const SUPABASE_URL = 'https://tfetuykairghymxmknxc.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_9ITJB3dba8vSDsZzcF3psw_YPIdstSx';

let supabase = null;

if (window.supabase && typeof window.supabase.createClient === 'function') {
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
} else {
    console.error('Supabase CDN SDK failed to load prior to initializing supabaseClient.js.');
}

// Attach client to global window object
window.supabaseClient = supabase;