-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MediCore PostgreSQL Database Schema
-- Professional Medical Management System
-- Version: 5.0.0
-- Migration from: SQLite (Drift ORM)
-- Target: PostgreSQL 14+
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 1: USERS
-- User accounts (admin, doctors, nurses, assistants)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    percentage DECIMAL(5,2),
    is_template_user BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync fields
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_users_name ON users(name) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_sync ON users(needs_sync, updated_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_template ON users(is_template_user) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 2: TEMPLATES
-- User role templates for quick user creation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS templates (
    id VARCHAR(255) PRIMARY KEY,
    role VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Sync fields
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_templates_role ON templates(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_templates_sync ON templates(needs_sync, updated_at) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 3: ROOMS
-- Consultation rooms (Cabinets)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_name ON rooms(name);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 4: PATIENTS
-- Patient master data (12 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS patients (
    code INTEGER PRIMARY KEY,  -- Sequential patient number
    barcode VARCHAR(8) UNIQUE NOT NULL,  -- 8-character unique barcode
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    age INTEGER,
    date_of_birth TIMESTAMP WITH TIME ZONE,
    address TEXT,
    phone_number VARCHAR(50),
    other_info TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    needs_sync BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_patients_barcode ON patients(barcode);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_patients_phone ON patients(phone_number);
CREATE INDEX IF NOT EXISTS idx_patients_created ON patients(created_at DESC);
-- Full-text search index for patient names
CREATE INDEX IF NOT EXISTS idx_patients_name_search ON patients USING gin(
    (first_name || ' ' || last_name) gin_trgm_ops
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 5: VISITS
-- Ophthalmology consultation records (54 fields!)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS visits (
    id SERIAL PRIMARY KEY,
    original_id INTEGER,  -- From XML import
    patient_code INTEGER NOT NULL REFERENCES patients(code) ON DELETE CASCADE,
    visit_sequence INTEGER DEFAULT 1,
    visit_date TIMESTAMP WITH TIME ZONE NOT NULL,
    doctor_name VARCHAR(255) NOT NULL,
    motif TEXT,
    diagnosis TEXT,
    conduct TEXT,  -- Treatment/CAT (Conduite à tenir)
    
    -- RIGHT EYE (OD - Oeil Droit) - 18 fields
    od_sv VARCHAR(50),  -- Sans Correction
    od_av VARCHAR(50),  -- Avec Correction
    od_sphere VARCHAR(50),
    od_cylinder VARCHAR(50),
    od_axis VARCHAR(50),
    od_vl VARCHAR(50),  -- Vision de Loin
    od_k1 VARCHAR(50),
    od_k2 VARCHAR(50),
    od_r1 VARCHAR(50),
    od_r2 VARCHAR(50),
    od_r0 VARCHAR(50),  -- Rayon
    od_pachy VARCHAR(50),  -- Pachymetry
    od_toc VARCHAR(50),  -- Tension Oculaire
    od_notes TEXT,
    od_gonio VARCHAR(50),
    od_to VARCHAR(50),
    od_laf TEXT,  -- Lampe à Fente
    od_fo TEXT,  -- Fond d'Oeil
    
    -- LEFT EYE (OG - Oeil Gauche) - 18 fields
    og_sv VARCHAR(50),
    og_av VARCHAR(50),
    og_sphere VARCHAR(50),
    og_cylinder VARCHAR(50),
    og_axis VARCHAR(50),
    og_vl VARCHAR(50),
    og_k1 VARCHAR(50),
    og_k2 VARCHAR(50),
    og_r1 VARCHAR(50),
    og_r2 VARCHAR(50),
    og_r0 VARCHAR(50),
    og_pachy VARCHAR(50),
    og_toc VARCHAR(50),
    og_notes TEXT,
    og_gonio VARCHAR(50),
    og_to VARCHAR(50),
    og_laf TEXT,
    og_fo TEXT,
    
    -- SHARED FIELDS - 2 fields
    addition VARCHAR(50),  -- Addition/EP
    dip VARCHAR(50),  -- Distance Inter-Pupillaire
    
    -- METADATA - 4 fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    needs_sync BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_visits_patient ON visits(patient_code, visit_date DESC);
CREATE INDEX IF NOT EXISTS idx_visits_date ON visits(visit_date DESC);
CREATE INDEX IF NOT EXISTS idx_visits_doctor ON visits(doctor_name);
CREATE INDEX IF NOT EXISTS idx_visits_active ON visits(is_active) WHERE is_active = TRUE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 6: ORDONNANCES
-- Medical documents (prescriptions, certificates, reports) - 23 fields
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ordonnances (
    id SERIAL PRIMARY KEY,
    original_id INTEGER,
    patient_code INTEGER NOT NULL REFERENCES patients(code) ON DELETE CASCADE,
    document_date TIMESTAMP WITH TIME ZONE,
    patient_age INTEGER,
    sequence INTEGER DEFAULT 1,
    seq_pat VARCHAR(50),
    doctor_name VARCHAR(255),
    amount DECIMAL(10,2) DEFAULT 0,
    
    -- Document 1
    content1 TEXT,
    type1 VARCHAR(100) DEFAULT 'ORDONNANCE',
    
    -- Document 2
    content2 TEXT,
    type2 VARCHAR(100),
    
    -- Document 3
    content3 TEXT,
    type3 VARCHAR(100),
    
    -- Additional
    additional_notes TEXT,
    report_title VARCHAR(255),
    referred_by VARCHAR(255),
    rdv_flag INTEGER DEFAULT 0,
    rdv_date VARCHAR(50),
    rdv_day VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ordonnances_patient ON ordonnances(patient_code, document_date DESC);
CREATE INDEX IF NOT EXISTS idx_ordonnances_date ON ordonnances(document_date DESC);
CREATE INDEX IF NOT EXISTS idx_ordonnances_doctor ON ordonnances(doctor_name);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 7: MEDICATIONS
-- Medication/prescription templates (8 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS medications (
    id SERIAL PRIMARY KEY,
    original_id INTEGER,
    code VARCHAR(255) NOT NULL,
    prescription TEXT NOT NULL,
    usage_count INTEGER DEFAULT 0,
    nature VARCHAR(1) DEFAULT 'O',  -- O = Ordonnance, N = Other
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medications_code ON medications(code);
CREATE INDEX IF NOT EXISTS idx_medications_usage ON medications(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_medications_search ON medications USING gin(code gin_trgm_ops);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 8: MEDICAL_ACTS
-- Medical procedures/services (Honoraires) - 6 fields
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS medical_acts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    fee_amount INTEGER NOT NULL,
    display_order INTEGER,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medical_acts_order ON medical_acts(display_order);
CREATE INDEX IF NOT EXISTS idx_medical_acts_name ON medical_acts(name);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 9: PAYMENTS
-- Payment tracking for accounting (14 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    medical_act_id INTEGER NOT NULL REFERENCES medical_acts(id),
    medical_act_name VARCHAR(255) NOT NULL,
    amount INTEGER NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    patient_code INTEGER NOT NULL REFERENCES patients(code),
    patient_first_name VARCHAR(255) NOT NULL,
    patient_last_name VARCHAR(255) NOT NULL,
    payment_time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    needs_sync BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id, payment_time DESC);
CREATE INDEX IF NOT EXISTS idx_payments_patient ON payments(patient_code, payment_time DESC);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_time DESC);
CREATE INDEX IF NOT EXISTS idx_payments_active ON payments(is_active) WHERE is_active = TRUE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 10: MESSAGE_TEMPLATES
-- Quick message templates (5 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS message_templates (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    display_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_message_templates_order ON message_templates(display_order);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 11: MESSAGES
-- Room-based doctor-nurse communication (12 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    room_id VARCHAR(255) NOT NULL REFERENCES rooms(id),
    sender_id VARCHAR(255) NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_role VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    direction VARCHAR(20) NOT NULL,  -- 'to_nurse' or 'to_doctor'
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    patient_code INTEGER,
    patient_name VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_messages_room ON messages(room_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(is_read, room_id) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_messages_direction ON messages(direction, room_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 12: WAITING_PATIENTS
-- Patient waiting queue per room (19 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS waiting_patients (
    id SERIAL PRIMARY KEY,
    patient_code INTEGER NOT NULL REFERENCES patients(code),
    patient_first_name VARCHAR(255) NOT NULL,
    patient_last_name VARCHAR(255) NOT NULL,
    patient_birth_date TIMESTAMP WITH TIME ZONE,
    patient_age INTEGER,
    patient_created_at TIMESTAMP WITH TIME ZONE,
    is_urgent BOOLEAN DEFAULT FALSE,
    is_dilatation BOOLEAN DEFAULT FALSE,
    dilatation_type VARCHAR(20),  -- 'skiacol', 'od', 'og', 'odg'
    room_id VARCHAR(255) NOT NULL REFERENCES rooms(id),
    room_name VARCHAR(255) NOT NULL,
    motif TEXT NOT NULL,
    sent_by_user_id VARCHAR(255) NOT NULL,
    sent_by_user_name VARCHAR(255) NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_checked BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_notified BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_waiting_room ON waiting_patients(room_id, sent_at) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_waiting_patient ON waiting_patients(patient_code);
CREATE INDEX IF NOT EXISTS idx_waiting_active ON waiting_patients(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_waiting_dilatation ON waiting_patients(is_dilatation, room_id) WHERE is_dilatation = TRUE;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 13: APPOINTMENTS
-- Scheduled patient appointments (13 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    age INTEGER,
    date_of_birth TIMESTAMP WITH TIME ZONE,
    phone_number VARCHAR(50),
    address TEXT,
    notes TEXT,
    existing_patient_code INTEGER REFERENCES patients(code),
    was_added BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(existing_patient_code);
CREATE INDEX IF NOT EXISTS idx_appointments_added ON appointments(was_added);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 14: SURGERY_PLANS
-- Surgery scheduling (21 fields)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS surgery_plans (
    id SERIAL PRIMARY KEY,
    surgery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    surgery_hour VARCHAR(10) NOT NULL,
    patient_code INTEGER NOT NULL REFERENCES patients(code),
    patient_first_name VARCHAR(255) NOT NULL,
    patient_last_name VARCHAR(255) NOT NULL,
    patient_age INTEGER,
    patient_phone VARCHAR(50),
    surgery_type VARCHAR(255) NOT NULL,
    eye_to_operate VARCHAR(3) NOT NULL,  -- 'OD', 'OG', 'ODG'
    implant_power VARCHAR(50),
    tarif INTEGER,
    payment_status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'partial', 'paid'
    amount_remaining INTEGER,
    surgery_status VARCHAR(20) DEFAULT 'scheduled',  -- 'scheduled', 'done', 'cancelled'
    patient_came BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    needs_sync BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_surgery_date ON surgery_plans(surgery_date);
CREATE INDEX IF NOT EXISTS idx_surgery_patient ON surgery_plans(patient_code);
CREATE INDEX IF NOT EXISTS idx_surgery_status ON surgery_plans(surgery_status);
CREATE INDEX IF NOT EXISTS idx_surgery_payment ON surgery_plans(payment_status);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL TABLES FOR PROFESSIONAL FEATURES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Session management table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    token VARCHAR(512) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- Audit log table
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_table ON audit_log(table_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at DESC);

-- Nurse preferences (room assignments)
CREATE TABLE IF NOT EXISTS nurse_preferences (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES users(id),
    room1_id VARCHAR(255) REFERENCES rooms(id),
    room2_id VARCHAR(255) REFERENCES rooms(id),
    room3_id VARCHAR(255) REFERENCES rooms(id),
    is_active BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_nurse_active ON nurse_preferences(is_active) WHERE is_active = TRUE;

-- App metadata (for auto-increment tracking, etc.)
CREATE TABLE IF NOT EXISTS app_metadata (
    key VARCHAR(255) PRIMARY KEY,
    value_int BIGINT,
    value_text TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at BEFORE UPDATE ON templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_visits_updated_at BEFORE UPDATE ON visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ordonnances_updated_at BEFORE UPDATE ON ordonnances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_acts_updated_at BEFORE UPDATE ON medical_acts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_surgery_plans_updated_at BEFORE UPDATE ON surgery_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SEED DATA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Insert default admin user
INSERT INTO users (id, name, role, password_hash, is_template_user, needs_sync)
VALUES ('admin', 'Administrateur', 'Administrateur', 'ophfares2016', FALSE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Insert default message templates
INSERT INTO message_templates (content, display_order) VALUES
('Dilatation OG', 1),
('Dilatation OD', 2),
('Dilatation ODG', 3),
('RDV 01 année', 4),
('Faites entrer le malade', 5),
('On Termine', 6),
('RDV 06 mois', 7),
('Pansement', 8),
('Stop Patients', 9),
('Faite le une carte de suivi', 10),
('Viens stp', 11),
('Desinfection', 12),
('RDV laser ARGON', 13),
('Faites entrer post op', 14),
('Numero de telephone', 15)
ON CONFLICT DO NOTHING;

-- Insert default medical acts (Honoraires)
INSERT INTO medical_acts (name, fee_amount, display_order) VALUES
('GRATUIT', 0, 1),
('CONSULTATION +FO', 2000, 2),
('Bilan préop', 3500, 3),
('V3M 1 oeil', 2500, 4),
('CONTROLE', 1000, 5),
('certificat', 1000, 6),
('OCT', 8000, 7),
('TOPOGRAPHIE CORNEENNE', 6000, 8),
('Laser YAG', 8000, 9),
('IP', 12000, 10),
('LASER ARGON 01 oeil', 5000, 11),
('Laser ARGON 2 YEUX', 10000, 12),
('INJECTION celestene + Consulatation', 3000, 13),
('Sondage', 8000, 14),
('Ablation de Fils Cornéen / LVL + Consultation', 3000, 15),
('CHZ', 8000, 16),
('ECHO A', 4000, 17),
('Pachymétrie', 4000, 18),
('Néoformation pp', 20000, 19),
('Néoformation plp', 12000, 20),
('Serum autologue', 3000, 21)
ON CONFLICT DO NOTHING;

-- Initialize patient code counter
INSERT INTO app_metadata (key, value_int) VALUES ('highest_patient_code', 0)
ON CONFLICT (key) DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SCHEMA VERSION TRACKING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO app_metadata (key, value_text) VALUES ('schema_version', '5.0.0')
ON CONFLICT (key) DO UPDATE SET value_text = '5.0.0', updated_at = NOW();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- END OF SCHEMA
-- Total Tables: 18 (14 core + 4 system)
-- Total Fields: ~220 fields
-- Total Indexes: 60+ indexes
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
