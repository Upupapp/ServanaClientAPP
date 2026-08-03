# Profile Backend Gaps — C17 PROFILECORE+

Generated: 2026-07-29

## Summary

Three backend gaps were identified during the C17 customer-profile audit.
None block the core C17 feature (profile load/edit/photo/addresses all work).
Two are P1 (user-visible limitation) and one is P2 (nice-to-have).

---

## GAP-001 — No mobile/phone OTP verification endpoint (P1)

**Symptom**: Users with an unverified phone number have no in-app path to verify it.  
**Root cause**: `POST /api/auth/verify-email-otp` exists for email.  
No equivalent `/api/auth/verify-phone-otp` or `/api/auth/send-phone-otp` exists.  
**Impact**: `AccountCompleteness.hasPhone` shows the number present but there is no
way to confirm ownership of the number inside the app.  
**Workaround**: Phone is captured at signup and considered authoritative (no re-verify
required for booking). The completeness score counts a non-empty phone as a win.  
**Fix path**: Add `POST /api/auth/send-phone-otp` (Twilio/Vonage) + `POST /api/auth/verify-phone-otp`.
Add `is_phone_verified` column to `user_credentials`. Expose it in `GET /api/user/profile`.

---

## GAP-002 — No email change flow (P2)

**Symptom**: Email is read-only in the Edit Profile screen.  
**Root cause**: There is no `POST /api/auth/change-email` endpoint. Changing email
in Firebase Auth also requires re-authentication.  
**Impact**: Customers who signed up with a typo or old address cannot self-serve.  
**Fix path**: Add a two-step flow:
1. `POST /api/auth/request-email-change` → OTP to new address
2. `POST /api/auth/confirm-email-change` → verify OTP, update Firebase + DB

---

## GAP-003 — No address update endpoint (P2)

**Symptom**: Editing a saved address does a delete-then-recreate.  
**Root cause**: `PUT /api/user/updateaddress` does not exist.
Only `POST /api/user/adduseraddress` and `DELETE /api/user/deleteaddress` exist.  
**Impact**: `addressId` changes on every edit (booking history referencing old IDs
is unaffected since bookings store a snapshot, but idempotency is weaker).  
**Fix path**: Add `PUT /api/user/updateaddress?addressId=<id>` accepting the same
payload shape as `adduseraddress`. Use `UPDATE ... WHERE location_id = $1 AND user_id = $2`.

---

## Endpoints confirmed working (C17)

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/user/profile` | GET | Load full profile (JWT-scoped) |
| `/api/user/updateprofile` | PUT | Update name/phone/photo/birthdate/gender |
| `/api/user/alluseraddresses` | GET | Load all addresses |
| `/api/user/adduseraddress` | POST | Create address |
| `/api/user/makeaddressprimary` | PUT | Set primary address |
| `/api/user/deleteaddress` | DELETE | Delete address |
| `/api/auth/resend-email-otp` | POST | Resend email verification OTP |
| `/api/auth/verify-email-otp` | POST | Verify email OTP |
