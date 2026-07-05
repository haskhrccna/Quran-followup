# Attendance Tracking — Architecture Guide

Attendance in this system is not a standalone calendar of check-ins. It is the
**close-out step of an appointment**: when a teacher records attendance for a
session, the server writes exactly one `SessionRecord` and flips the parent
`Appointment` to `COMPLETED` in the same transaction. Everything else —
student/parent history views, teacher analytics, notifications — reads from
that one table.

Introduced in Phase 2 (migration `20260606160000_add_attendance_session_records`).

## The one-minute picture

```
Teacher (mobile)                                          Student (mobile)
     │                                                          ▲
     │ POST /api/v1/appointments/:id/attendance                 │ push + in-app feed
     ▼                                                          │
appointment.routes.ts ── authorize(TEACHER) ──► attendance.controller.recordAttendance
                                                        │
                                                        ▼
                                        attendance.service.recordAttendance
                                          1. appointment exists + belongs to teacher
                                          2. assertTeacherCanAccessStudent (ACCEPTED appt)
                                          3. reject duplicate (409)
                                          4. $transaction:
                                               • create SessionRecord
                                               • Appointment.status → COMPLETED
                                          5. notifyUser('attendance_recorded')  ← best-effort
                                                        │
                                                        ▼
                                              session_records (PostgreSQL)
                                                        ▲
              ┌─────────────────────────────────────────┼──────────────────────────┐
   GET /api/v1/attendance                    parent.service                analytics.service
   (student / teacher / admin)               getChildDashboard             teacher activity +
                                             (last 5 records)              weekly active students
```

## Data model

`SessionRecord` (`packages/server/prisma/schema.prisma:369`, table
`session_records`):

| Column | Type | Notes |
|---|---|---|
| `id` | cuid | PK |
| `appointmentId` | FK → `appointments` | **`@unique` — 1:1 with Appointment**, cascade delete |
| `studentId` | FK → `users` | denormalized from the appointment, cascade delete |
| `teacherId` | FK → `users` | the recorder, cascade delete |
| `status` | `AttendanceStatus` enum | `PRESENT` \| `ABSENT` \| `LATE` \| `EXCUSED` |
| `notes` | text, nullable | free-form teacher note |
| `recordedAt` | timestamp | defaults to now |

Indexes: `(studentId, recordedAt)` and `(teacherId, recordedAt)` serve the two
history queries; `(status)` serves aggregate/analytics filters.

Design points worth knowing:

- **The unique index on `appointmentId` is the source of truth for
  idempotency.** The service also checks for an existing record first so the
  API can return a clean `409` instead of a Prisma unique-constraint error,
  but the database enforces the invariant regardless of code paths.
- `studentId`/`teacherId` are copied onto the record even though they are
  derivable through the appointment. This keeps history queries
  single-table-indexed and avoids joins for the common reads.
- There is **no update or delete endpoint**. Once recorded, attendance is
  immutable through the API (correcting a mistake currently requires DB
  access). Deleting the appointment or either user cascades the record away.

## HTTP surface

Two endpoints, split across two routers:

### Write — `POST /api/v1/appointments/:id/attendance`

Defined in `packages/server/src/routes/appointment.routes.ts:32`, guarded by
`authorize(UserRole.TEACHER)`. It lives under the **appointments** router
(not `/attendance`) because it is semantically an action on an appointment.

- Body: `{ status: 'PRESENT' | 'ABSENT' | 'LATE' | 'EXCUSED', notes?: string }`
- The controller (`attendance.controller.ts`) validates `status` against the
  allow-list by hand — this route does **not** use the shared
  `validate(ZodSchema)` middleware that sibling appointment routes use.
  Empty-string `notes` are treated as no note (stored as `null`).
- Returns `201` with `{ success: true, data: <SessionRecord including
  appointment.requestedDate/requestedTime> }`.
- Errors: `400` bad status · `401` no auth · `403` not the appointment's
  teacher, or no ACCEPTED appointment with the student, or either party
  soft-deleted · `404` appointment not found · `409` already recorded.
- Note: the legacy alias mount `app.use('/api/appointments', …)`
  (`app.ts:113`) exposes this same route without the `/v1` prefix.

### Read — `GET /api/v1/attendance?studentId=<id>`

Mounted in `app.ts:102` with `authenticate` + `standardLimiter`; the router
(`attendance.routes.ts`) applies `authenticate` again (harmless duplication).
There is no `authorize()` here — role logic lives in the service:

