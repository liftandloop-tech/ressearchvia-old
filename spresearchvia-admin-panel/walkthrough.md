# Walkthrough: Dual-Stage Applicant Onboarding & Verification

We have successfully implemented the recruitment portal, contact verification flows, and employee promotion systems.

---

## 1. Database & Backend Changes (`l-l-backend`)

* **Schema Extensions (`staffModel.js`)**:
  * Added `stage` field (`'Applicant'` or `'Employee'`).
  * Added OTP fields (`emailOtp`, `mobileOtp`, and expirations) and verification states (`isEmailVerified`, `isMobileVerified`).
  * Added personal/professional details: DOB, gender, profile photo, current and permanent addresses, emergency contacts, experience, previous company, and last CTC.
* **Applicant API Controller (`applicantController.js` [NEW])**:
  * `registerApplicant`: Saves basic applicant profile, sends numeric verification OTPs via SMS (phone) and Nodemailer (email).
  * `verifyOtp`: Validates email and mobile OTPs.
  * `uploadApplicantDoc`: Public upload handler for photos, resumes, and onboarding docs.
  * `uploadApplicantVideo`: Public video upload handler.
  * `listApplicants`: Returns all unapproved applicant records.
  * `approveApplicant`: Admin-only promotion route to assign role, department, MPIN, and active employee status.
* **Route Integrations (`staffroutes/index.js`)**: Mounted public endpoints under `/api/staff/applicant/...` and admin endpoints under `/api/staff/applicants` / `/api/staff/applicant/approve/:id`.
* **Staff Listing**: Filtered out applicants from appearing in the active employee directory.

---

## 2. Flutter Admin Panel UI Changes (`spresearchvia-admin-panel`)

* **Public Job Application (`/apply` [NEW])**: 
  * Displays forms for basic info, addresses, emergency contacts, and professional experience.
  * Initiates email/mobile OTP verification.
  * Once verified, unlocks upload pickers for Profile Photo, Resume/CV, PAN, Aadhaar, NISM Certificate, Highest Education Certificate, and KYC Video.
* **Admin Review Dashboard (`/applicants` [NEW])**:
  * Displays lists of all pending applicants and verification checkmarks.
  * Opens applicant profile summaries, document viewers, and links to download uploaded resumes or play verification videos.
  * Adds an **Approve Dialog** to set the employee's role/department and assign an MPIN.
* **Main Navigation**: Registered routes and mapped tabs/sidebar icons for `/apply` and `/applicants`.

---

## Verification & Testing Instructions

1. **Verify Public Registration Form**:
   * Navigate to `/apply`.
   * Fill out the job application forms and click **Register & Verify**.
   * Receive the OTPs on the email/mobile, enter them, and verify.
   * Upload sample files for profile photo, resume, and onboarding documents.
2. **Review & Approve**:
   * Log in to the Admin Web Panel.
   * Go to the **Job Applicants** tab in the sidebar.
   * Click **View** on your applicant, verify their details/resumes, and click **Approve & Promote to Employee**.
   * Setup their department and MPIN, then save. Verify they now appear under the **Staff** listing!
