const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

exports.handler = async function (event, context) {
    // Only allow POST
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { email, password, first_name, last_name, matric_number, department } = JSON.parse(event.body);

    if (!email || !password || !first_name || !last_name || !matric_number || !department) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Missing required fields' })
        };
    }

    let authUser = null;

    try {
        // 1. Create Auth User
        const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
            email: email,
            password: password,
            email_confirm: true, // Auto-confirm for organizational use, or set to false if you want email verification
            user_metadata: { first_name, last_name, matric_number, department }
        });

        if (authError) {
            throw authError;
        }

        authUser = authData.user;

        // 2. Insert into students table
        const { error: dbError } = await supabaseAdmin
            .from('students')
            .insert([{
                user_id: authUser.id,
                school_email: email,
                first_name: first_name,
                last_name: last_name,
                matric_number: matric_number,
                department: department,
                status: 'pending'
            }]);

        if (dbError) {
            // 3. Rollback: Delete Auth User if DB insert fails
            console.error('Database insert failed, rolling back auth user:', dbError);
            await supabaseAdmin.auth.admin.deleteUser(authUser.id);
            throw dbError;
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Signup successful, pending approval', user: authUser })
        };

    } catch (error) {
        console.error('Signup error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message || 'Internal Server Error' })
        };
    }
};
