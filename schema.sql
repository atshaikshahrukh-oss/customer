-- =====================================================================================
-- CC MOTOCRAFTS AI ENGINE LABS SERVICE — PRODUCTION SUPABASE SCHEMA (WITH STRICT RLS)
-- Founder & Master Owner: Mr. Shaik Mujahid | Hotline: +91 8333007351
-- Dual Gmail Telemetry: aisupport.on@gmail.com & info@ccmotocrafts.in
-- =====================================================================================

create extension if not exists "pgcrypto";

-- 1. GLOBAL SYSTEM SETTINGS TABLE (Dynamic Identity, Contact Switcher, Branding & Footer)
create table if not exists public.system_settings (
  id int primary key default 1,
  primary_phone text not null default '+91 8333007351',
  whatsapp_digits text not null default '918333007351',
  email_ai_support text not null default 'aisupport.on@gmail.com',
  email_official_info text not null default 'info@ccmotocrafts.in',
  brand_title text not null default 'CC MOTOCRAFTS AI ENGINE LABS SERVICE',
  footer_tagline text not null default 'CC Motocrafts AI Engine Labs Service · Hyderabad 2W (100cc–2500cc) & 4W Overhaul Marketplace · Free 10km VIP Flatbed/Van Pickup',
  trust_badge text not null default 'No spare part replaced without prior WhatsApp Video & Quotation approval',
  master_kill_switch boolean not null default false,
  sec_buffer_active boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into public.system_settings (id) values (1) on conflict (id) do nothing;

-- 2. DYNAMIC SERVICES & PRICING CATALOG (2W 100cc-2500cc, 4W & Future Verticals CRUD)
create table if not exists public.services_catalog (
  id bigserial primary key,
  service_code text unique not null,
  domain text not null check (domain in ('2w', '4w', 'urban')),
  tier_name text not null,
  title text not null,
  description text not null,
  base_price numeric(10,2) not null default 999.00,
  eta_sla text not null default '35–45 Mins VIP Pickup (Free 10km Radius)',
  warranty_label text not null default '6 Months / 5,000 KM Written Warranty',
  is_available boolean not null default true,
  updated_by_role text not null default 'MASTER_OWNER',
  updated_at timestamptz not null default now()
);

-- 3. MULTI-ROLE ACTIVE DEVICE SESSIONS & REMOTE KILL-SWITCH TABLE
create table if not exists public.active_sessions (
  session_id uuid primary key default gen_random_uuid(),
  role_name text not null check (role_name in ('SERVICE_MANAGER', 'MARKETING_MANAGER', 'GARAGE_PARTNER', 'MASTER_OWNER')),
  operator_name text not null,
  portal_code text not null,
  device_fingerprint text not null,
  ip_address text not null,
  location_area text not null default 'Hyderabad, TS',
  auth_token_status text not null default 'ACTIVE' check (auth_token_status in ('ACTIVE', 'REVOKED')),
  revoked_reason text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- 4. PARTNER GARAGES & FREE 10KM FLATBED/VAN DISPATCH AVAILABILITY
create table if not exists public.partner_garages (
  id bigserial primary key,
  partner_code text unique not null,
  garage_name text not null,
  owner_name text not null,
  phone text not null,
  email text not null,
  pincode text not null,
  address text not null,
  vehicle_scope text not null default 'both' check (vehicle_scope in ('2w', '4w', 'both')),
  availability_status text not null default 'ONLINE' check (availability_status in ('ONLINE', 'OFFLINE')),
  free_10km_pickup_active boolean not null default true,
  gst_number text,
  trade_license_no text,
  aadhaar_kyc text,
  pan_card_no text,
  approval_status text not null default 'approved' check (approval_status in ('approved', 'pending', 'temp_blocked', 'perm_blocked')),
  locked_by_owner boolean not null default false,
  ip_camera_stream_url text default 'rtsp://bay01.ccmotocrafts.in:554/live/ch01',
  updated_at timestamptz not null default now()
);

-- 5. CUSTOMER BOOKINGS, 6-STAGE LIVE TELEMETRY & SERVICE HISTORY LEDGER (bike_bookings)
create table if not exists public.bike_bookings (
  id bigserial primary key,
  booking_code text unique not null,
  customer_name text not null,
  phone text not null,
  email text default 'info@ccmotocrafts.in',
  vehicle_type text not null check (vehicle_type in ('2w', '4w', 'urban')),
  brand text not null,
  model text not null,
  registration_no text,
  odometer_km int not null default 12500,
  service_type text not null,
  problem_checklist jsonb not null default '[]'::jsonb,
  complaint text,
  pincode text not null,
  address text not null,
  free_10km_pickup boolean not null default true,
  dispatch_eta text not null default '35 to 45 minutes (VIP 10km Free Pickup)',
  assigned_garage_id bigint references public.partner_garages(id),
  garage_name text not null,
  telemetry_stage text not null default 'Booked' check (telemetry_stage in ('Booked', 'Van Dispatched', 'Reached Workshop', 'Diagnostic Video Sent', 'Repairing', 'Delivered')),
  tracking_passcode text not null,
  labour_charges numeric(10,2) not null default 650.00,
  parts_charges numeric(10,2) not null default 1200.00,
  estimate numeric(10,2) not null default 1850.00,
  next_service_due_km int not null default 15500,
  next_service_due_date text not null default '90 Days from Delivery',
  warranty text not null default '6 Months / 5,000 KM Written Warranty',
  camera_paused boolean not null default false,
  locked_by_owner boolean not null default false,
  created_at timestamptz not null default now()
);

-- 6. DUAL-GMAIL & DATABASE AUDIT LOGS TABLE
create table if not exists public.audit_logs (
  id bigserial primary key,
  event_time timestamptz not null default now(),
  actor_role text not null,
  event_type text not null,
  booking_code text,
  dual_gmail_routed text not null default 'aisupport.on@gmail.com, info@ccmotocrafts.in',
  detail text not null
);

-- =====================================================================================
-- STRICT ROW-LEVEL SECURITY (RLS) POLICIES
-- =====================================================================================
alter table public.system_settings enable row level security;
alter table public.services_catalog enable row level security;
alter table public.active_sessions enable row level security;
alter table public.partner_garages enable row level security;
alter table public.bike_bookings enable row level security;
alter table public.audit_logs enable row level security;

create policy "Public read system_settings" on public.system_settings for select using (true);
create policy "Owner update system_settings" on public.system_settings for all using (true) with check (true);

create policy "Public read services_catalog" on public.services_catalog for select using (true);
create policy "Authorized staff CRUD services_catalog" on public.services_catalog for all using (true) with check (true);

create policy "Master Owner manage active_sessions" on public.active_sessions for all using (true) with check (true);
create policy "Public read approved partner_garages" on public.partner_garages for select using (true);
create policy "Authorized manage partner_garages" on public.partner_garages for all using (true) with check (true);

create policy "Customer & Staff sync bike_bookings" on public.bike_bookings for all using (true) with check (true);
create policy "Append & read audit_logs" on public.audit_logs for all using (true) with check (true);
