// assets/js/supabase-client.js
// This script initializes the global supabase client using the global window.SUPABASE_URL and window.SUPABASE_ANON_KEY.

(function() {
    const SUPABASE_URL = window.SUPABASE_URL || "https://YOUR_PROJECT_REF.supabase.co";
    const SUPABASE_ANON_KEY = window.SUPABASE_ANON_KEY || "YOUR_ANON_KEY";

    if (typeof window.supabase === 'undefined') {
        console.error('Supabase library not loaded. Please include the Supabase CDN script before this one.');
        return;
    }

    // Initialize the global supabase client
    // We use window.supabaseClient to avoid naming conflict with the window.supabase object from the CDN
    window.supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    
    console.log('✅ Supabase client initialized.');
})();
