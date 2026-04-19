const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

exports.handler = async function (event, context) {
    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            body: JSON.stringify({ error: 'Method Not Allowed' })
        };
    }

    try {
        const { name, email, matric_no, course, department } = JSON.parse(event.body || '{}');

        if (!name || !email || !matric_no || !course) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Missing required fields: name, email, matric_no, course' })
            };
        }

        const studentData = {
            first_name: name.split(' ')[0],
            last_name: name.split(' ').slice(1).join(' '),
            school_email: email.toLowerCase(),
            matric_number: matric_no.toUpperCase(),
            department: department || course,
            status: 'pending'
        };

        const { data, error } = await supabase
            .from('students')
            .insert(studentData)
            .select()
            .single();

        if (error) {
            if (error.code === '23505') { // Unique constraint violation
                return {
                    statusCode: 409,
                    body: JSON.stringify({ error: 'Student with this email or matric number already exists' })
                };
            }
            throw error;
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ success: true, message: 'Student registered successfully', data })
        };

    } catch (error) {
        console.error('Error registering student:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message || 'Internal server error' })
        };
    }
};
