-- ============================================================
-- Quran Tutor — Supabase schema
-- Run once in the Supabase SQL editor (Database → SQL Editor)
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- Tables
-- ============================================================

-- Profiles (mirrors auth.users 1-to-1)
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  name            text not null,
  email           text,
  phone           text,
  age             int,
  avatar_url      text,
  role            text not null default 'student'
                    check (role in ('student', 'teacher', 'admin')),
  status          text not null default 'pending'
                    check (status in ('pending', 'approved', 'rejected', 'suspended')),
  preferred_level text,
  bio             text,
  teacher_id      uuid references public.profiles(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz
);

-- Teacher invite codes (admin creates, teacher consumes on signup)
create table public.teacher_invites (
  id         uuid primary key default uuid_generate_v4(),
  code       text not null unique,
  used       boolean not null default false,
  used_by    uuid references public.profiles(id),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- Teacher–student assignments
create table public.teacher_students (
  teacher_id  uuid not null references public.profiles(id) on delete cascade,
  student_id  uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (teacher_id, student_id)
);

-- Sessions
create table public.sessions (
  id            uuid primary key default uuid_generate_v4(),
  teacher_id    uuid not null references public.profiles(id),
  student_id    uuid not null references public.profiles(id),
  scheduled_at  timestamptz not null,
  duration_min  int not null default 60,
  status        text not null default 'scheduled'
                  check (status in ('scheduled', 'in_progress', 'completed', 'cancelled', 'rescheduled')),
  notes         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz
);

-- Progress records (grading per session)
create table public.progress_records (
  id           uuid primary key default uuid_generate_v4(),
  session_id   uuid not null references public.sessions(id) on delete cascade,
  student_id   uuid not null references public.profiles(id),
  teacher_id   uuid not null references public.profiles(id),
  memorization int check (memorization between 1 and 5),
  tajweed      int check (tajweed between 1 and 5),
  mastery      int check (mastery between 1 and 5),
  consistency  int check (consistency between 1 and 5),
  notes        text,
  created_at   timestamptz not null default now()
);

-- Notifications
create table public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       text not null,
  title      text not null,
  body       text,
  read       boolean not null default false,
  payload    jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Triggers — auto-set updated_at
-- ============================================================

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger trg_sessions_updated_at
  before update on public.sessions
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.profiles         enable row level security;
alter table public.teacher_invites  enable row level security;
alter table public.teacher_students enable row level security;
alter table public.sessions         enable row level security;
alter table public.progress_records enable row level security;
alter table public.notifications    enable row level security;

-- Helper: is current user an admin?
create or replace function public.is_admin()
returns boolean language sql security definer as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- profiles
create policy "profiles: own row"
  on public.profiles for all
  using (auth.uid() = id);

create policy "profiles: admin read all"
  on public.profiles for select
  using (public.is_admin());

create policy "profiles: admin update all"
  on public.profiles for update
  using (public.is_admin());

-- teacher_invites: admins manage; anyone can read to validate code at signup
create policy "invites: admin manage"
  on public.teacher_invites for all
  using (public.is_admin());

create policy "invites: read for signup"
  on public.teacher_invites for select
  using (true);

-- teacher_students
create policy "teacher_students: read own"
  on public.teacher_students for select
  using (auth.uid() = teacher_id or auth.uid() = student_id);

create policy "teacher_students: admin all"
  on public.teacher_students for all
  using (public.is_admin());

-- sessions
create policy "sessions: read own"
  on public.sessions for select
  using (auth.uid() = teacher_id or auth.uid() = student_id);

create policy "sessions: teacher insert"
  on public.sessions for insert
  with check (auth.uid() = teacher_id);

create policy "sessions: teacher update"
  on public.sessions for update
  using (auth.uid() = teacher_id);

create policy "sessions: admin all"
  on public.sessions for all
  using (public.is_admin());

-- progress_records
create policy "progress: teacher insert"
  on public.progress_records for insert
  with check (auth.uid() = teacher_id);

create policy "progress: read own"
  on public.progress_records for select
  using (auth.uid() = student_id or auth.uid() = teacher_id);

create policy "progress: admin all"
  on public.progress_records for all
  using (public.is_admin());

-- notifications
create policy "notifications: own"
  on public.notifications for all
  using (auth.uid() = user_id);
