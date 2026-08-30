### Project Overview: AeroTeleConsult Kenya Licensing Portal

The AeroTeleConsult Kenya project is a web-based compliance, regulatory intake, and licensing management platform designed to streamline CA (Communications Authority of Kenya) and KCAA (Kenya Civil Aviation Authority) licensing tracks.

---

### Core Components & System Architecture

```
[ Client Form ] ---> (Inserts Intake Data) ---> [ Supabase: input_submissions ]
                                                            |
                                        +-------------------+-------------------+
                                        |                                       |
                               (RPC Check Function)                     (Authenticated Access)
                                        v                                       v
                             [ Client Status Tracker ]             [ Secretariat Admin Dashboard ]

```

* **Backend & Database Platform:** Supabase (PostgreSQL).
* **Primary Database Table:** `input_submissions` (stores intake reference tickets, applicant/company details, contact info, sector track selection, compliance status, and secretarial evaluation notes).
* **Frontend Framework:** Lightweight HTML5, Tailwind CSS, and vanilla JavaScript using the Supabase JS Client (`@supabase/supabase-js`).

---

### Progress & Completed Features

#### 1. Regulatory Intake & Ticket Generation

* Form interface for applicants to register compliance assessments under specific sector tracks (Aviation, Telecom, Private Radio, Amateur Permit).
* Auto-generation of unique tracking reference codes (e.g., `ATC-XXXXXX`).
* Downloadable receipt handler allowing applicants to export their intake receipts.

#### 2. Public Tracking Module

* Client-facing status search form (`#statusCheckForm`) that queries application progress using the tracking ticket code.
* Optimized database access using a Postgres RPC function (`check_application_status`) running under `SECURITY DEFINER` mode to safely return application status and notes to anonymous visitors without exposing raw database tables.

#### 3. Secretariat Operations Admin Dashboard (`admin.html`)

* **Real-time Live Data Fetching:** Directly retrieves and renders active applications from the `input_submissions` table.
* **Metrics Counters:** Summarizes total, under-review, in-processing, and action-required applications at a glance.
* **Interactive Data Grid & Filtering:** Real-time text search (by ticket, company, or contact name) alongside sector and status filters.
* **Evaluation Modal:** Modal interface for secretariat officers to update application statuses (`under_review`, `processing`, `action_required`, `approved`, `rejected`) and save public remark notes back to Supabase.
* **Defensive Data Mapping:** Built-in code fallbacks handling schema field variations (`tracking_ticket` vs. `ticket`, `company_name` vs. `company`, `contact_name` vs. `contact`).

#### 4. Security & Access Control Infrastructure

* **Row-Level Security (RLS) Configuration:**
* Enabled anonymous `INSERT` access on `input_submissions` so visitors can submit forms without logging in.
* Restricted `SELECT` and `UPDATE` permissions exclusively to authenticated users (`TO authenticated`) to keep intake data secure.


* **Admin Dashboard Guard:** Session verification logic (`supabase.auth.getSession()`) enforcing authentication on page load and redirecting unauthenticated users to the login screen.

---

### Current Status & Next Steps

* **Current Status:** Core intake, tracking, admin management, database queries, and basic security models are built and configured.
* **Pending Integration Steps:**
* Deploy and test the live `/login.html` authentication view to issue admin credentials.
* Optionally implement PDF formatting for receipts (via browser print formatting or `jsPDF`).
