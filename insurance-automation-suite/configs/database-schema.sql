-- =====================================================
-- INSURANCE AUTOMATION SUITE - DATABASE SCHEMA
-- =====================================================
-- PostgreSQL 12+ Required
-- Run this script to create all necessary tables
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- LEADS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,

    -- Basic Info
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,

    -- Demographics
    age INTEGER,
    income DECIMAL(12,2),
    marital_status VARCHAR(50),
    dependents INTEGER DEFAULT 0,
    employment_status VARCHAR(100),

    -- Insurance Details
    coverage_type VARCHAR(100),
    coverage_amount VARCHAR(50),
    has_existing_coverage BOOLEAN DEFAULT false,
    existing_coverage_details TEXT,
    health_status VARCHAR(50),
    smoker BOOLEAN DEFAULT false,

    -- Lead Source & Tracking
    source VARCHAR(100),
    source_details TEXT,
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),

    -- Qualification
    qualification_score INTEGER,
    qualification_tier VARCHAR(20), -- HOT, WARM, LUKEWARM, COLD
    qualification_reasoning TEXT,
    red_flags JSONB,
    urgency_level VARCHAR(20),
    close_probability VARCHAR(20),
    assigned_agent_tier VARCHAR(50),

    -- Status & Follow-Up
    status VARCHAR(50) DEFAULT 'new', -- new, qualified, contacted, quote_sent, nurture, closed_won, closed_lost
    priority INTEGER DEFAULT 3,
    follow_up_at TIMESTAMP,
    follow_up_count INTEGER DEFAULT 0,
    last_contacted_at TIMESTAMP,

    -- Policy Details (if converted)
    policy_number VARCHAR(100),
    policy_start_date DATE,
    policy_renewal_date DATE,
    annual_premium DECIMAL(10,2),

    -- Metadata
    raw_data JSONB,
    notes TEXT,
    unsubscribed BOOLEAN DEFAULT false,
    qualified_at TIMESTAMP,
    last_quote_sent_at TIMESTAMP,
    last_no_show_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes
    CONSTRAINT unique_email UNIQUE(email)
);

CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_phone ON leads(phone);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_qualification_tier ON leads(qualification_tier);
CREATE INDEX idx_leads_follow_up_at ON leads(follow_up_at);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);

-- =====================================================
-- CLIENTS TABLE (Converted Leads)
-- =====================================================
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id),

    -- Basic Info
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,

    -- Policy Details
    policy_number VARCHAR(100) NOT NULL UNIQUE,
    coverage_type VARCHAR(100) NOT NULL,
    coverage_amount DECIMAL(12,2),
    monthly_premium DECIMAL(10,2),
    annual_premium DECIMAL(10,2),

    policy_start_date DATE NOT NULL,
    policy_end_date DATE,
    policy_renewal_date DATE,

    -- Status
    policy_status VARCHAR(50) DEFAULT 'active', -- active, cancelled, expired, pending

    -- Financial
    payment_method VARCHAR(50),
    auto_pay_enabled BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_policy_number ON clients(policy_number);
CREATE INDEX idx_clients_policy_renewal_date ON clients(policy_renewal_date);

-- =====================================================
-- FOLLOW-UP CAMPAIGNS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS follow_up_campaigns (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) UNIQUE,

    -- Campaign Status
    follow_up_count INTEGER DEFAULT 0,
    last_contact_at TIMESTAMP,
    last_contact_type VARCHAR(20), -- email, sms, multi
    last_message_sent TEXT,
    next_follow_up_at TIMESTAMP,

    -- Response Tracking
    email_opens INTEGER DEFAULT 0,
    email_clicks INTEGER DEFAULT 0,
    sms_responses INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_followup_next_followup ON follow_up_campaigns(next_follow_up_at);
CREATE INDEX idx_followup_lead_id ON follow_up_campaigns(lead_id);

-- =====================================================
-- APPOINTMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id),
    client_id INTEGER REFERENCES clients(id),

    -- Appointment Details
    calendar_event_id VARCHAR(255) UNIQUE,
    appointment_time TIMESTAMP NOT NULL,
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    duration_minutes INTEGER DEFAULT 30,
    meeting_type VARCHAR(50), -- discovery_call, quote_review, policy_review
    meeting_link TEXT,

    -- Contact Info
    lead_email VARCHAR(255),
    lead_phone VARCHAR(20),
    lead_name VARCHAR(255),

    -- Status
    status VARCHAR(50) DEFAULT 'confirmed', -- confirmed, reminded, completed, no_show, cancelled

    -- Reminders
    confirmation_sent BOOLEAN DEFAULT false,
    confirmation_sent_at TIMESTAMP,
    reminder_1_sent BOOLEAN DEFAULT false,
    reminder_1_sent_at TIMESTAMP,
    reminder_2_sent BOOLEAN DEFAULT false,
    reminder_2_sent_at TIMESTAMP,
    reminder_3_sent BOOLEAN DEFAULT false,
    reminder_3_sent_at TIMESTAMP,

    -- No-Show Recovery
    no_show_recovery_sent BOOLEAN DEFAULT false,
    no_show_recovery_sent_at TIMESTAMP,

    -- Timestamps
    booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_appointments_time ON appointments(appointment_time);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_lead_id ON appointments(lead_id);

