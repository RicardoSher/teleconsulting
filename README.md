# AeroTeleConsult Kenya & Wankilb ProTech Web Application Suite

> High-reliability regulatory frequency compliance secretariat, technical engineering dispatch, and authenticated executive client portal.

---

## 🚀 Overview

The **teleconsult** suite operates a unified platform for two synchronized practices based in Nairobi, Kenya:

1. **AeroTeleConsult Kenya:**
   - Aviation radio station licenses (VHF/HF air-band, Mode-S transponders, ELT beacons) with KCAA & CA.
   - Telecom carrier operator licensing (NFP/ASP Tier 1–3).
   - Private Mobile Radio (PMR) trunked networks (mining, logistics, security, conservation).
   - Amateur Radio Operator permits & callsign reservations.

2. **Wankilb ProTech & Skills Solutions:**
   - Computer hardware repair, thermal servicing, SSD upgrades, and forensic data recovery.
   - Precision smart TV wall mountings with concealed raceway cabling.
   - Custom web application and portal engineering.
   - Practical 4-Week Computer Packages & AI Productivity Bootcamp.

---

## 📁 Repository Structure

```
teleconsult/
├── assets/
│   ├── logo-icon.svg        # Scalable Vector Brand Insignia (Swept delta wing & spectrum transceiver)
│   ├── logo.svg             # Horizontal full lockup for light themes (420x88)
│   ├── logo-dark.svg        # Horizontal full lockup for dark themes (420x88)
│   ├── aeroteleconsult_logo_dark.jpg  # Ultra-high-resolution corporate render (Dark Slate)
│   └── aeroteleconsult_logo_light.jpg # Ultra-high-resolution corporate render (Clean White)
├── index.html         # AeroTeleConsult Landing Page, Fast-Track Intake & Status Tracker
├── client.html        # Authenticated Executive Client Portal & Secretariat Realtime Chat
├── services.html      # Wankilb ProTech Service Catalogue, Rate Estimator & Dispatch Booking
├── admin.html         # Secretariat Operations Command Console (Admin & Field Dispatch)
├── config.js          # Centralized Configuration, Supabase Client & Shared Metadata
├── schema.sql         # Complete PostgreSQL / Supabase Cloud Database Migration & RLS Script
├── supabase/
│   └── functions/
│       └── notify-new-ticket/
│           └── index.ts # Supabase Edge Function for automated email & webhook alerting
└── README.md          # Comprehensive Architecture, Setup & Deployment Guide
```

---

## 🛠 Tech Stack

- **Frontend Core:** Pure HTML5, CSS3, Modern ES6+ JavaScript.
- **Styling:** Tailwind CSS with custom `brand` and `aero` palettes, Plus Jakarta Sans & JetBrains Mono typography.
- **Backend & Database:** Supabase (PostgreSQL, Supabase Auth, Storage, and Realtime WebSockets).
- **Document & Receipt Generation:** Client-side `jsPDF` v2.5.1 producing high-resolution corporate A4 vouchers and 80mm/58mm EPOS thermal slips.
- **Payment & Settlement:** Lipa na M-PESA Buy Goods Till (`4676122`) & Corporate Paybill (`247247`, Account `194489`).

---

## 🗄 Database & Supabase Setup

### 1. Apply Schema Migrations
1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
2. Navigate to **SQL Editor** &rarr; **New Query**.
3. Copy the contents of [`schema.sql`](./schema.sql) and execute the script.
4. This creates:
   - Tables: `intake_submissions`, `tech_service_orders`, `authorized_admins`, `clients`, `client_documents`, `chat_messages`, `proforma_invoices`.
   - Security: Complete Row-Level Security (RLS) policies.
   - Storage: `client-documents` bucket.
   - Functions: `check_application_status()` and `set_updated_at()`.
   - Realtime: WebSocket publications for tickets and live chat.

### 2. Configure Environment Variables (`config.js`)
Update your Supabase credentials in [`config.js`](./config.js):
```javascript
window.APP_CONFIG = {
    SUPABASE_URL: "https://your-project.supabase.co",
    SUPABASE_ANON_KEY: "your-anon-public-key",
    ...
};
```
*Tip: You can also override credentials dynamically via the Secretariat Console in `admin.html` without editing source code.*

### 3. Deploy Edge Function (`notify-new-ticket`)
Deploy the edge function using the Supabase CLI:
```bash
supabase functions deploy notify-new-ticket --project-ref your-project-id
supabase secrets set NOTIFICATION_EMAIL="kilbdynamicsltd@gmail.com" RESEND_API_KEY="re_..."
```

---

## 🖥 Local Development

Because this suite has **zero build dependencies**, you can preview and run it using any static HTTP server:

```bash
# Python 3
python -m http.server 8080

# Or Node.js npx
npx serve .
```

Open `http://localhost:8080` in any web browser.

---

## 🔒 Security Best Practices

- **Row-Level Security (RLS):** All tables have RLS enabled. Direct public updates and deletions are blocked.
- **Admin Verification:** Access to `admin.html` checks authenticated user emails against `authorized_admins` in PostgreSQL.
- **Storage Protection:** Documents uploaded to `client-documents` are isolated and tied to client identifiers.
- **Sanitization:** All user inputs and chat messages are HTML-escaped to prevent XSS.

---

## 📞 Secretariat & Support Contacts

- **Hotline / WhatsApp:** +254 723 489 194
- **Official Email:** kilbdynamicsltd@gmail.com
- **Payment Paybill:** 247247 (Account: 194489 or Ticket Ref)
- **Headquarters:** Nairobi, Kenya
