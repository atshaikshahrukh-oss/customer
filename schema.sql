-- ============================================================================
-- CC MOTOCRAFTS & CC CARS MOTOCRAFTS AI ENGINE LABS SERVICE
-- SUPABASE PRODUCTION SCHEMA (Project: xrrlbqxbgxmetrwgiwvk)
-- Includes: Server-Side Owner Vault, 1-Device Lock, Masked Telephony Logs,
--           4W CC Tiers, Dual-Gmail Recovery & Realtime Kill-Switches
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. SERVER-SIDE OWNER VAULT (ZERO FRONTEND PASSWORDS)
CREATE TABLE IF NOT EXISTS public.owner_vault (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_name TEXT NOT NULL DEFAULT 'Shaik Mujahid',
  primary_business_email TEXT NOT NULL DEFAULT 'info@ccmotocrafts.in',
  telemetry_gmail TEXT NOT NULL DEFAULT 'aisupport.on@gmail.com',
  backup_personal_gmail TEXT,
  pin_hash TEXT NOT NULL,
  otp_code_hash TEXT,
  otp_expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Secure RPC: Verify Master Owner PIN server-side (never exposed to frontend)
CREATE OR REPLACE FUNCTION public.verify_owner_pin(input_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row public.owner_vault%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM public.owner_vault LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Owner vault not initialized');
  END IF;
  IF v_row.pin_hash = crypt(input_pin, v_row.pin_hash) THEN
    RETURN jsonb_build_object(
      'ok', true,
      'owner_name', v_row.owner_name,
      'primary_email', v_row.primary_business_email,
      'telemetry_gmail', v_row.telemetry_gmail,
      'backup_gmail', v_row.backup_personal_gmail
    );
  END IF;
  RETURN jsonb_build_object('ok', false, 'error', 'Invalid Master PIN');
END;
$$;

-- Secure RPC: Change Master Owner Password/PIN
CREATE OR REPLACE FUNCTION public.update_owner_pin(current_pin TEXT, new_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row public.owner_vault%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM public.owner_vault LIMIT 1;
  IF NOT FOUND OR v_row.pin_hash <> crypt(current_pin, v_row.pin_hash) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Current PIN verification failed');
  END IF;
  UPDATE public.owner_vault
    SET pin_hash = crypt(new_pin, gen_salt('bf', 10)),
        updated_at = NOW()
    WHERE id = v_row.id;
  RETURN jsonb_build_object('ok', true, 'message', 'Master Owner PIN updated securely');
END;
$$;

-- 2. STAFF & PARTNER ACCESS (1 USER = 1 ACCOUNT = 1 DEVICE LOCK)
CREATE TABLE IF NOT EXISTS public.staff_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('partner_2w', 'partner_4w', 'service_manager', 'marketing_manager', 'advisor')),
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL UNIQUE,
  passcode_hash TEXT NOT NULL,
  device_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_profile_locked BOOLEAN NOT NULL DEFAULT FALSE,
  workshop_name TEXT,
  workshop_address TEXT,
  gps_coords TEXT,
  id_proof_url TEXT,
  gst_number TEXT,
  trade_license TEXT,
  last_ip TEXT,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Secure RPC: Verify Staff/Partner Login & Enforce 1-Device Lock + Kill-Switch
CREATE OR REPLACE FUNCTION public.verify_staff_login(
  p_identifier TEXT,
  p_passcode TEXT,
  p_device_id TEXT,
  p_expected_role_group TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff public.staff_access%ROWTYPE;
BEGIN
  SELECT * INTO v_staff
  FROM public.staff_access
  WHERE email = p_identifier OR phone = p_identifier
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'code', 'NOT_FOUND', 'error', 'Account not registered');
  END IF;

  IF v_staff.is_active = FALSE THEN
    RETURN jsonb_build_object('ok', false, 'code', 'SUSPENDED', 'error', 'Your device has an issue. Access suspended — contact CC Motocrafts Admin.');
  END IF;

  IF v_staff.passcode_hash <> crypt(p_passcode, v_staff.passcode_hash) THEN
    RETURN jsonb_build_object('ok', false, 'code', 'BAD_CREDENTIALS', 'error', 'Invalid credentials');
  END IF;

  -- Enforce 1 User = 1 Account = 1 Device Lock
  IF v_staff.device_id IS NULL OR v_staff.device_id = '' THEN
    UPDATE public.staff_access SET device_id = p_device_id, last_seen = NOW() WHERE id = v_staff.id;
  ELSIF v_staff.device_id <> p_device_id THEN
    RETURN jsonb_build_object('ok', false, 'code', 'DEVICE_LOCKED', 'error', 'Account locked to another registered device. Ask Master Owner to click Reset Device.');
  ELSE
    UPDATE public.staff_access SET last_seen = NOW() WHERE id = v_staff.id;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'id', v_staff.id,
    'full_name', v_staff.full_name,
    'role', v_staff.role,
    'is_profile_locked', v_staff.is_profile_locked,
    'workshop_name', v_staff.workshop_name
  );
END;
$$;

-- 3. GLOBAL SYSTEM SETTINGS & MULTI-AI API CONNECTORS
CREATE TABLE IF NOT EXISTS public.system_settings (
  id INT PRIMARY KEY DEFAULT 1,
  hotline_display TEXT NOT NULL DEFAULT '+91 8333084261',
  whatsapp_digits TEXT NOT NULL DEFAULT '918333084261',
  primary_email TEXT NOT NULL DEFAULT 'info@ccmotocrafts.in',
  telemetry_gmail TEXT NOT NULL DEFAULT 'aisupport.on@gmail.com',
  backup_gmail TEXT DEFAULT '',
  brand_2w_name TEXT NOT NULL DEFAULT 'CC Motocrafts AI Engine Labs Service',
  brand_4w_name TEXT NOT NULL DEFAULT 'CC Cars Motocrafts AI Engine Labs Service',
  active_ai_provider TEXT NOT NULL DEFAULT 'gemini',
  gemini_api_key TEXT DEFAULT '',
  openai_api_key TEXT DEFAULT '',
  claude_api_key TEXT DEFAULT '',
  promo_banner TEXT NOT NULL DEFAULT 'CC MOTOCRAFTS | HYDERABAD 2W (100cc-2500cc) & 4W (800cc-6500cc) PETROL/DIESEL/CNG LABS · NO EV · FREE 10KM PICKUP IN VIP PINCODES',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. DYNAMIC SERVICES & 4W CC DISPLACEMENT CATALOG
CREATE TABLE IF NOT EXISTS public.services_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  division TEXT NOT NULL CHECK (division IN ('2w', '4w', 'home', 'ac')),
  cc_tier TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price_inr NUMERIC(10,2) NOT NULL,
  is_live BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. BOOKINGS & GOOGLE MAPS UTM TRACKING
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_code TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  division TEXT NOT NULL CHECK (division IN ('2w', '4w')),
  brand TEXT NOT NULL,
  fuel_type TEXT NOT NULL CHECK (fuel_type IN ('Petrol', 'Diesel', 'CNG-LPG Gas')),
  cc_tier TEXT NOT NULL,
  vehicle_model TEXT NOT NULL,
  odometer_km INTEGER,
  symptoms TEXT,
  pincode TEXT,
  gps_lat DOUBLE PRECISION,
  gps_lng DOUBLE PRECISION,
  utm_source TEXT DEFAULT 'direct',
  promo_code TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'BOOKED' CHECK (status IN ('BOOKED', 'VAN_DISPATCHED', 'REACHED_WORKSHOP', 'DIAGNOSTIC_VIDEO_SENT', 'REPAIRING', 'DELIVERED')),
  quotation_approved BOOLEAN NOT NULL DEFAULT FALSE,
  media_proof_uploaded BOOLEAN NOT NULL DEFAULT FALSE,
  assigned_partner_id UUID REFERENCES public.staff_access(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. JOB TRACKING, EMERGENCY VIDEO/TRACKING KILL-SWITCH & MASKED TELEPHONY LOGS
CREATE TABLE IF NOT EXISTS public.job_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  live_video_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  gps_tracking_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  call_timestamp TIMESTAMPTZ,
  call_duration_sec INTEGER DEFAULT 0,
  call_recording_url TEXT,
  updated_by TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_role TEXT NOT NULL,
  action TEXT NOT NULL,
  target_id TEXT,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.owner_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Public read-only access to live catalog & non-sensitive settings
CREATE POLICY "Public read live services" ON public.services_catalog FOR SELECT USING (is_live = TRUE);
CREATE POLICY "Public insert bookings" ON public.bookings FOR INSERT WITH CHECK (TRUE);

-- Enable Supabase Realtime for 2-second Staff Kill-Switch & Incident Hold
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_access;
ALTER PUBLICATION supabase_realtime ADD TABLE public.job_tracking;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.services_catalog;
ALTER PUBLICATION supabase_realtime ADD TABLE public.system_settings;