| Caller role | Behavior |
|---|---|
| `STUDENT` | May omit `studentId` (defaults to self). Requesting anyone else → `403`. |
| `TEACHER` | Must pass `studentId`; allowed only with an ACCEPTED appointment with that student. |
| `ADMIN` | Any student. |

Returns all of the student's records (no pagination), newest first, each with
`appointment.requestedDate/requestedTime/durationMinutes`.

## The write path in detail

`attendance.service.recordAttendance` (`packages/server/src/services/attendance.service.ts:38`):

1. **Ownership pre-flight** — the appointment must exist and its `teacherId`
   must equal the caller.
2. **Relationship guard** — `assertTeacherCanAccessStudent(teacherId,
   studentId)`: requires an `ACCEPTED` appointment between the pair and that
   neither user is soft-deleted. This is the same guard convention duplicated
   in the grades, recordings, memorization, revision, and export services
   (see CLAUDE.md — it is deliberately copied per service, not shared).
3. **Idempotency check** — an existing record for the appointment → `409`.
4. **Transaction** — `prisma.$transaction` creates the `SessionRecord` and
   sets `Appointment.status = 'COMPLETED'`. This coupling is the core
   invariant: *recording attendance is what completes a session.*
5. **Notification** — after commit, `notifyUser({ event:
   'attendance_recorded', … })` sends the student a push notification and a
   durable in-app feed row. Every channel inside `notifyUser`
   (`notification.service.ts:15`) is individually try/caught, so a
   notification failure is logged but can never fail the request or roll back
   the attendance record.

Subtlety: the transaction flips the appointment to `COMPLETED` regardless of
its prior status — the service checks ownership but not that this specific
appointment was `ACCEPTED`. The relationship guard only requires *some*
ACCEPTED appointment between the pair, so with multiple appointments between
the same teacher and student, attendance can be recorded against one still in
`REQUESTED` state.

## Downstream consumers

- **Parent dashboard** — `parent.service.getChildDashboard` includes the
  child's 5 most recent `SessionRecord`s (gated by an APPROVED `ParentLink`,
  a guard chain independent of the teacher/student one).
- **Admin analytics** — `analytics.service` counts
  `sessionRecordsAsTeacher` in the last 30 days per teacher
  ("sessions last 30d") and treats a `SessionRecord` in the last 7 days as
  one of the signals for "weekly active students".

## Mobile client

`mobile/src/api/attendance.ts` exposes `attendanceApi.record(appointmentId,
status, notes?)` and `attendanceApi.list(studentId?)`, mapping 1:1 onto the
two endpoints.

⚠️ **Known gap:** none of the Axios client's interceptors (auth-header
injection, error-message normalization, 401 token refresh) unwrap response
envelopes, and `attendance.ts` returns `res.data` raw while typing it as
`SessionRecord`/`SessionRecord[]`. The server actually responds with
`{ success: true, data: … }`, so these functions return the envelope, not the
record — compare `parents.ts`, which defensively unwraps `res.data?.data`.
This has not bitten yet because **no hook or screen currently consumes
`attendanceApi`** — fix the unwrapping before building attendance UI.

## Testing

- `src/services/__tests__/attendance.service.test.ts` — 11 cases:
  `recordAttendance` (invalid status, missing appointment, wrong teacher,
  missing ACCEPTED appointment, duplicate record, transaction shape,
  notification row) and `getStudentAttendance` (all four role-authorization
  branches).
- `src/controllers/__tests__/attendance.controller.test.ts` — 9 cases:
  status validation (400), unauthenticated (401), the student-self fallback
  on list, and the teacher-must-pass-`studentId` rule.

Both use the global `jest-mock-extended` Prisma mock from
`src/__tests__/setup.ts`. Run them with:

```bash
cd packages/server && npm test -- --testPathPattern=attendance
```

## Extension checklist

Adding to attendance? Keep these invariants:

1. One `SessionRecord` per appointment — never relax the `@unique`.
2. Attendance recording completes the appointment; if you add another
   completion path, decide explicitly what happens to attendance.
3. Any new teacher-facing read/write must call
   `assertTeacherCanAccessStudent` (copy it into your service, per project
   convention).
4. New statuses go in three places: the Prisma enum (+ migration), the
   controller/service allow-lists, and the mobile `AttendanceStatus` type.
5. Notifications stay best-effort — never let them fail the write.
