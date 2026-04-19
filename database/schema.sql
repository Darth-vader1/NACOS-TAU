-- =====================================================
-- NACOS Platform Database Schema
-- Production Ready Signup & Approval System
-- =====================================================

-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Table: students
-- Stores student profile information
-- =====================================================
CREATE TABLE IF NOT EXISTS students (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    school_email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    matric_number VARCHAR(50) UNIQUE NOT NULL,
    department VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    profile_picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Table: admin_users
-- Stores admin user information
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Table: resource_categories
-- Categories for organizing resources
-- =====================================================
CREATE TABLE IF NOT EXISTS resource_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Table: past_questions
-- Stores past examination questions
-- =====================================================
CREATE TABLE IF NOT EXISTS past_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    course_code VARCHAR(50) NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    level VARCHAR(50) NOT NULL,
    semester VARCHAR(50) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(20) NOT NULL,
    uploaded_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Table: academic_resources
-- Stores links and references to academic resources
-- =====================================================
CREATE TABLE IF NOT EXISTS academic_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    category VARCHAR(100),
    uploaded_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE past_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_resources ENABLE ROW LEVEL SECURITY;

-- Students table policies
CREATE POLICY "Public students can be seen by admins" ON students
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    );

CREATE POLICY "Students can update own profile" ON students
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Students can insert own profile" ON students
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin users table policies
CREATE POLICY "Admins can view all admin users" ON admin_users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    );

-- Resource categories policies
CREATE POLICY "Anyone can view resource categories" ON resource_categories
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage resource categories" ON resource_categories
    FOR ALL USING (
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    );

-- Past questions policies
CREATE POLICY "Anyone can view past questions" ON past_questions
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage past questions" ON past_questions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    );

-- Academic resources policies
CREATE POLICY "Anyone can view academic resources" ON academic_resources
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage academic resources" ON academic_resources
    FOR ALL USING (
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    );

-- =====================================================
-- Functions & Triggers
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Initial Data: Resource Categories
-- =====================================================
INSERT INTO resource_categories (name, description) VALUES
    ('Programming', 'Programming languages and development resources'),
    ('Database', 'Database design and management resources'),
    ('Networking', 'Computer networking and security resources'),
    ('Mathematics', 'Mathematics for computing students'),
    ('Web Development', 'Frontend and backend web development'),
    ('AI/ML', 'Artificial Intelligence and Machine Learning resources')
ON CONFLICT DO NOTHING;

-- Table: audit_logs
-- Stores administrative actions for auditing
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB DEFAULT '{}',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: timetables
-- Stores timetable information
-- =====================================================
CREATE TABLE IF NOT EXISTS timetables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    uploaded_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;

-- Audit logs policies
CREATE POLICY "Admins can view audit logs" ON audit_logs
    FOR SELECT USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

-- Timetables policies
CREATE POLICY "Anyone can view current timetables" ON timetables
    FOR SELECT USING (is_current = true OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage timetables" ON timetables
    FOR ALL USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

-- Table: career_paths
-- Stores information about career paths for computing students
-- =====================================================
CREATE TABLE IF NOT EXISTS career_paths (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    overview TEXT,
    skills TEXT[],
    tools TEXT[],
    resources JSONB DEFAULT '[]',
    uploaded_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE career_paths ENABLE ROW LEVEL SECURITY;

-- Career paths policies
CREATE POLICY "Anyone can view career paths" ON career_paths
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage career paths" ON career_paths
    FOR ALL USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

-- =====================================================
-- ADMIN SETUP INSTRUCTIONS
-- =====================================================
-- To create an admin:
-- 1. Sign up a user normally via the signup page or Supabase Dashboard.
-- 2. Get the user's ID from auth.users.
-- 3. Run the following SQL (replace with real values):
-- INSERT INTO admin_users (user_id, name, email, role) 
-- VALUES ('USER_ID_HERE', 'Admin Name', 'admin@email.com', 'super_admin');
-- =====================================================

-- =====================================================
-- Table: events
-- Stores event information
-- =====================================================
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50),
    date DATE NOT NULL,
    time TIME,
    location VARCHAR(255),
    max_attendees INTEGER,
    current_attendees INTEGER DEFAULT 0,
    requires_payment BOOLEAN DEFAULT FALSE,
    payment_amount DECIMAL(10, 2) DEFAULT 0,
    payment_details TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- Table: event_registrations
-- Stores student registrations for events
-- =====================================================
CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(user_id) ON DELETE CASCADE,
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'free')),
    UNIQUE(event_id, student_id)
);

-- =====================================================
-- Table: payment_verification
-- Stores payment proof for manual verification
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_verification (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(user_id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_reference VARCHAR(100) UNIQUE,
    proof_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    verified_by UUID REFERENCES admin_users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_verification ENABLE ROW LEVEL SECURITY;

-- Events policies
CREATE POLICY "Anyone can view active events" ON events
    FOR SELECT USING (is_active = true OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage events" ON events
    FOR ALL USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

-- Event registrations policies
CREATE POLICY "Students can view own registrations" ON event_registrations
    FOR SELECT USING (student_id = auth.uid() OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

CREATE POLICY "Students can register for events" ON event_registrations
    FOR INSERT WITH CHECK (student_id = auth.uid());

-- Payment verification policies
CREATE POLICY "Students can view own payments" ON payment_verification
    FOR SELECT USING (student_id = auth.uid() OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));

CREATE POLICY "Students can submit payment proof" ON payment_verification
    FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Admins can verify payments" ON payment_verification
    FOR UPDATE USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid()));
