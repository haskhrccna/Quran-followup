-- ============================================================
-- Quran Tutor — Seed data
--
-- BEFORE running this file:
--   1. Create the admin user in Supabase Auth dashboard
--      (Authentication → Users → Add user)
--   2. Copy the UUID of that user
--   3. Replace every occurrence of <ADMIN_UUID> below with it
--
-- Run in Supabase SQL editor AFTER running schema.sql
-- ============================================================

-- Insert admin profile
insert into public.profiles (id, name, email, role, status)
values (
  '<ADMIN_UUID>',
  'المدير',
  'admin@qurantutor.app',
  'admin',
  'approved'
);

-- Insert a test teacher invite code
insert into public.teacher_invites (code, created_by)
values ('TEACHER2024', '<ADMIN_UUID>');

-- Insert a second invite for testing reuse prevention
insert into public.teacher_invites (code, created_by)
values ('WELCOME2024', '<ADMIN_UUID>');
