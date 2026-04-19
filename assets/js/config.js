// assets/js/config.js
// ============================================
// NACOS Website - Global Configuration
// ============================================

// DO NOT put sensitive keys here if this file is public.
// For static sites, the Anon Key is safe to expose as long as RLS is properly configured.
// Replace these values with your actual Supabase credentials.

window.SUPABASE_URL = "https://your-project-id.supabase.co";
window.SUPABASE_ANON_KEY = "your-anon-key-here";

// Optional: Analytics or other global settings
window.APP_CONFIG = {
    env: 'production',
    version: '1.0.0',
    analytics_enabled: false
};