-- =====================================================
-- REFERRAL CAMPAIGNS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS referral_campaigns (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id) UNIQUE,

    -- Review Request
    review_request_sent BOOLEAN DEFAULT false,
    review_request_sent_at TIMESTAMP,
    review_request_scheduled_for TIMESTAMP,
    review_submitted BOOLEAN DEFAULT false,
    review_submitted_at TIMESTAMP,

    -- Referral Request
    referral_request_sent BOOLEAN DEFAULT false,
    referral_request_sent_at TIMESTAMP,
    referral_request_scheduled_for TIMESTAMP,
    referrals_received INTEGER DEFAULT 0,
    last_referral_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_referral_review_scheduled ON referral_campaigns(review_request_scheduled_for);
CREATE INDEX idx_referral_referral_scheduled ON referral_campaigns(referral_request_scheduled_for);

-- =====================================================
-- REFERRALS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS referrals (
    id SERIAL PRIMARY KEY,
    referring_client_id INTEGER REFERENCES clients(id),

    -- Referred Person
    referred_name VARCHAR(255),
    referred_email VARCHAR(255),
    referred_phone VARCHAR(20),

    -- Tracking
    referral_source VARCHAR(50), -- direct, review_platform, social
    status VARCHAR(50) DEFAULT 'new', -- new, contacted, qualified, converted, lost
    converted_to_lead_id INTEGER REFERENCES leads(id),
    converted_to_client_id INTEGER REFERENCES clients(id),

    -- Incentive
    incentive_type VARCHAR(100),
    incentive_amount DECIMAL(10,2),
    incentive_paid BOOLEAN DEFAULT false,
    incentive_paid_at TIMESTAMP,

    -- Timestamps
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    converted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_referrals_referring_client ON referrals(referring_client_id);
CREATE INDEX idx_referrals_status ON referrals(status);

-- =====================================================
-- QUOTES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS quotes (
    id SERIAL PRIMARY KEY,
    quote_id VARCHAR(100) UNIQUE NOT NULL,
    lead_id INTEGER REFERENCES leads(id),

    -- Quote Details
    coverage_type VARCHAR(100) NOT NULL,
    coverage_amount VARCHAR(50),
    monthly_premium VARCHAR(50),
    annual_premium VARCHAR(50),

    -- AI-Generated Data
    quote_data_json JSONB,

    -- Status
    status VARCHAR(50) DEFAULT 'sent', -- sent, viewed, accepted, rejected, expired

    -- Tracking
    email_opened BOOLEAN DEFAULT false,
    email_opened_at TIMESTAMP,
    quote_viewed_at TIMESTAMP,

    -- Expiration
    generated_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_quotes_quote_id ON quotes(quote_id);
CREATE INDEX idx_quotes_lead_id ON quotes(lead_id);
CREATE INDEX idx_quotes_expires_at ON quotes(expires_at);

-- =====================================================
-- NURTURE CAMPAIGNS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS nurture_campaigns (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id) UNIQUE,

    -- Campaign Progress
    nurture_sequence_step INTEGER DEFAULT 0,
    last_nurture_sent_at TIMESTAMP,

    -- Engagement
    emails_sent INTEGER DEFAULT 0,
    emails_opened INTEGER DEFAULT 0,
    links_clicked INTEGER DEFAULT 0,

    -- Status
    campaign_status VARCHAR(50) DEFAULT 'active', -- active, paused, completed, unsubscribed

    -- Timestamps
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nurture_lead_id ON nurture_campaigns(lead_id);
CREATE INDEX idx_nurture_last_sent ON nurture_campaigns(last_nurture_sent_at);

-- =====================================================
-- ONBOARDING SEQUENCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS onboarding_sequences (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id) UNIQUE,

    -- Welcome Flow
    welcome_sent BOOLEAN DEFAULT false,
    welcome_sent_at TIMESTAMP,

    -- Documents
    documents_sent BOOLEAN DEFAULT false,
    documents_sent_at TIMESTAMP,

    -- Check-Ins
    check_in_1_sent BOOLEAN DEFAULT false, -- 7 days
    check_in_1_sent_at TIMESTAMP,
    check_in_30_sent BOOLEAN DEFAULT false, -- 30 days
    check_in_30_sent_at TIMESTAMP,

    -- Renewal
    renewal_reminder_sent BOOLEAN DEFAULT false,
    renewal_reminder_sent_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_onboarding_client_id ON onboarding_sequences(client_id);

-- =====================================================
-- CHAT SESSIONS TABLE (For AI Chat Bot)
-- =====================================================
CREATE TABLE IF NOT EXISTS chat_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,

    -- Messages
    user_message TEXT,
    bot_response TEXT,

    -- Data Collection
    collected_data JSONB,
    ready_for_handoff BOOLEAN DEFAULT false,

    -- Conversion
    converted_to_lead_id INTEGER REFERENCES leads(id),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_session_id ON chat_sessions(session_id);
CREATE INDEX idx_chat_created_at ON chat_sessions(created_at DESC);

-- =====================================================
-- MISSED CALLS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS missed_calls (
    id SERIAL PRIMARY KEY,

    -- Call Details
    phone_number VARCHAR(20) NOT NULL,
    call_time TIMESTAMP NOT NULL,
    duration INTEGER DEFAULT 0,

    -- Associated Records
    lead_id INTEGER REFERENCES leads(id),
    client_id INTEGER REFERENCES clients(id),

    -- Classification
    is_known_contact BOOLEAN DEFAULT false,
    urgency VARCHAR(20),

    -- Recovery
    recovery_sent BOOLEAN DEFAULT false,
    recovery_sent_at TIMESTAMP,

    -- Response
    callback_completed BOOLEAN DEFAULT false,
    callback_completed_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_missed_calls_phone ON missed_calls(phone_number);
CREATE INDEX idx_missed_calls_time ON missed_calls(call_time DESC);

-- =====================================================
-- LEAD ACTIVITY LOG (Audit Trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS lead_activity_log (
    id SERIAL PRIMARY KEY,
    lead_id INTEGER REFERENCES leads(id),

    -- Activity Details
    activity_type VARCHAR(100) NOT NULL, -- email_sent, sms_sent, status_changed, etc.
    activity_description TEXT,

    -- Metadata
    workflow_id VARCHAR(255),
    execution_id VARCHAR(255),
    performed_by VARCHAR(100) DEFAULT 'automation',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activity_lead_id ON lead_activity_log(lead_id);
CREATE INDEX idx_activity_type ON lead_activity_log(activity_type);
CREATE INDEX idx_activity_created_at ON lead_activity_log(created_at DESC);

-- =====================================================
-- AUTOMATION METRICS (Performance Tracking)
-- =====================================================
CREATE TABLE IF NOT EXISTS automation_metrics (
    id SERIAL PRIMARY KEY,

    -- Metric Info
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(12,2),
    metric_unit VARCHAR(50),

    -- Context
    workflow_name VARCHAR(255),
    time_period DATE,

    -- Metadata
    metadata JSONB,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_metrics_name ON automation_metrics(metric_name);
CREATE INDEX idx_metrics_period ON automation_metrics(time_period DESC);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Active Leads Dashboard
CREATE OR REPLACE VIEW v_active_leads AS
SELECT
    l.*,
    fc.follow_up_count,
    fc.last_contact_at,
    fc.next_follow_up_at,
    CASE
        WHEN l.follow_up_at < NOW() THEN 'overdue'
        WHEN l.follow_up_at BETWEEN NOW() AND NOW() + INTERVAL '24 hours' THEN 'due_soon'
        ELSE 'scheduled'
    END as follow_up_status
FROM leads l
LEFT JOIN follow_up_campaigns fc ON l.id = fc.lead_id
WHERE l.status NOT IN ('closed_won', 'closed_lost', 'unsubscribed');

-- Performance Dashboard
CREATE OR REPLACE VIEW v_performance_dashboard AS
SELECT
    DATE_TRUNC('week', created_at) as week,
    COUNT(*) as total_leads,
    COUNT(*) FILTER (WHERE qualification_tier = 'HOT') as hot_leads,
    COUNT(*) FILTER (WHERE qualification_tier = 'WARM') as warm_leads,
    COUNT(*) FILTER (WHERE status = 'closed_won') as closed_won,
    AVG(qualification_score) as avg_qualification_score,
    COUNT(DISTINCT CASE WHEN status = 'closed_won' THEN id END)::FLOAT /
        NULLIF(COUNT(DISTINCT id), 0) * 100 as conversion_rate
FROM leads
WHERE created_at >= NOW() - INTERVAL '12 weeks'
GROUP BY week
ORDER BY week DESC;

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_followup_updated_at BEFORE UPDATE ON follow_up_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_referral_campaigns_updated_at BEFORE UPDATE ON referral_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample leads for testing
/*
INSERT INTO leads (first_name, last_name, email, phone, age, income, coverage_type, source, qualification_score, qualification_tier, status)
VALUES
    ('John', 'Doe', 'john.doe@example.com', '+12345678901', 35, 75000, 'Term Life', 'website', 85, 'HOT', 'qualified'),
    ('Jane', 'Smith', 'jane.smith@example.com', '+12345678902', 42, 120000, 'Whole Life', 'referral', 92, 'HOT', 'contacted'),
    ('Bob', 'Johnson', 'bob.j@example.com', '+12345678903', 28, 45000, 'Health Insurance', 'facebook', 55, 'WARM', 'quote_sent');
*/

-- =====================================================
-- COMPLETE!
-- =====================================================
-- Database schema setup complete.
-- All tables, indexes, views, and triggers created.
-- =====================================================
