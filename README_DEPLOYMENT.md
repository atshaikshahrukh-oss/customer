# CC Motocrafts Global Platform — Deployment & Verification

## What this package contains
- Clean root architecture: `index.html`, `customer.html`, `diagnosis.html`, `garage.html`, `admin.html`, `ceo.html`, `owner.html`.
- Original 2W/4W portfolio images retained under `assets/portfolio/`.
- Installable PWA manifests and local PNG icons.
- PHP 8+ / MySQL API with session cookies, role checks, CSRF tokens, booking intake, owner-only partner approval/blocking, manager assignment, partner-only assigned jobs, parking search/reservation and separate 2W/4W AI routing.
- AI provider failover order: configured primary, then other configured providers (OpenAI, Gemini, Anthropic). Secrets remain server-side.
- Voice input uses browser SpeechRecognition when supported; typing remains available.

## Honest readiness boundary
This is a deployable application source package, not a live connected service. The supplied project did not contain a known backend, database credentials, AI API keys, WhatsApp Business API credentials, CCTV/WebRTC credentials or SMTP provider configuration. Those cannot be invented or tested from this archive. No real booking, AI-provider request, email, WhatsApp automation, live camera or scheduled backup is claimed until those dependencies are configured and verified.

## Hostinger PHP/MySQL setup\nRequired PHP extensions: `pdo_mysql`, `curl`, and `mbstring`; enable these in hPanel PHP configuration. The build container used for source checks did not have these extensions, so live database/AI integration could not be exercised here.
1. Back up `public_html` and upload the contents of this package to a separate `/preview/` folder first.
2. In Hostinger hPanel, create a MySQL database and database user.
3. Import `database/schema.sql` using phpMyAdmin.
4. Copy `config/config.example.php` to `config/config.php`. Enter database details and your exact HTTPS domain in `base_url` and `allowed_origins`.
5. Keep `config/config.php` private. The included `.htaccess` denies direct access to configuration and SQL files. Confirm Apache/LiteSpeed honours `.htaccess`.
6. Run the owner bootstrap once using SSH/terminal: `php install.php owner@example.com +919999999999 'A-long-random-password-14chars-min'`. Do not use the example values. Delete `install.php` after owner creation.
7. Create manager/partner/customer users through a future controlled admin onboarding process or insert securely generated password hashes. Do not reuse old demo passcodes.
8. Add approved garages and parking slots using parameterized SQL/admin tooling. Partner user `partner_id` must reference its garage row.
9. Configure AI keys in `config/config.php`; never put them in HTML/JS. Enable cURL in PHP. Test each provider and fallback with non-production keys first.
10. Configure mail transport and a queue worker for `notification_outbox`. WhatsApp automatic delivery needs an approved WhatsApp Business API provider; `wa.me` links are not automated messaging.
11. Set up Hostinger cron for database backups outside `public_html`, with retention and a tested restore procedure. This package does not claim midnight backup until cron is configured and restore-tested.
12. Register service worker only on HTTPS. Install each app from its corresponding start URL.

## API smoke checks
- `GET /api/index.php?action=health`
- `GET /api/index.php?action=csrf`
- Login: `POST /api/index.php?action=login` with `{ "login":"...", "password":"..." }`
- Authenticated requests use the PHP session cookie and `X-CSRF-Token` from the CSRF endpoint.
- Booking: `POST /api/index.php?action=booking.create`
- Booking list: `GET /api/index.php?action=booking.list`
- Parking: `GET /api/index.php?action=parking.search&city=Hyderabad&vehicleType=2w`

## Required production acceptance tests
- Test with distinct owner, manager, partner and customer accounts.
- Confirm manager cannot approve/block partners.
- Confirm partner cannot assign jobs and cannot view another garage's bookings.
- Confirm customer cannot view another customer's bookings.
- Confirm CSRF failures are rejected.
- Confirm duplicate/overlapping parking requests respect capacity.
- Confirm 2W assistant rejects car-domain questions and 4W assistant rejects bike-domain questions (tighten prompts and add explicit server validation before public launch).
- Test provider outage fallback, quotas, latency and cost caps.
- Test email/WhatsApp delivery and outbox retries.
- Test backup restoration, not just backup file creation.
- Test PWA install on Android Chrome and iOS Safari separately.\n- Test CEO dashboard with owner and non-owner sessions.\n- Test diagnosis domain separation with 2W and 4W prompts.

## Important business settings
The original archive contained hardcoded demo login passcodes, demo customer/partner records and sample financial/vehicle data. This rebuild does not carry those credentials into the new app. Create real accounts and use real customer consent/data only.
