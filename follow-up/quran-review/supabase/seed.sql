-- Seed file for Quran Review app
-- This creates the initial admin user

-- Note: In Supabase, users are created through auth.users, not directly in profiles.
-- The admin user should be created through the Supabase dashboard or CLI.

-- To create admin via Supabase CLI:
-- supabase users create admin@quranreview.com --role admin

-- Or use the create-teacher edge function to create teacher accounts

-- Sample data for testing (uncomment after initial setup)

-- -- Create a sample teacher
-- INSERT INTO profiles (id, email, first_name, last_name, role, status)
-- VALUES (
--   '00000000-0000-0000-0000-000000000001',
--   'teacher@example.com',
--   'أحمد',
--   'المعلم',
--   'teacher',
--   'active'
-- );

-- -- Create a sample student (pending approval)
-- INSERT INTO profiles (id, email, first_name, last_name, role, status)
-- VALUES (
--   '00000000-0000-0000-0000-000000000002',
--   'student@example.com',
--   'محمد',
--   'الطالب',
--   'student',
--   'pending'
-- );

-- -- Assign student to teacher
-- INSERT INTO student_teacher_assignments (student_id, teacher_id, assigned_by)
-- VALUES (
--   '00000000-0000-0000-0000-000000000002',
--   '00000000-0000-0000-0000-000000000001',
--   '00000000-0000-0000-0000-000000000001'
-- );

-- Update the status of the student after assignment
-- UPDATE profiles SET status = 'active' WHERE id = '00000000-0000-0000-0000-000000000002';

-- To use this seed file:
-- 1. Create the users in Supabase Auth dashboard
-- 2. Copy their UUIDs
-- 3. Update the seed file with the correct UUIDs
-- 4. Run: supabase db seed --db-url=your-database-url