-- Recordings/Files table
CREATE TABLE recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size BIGINT,
  description TEXT,
  reviewed BOOLEAN DEFAULT FALSE,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT,
  message_type message_type NOT NULL DEFAULT 'text',
  file_url TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_recordings_student_id ON recordings(student_id);
CREATE INDEX idx_recordings_teacher_id ON recordings(teacher_id);
CREATE INDEX idx_recordings_reviewed ON recordings(reviewed);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Enable RLS
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE recordings IS 'Student audio/video/document uploads for teacher review';
COMMENT ON TABLE messages IS 'Direct messages between users';

-- =====================
-- ROW LEVEL SECURITY POLICIES
-- =====================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Teachers can view assigned students" ON profiles FOR SELECT USING (EXISTS (SELECT 1 FROM student_teacher_assignments WHERE teacher_id = auth.uid() AND student_id = profiles.id AND is_active = TRUE));
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any profile" ON profiles FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can insert profiles" ON profiles FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Appointments policies
CREATE POLICY "Students can view own appointments" ON appointments FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view own appointments" ON appointments FOR SELECT USING (teacher_id = auth.uid());
CREATE POLICY "Admins can view all appointments" ON appointments FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Students can create appointments" ON appointments FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Teachers can update own appointments" ON appointments FOR UPDATE USING (teacher_id = auth.uid());
CREATE POLICY "Admins can update any appointment" ON appointments FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users can delete own appointments" ON appointments FOR DELETE USING (student_id = auth.uid() OR teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Grades policies
CREATE POLICY "Students can view own grades" ON grades FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view manage grades" ON grades FOR ALL USING (teacher_id = auth.uid());
CREATE POLICY "Admins can view all grades" ON grades FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Students can delete own grades" ON grades FOR DELETE USING (student_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Recordings policies
CREATE POLICY "Students can view own recordings" ON recordings FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view own recordings" ON recordings FOR SELECT USING (teacher_id = auth.uid());
CREATE POLICY "Admins can view all recordings" ON recordings FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Students can upload recordings" ON recordings FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Teachers can update own recordings" ON recordings FOR UPDATE USING (teacher_id = auth.uid());
CREATE POLICY "Admins can update any recording" ON recordings FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Teachers can delete own recordings" ON recordings FOR DELETE USING (teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Messages policies
CREATE POLICY "Users can view own messages" ON messages FOR SELECT USING (sender_id = auth.uid() OR receiver_id = auth.uid());
CREATE POLICY "Admins can view all messages" ON messages FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY "Users can update own messages" ON messages FOR UPDATE USING (sender_id = auth.uid() OR receiver_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Student-Teacher assignments policies
CREATE POLICY "Users can view own assignments" ON student_teacher_assignments FOR SELECT USING (student_id = auth.uid() OR teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can manage assignments" ON student_teacher_assignments FOR ALL USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Reports policies
CREATE POLICY "Students can view own reports" ON reports FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can manage reports" ON reports FOR ALL USING (teacher_id = auth.uid());
CREATE POLICY "Admins can view all reports" ON reports FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Broadcast messages policies
CREATE POLICY "Admins can manage broadcasts" ON broadcast_messages FOR ALL USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "All users can view broadcasts" ON broadcast_messages FOR SELECT USING (TRUE);

-- =====================
-- STORAGE BUCKETS
-- =====================

INSERT INTO storage.buckets (id, name, public) VALUES ('recordings', 'recordings', false);
INSERT INTO storage.buckets (id, name, public) VALUES ('report-pdfs', 'report-pdfs', false);
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('message-attachments', 'message-attachments', false);

-- Storage policies
CREATE POLICY "Students can upload to own recording folder" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'recordings' AND (storage.foldername(auth.uid()))[1] = auth.uid()::text);
CREATE POLICY "Users can read own recordings" ON storage.objects FOR SELECT USING (bucket_id = 'recordings' AND (storage.foldername(auth.uid()))[1] = auth.uid()::text);
CREATE POLICY "Teachers can read student recordings" ON storage.objects FOR SELECT USING (bucket_id = 'recordings' AND EXISTS (SELECT 1 FROM profiles WHERE role = 'teacher' AND id = auth.uid()));
CREATE POLICY "Teachers can delete student recordings" ON storage.objects FOR DELETE USING (bucket_id = 'recordings' AND EXISTS (SELECT 1 FROM profiles WHERE role = 'teacher' AND id = auth.uid()));

CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(auth.uid()))[1]);
CREATE POLICY "Users can read avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(auth.uid()))[1]);

CREATE POLICY "Teachers can upload reports" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'report-pdfs' AND EXISTS (SELECT 1 FROM profiles WHERE role = 'teacher' AND id = auth.uid()));
CREATE POLICY "Students can read own reports" ON storage.objects FOR SELECT USING (bucket_id = 'report-pdfs' AND EXISTS (SELECT 1 FROM profiles WHERE role = 'student' AND id = auth.uid()));
CREATE POLICY "Admins can read all reports" ON storage.objects FOR SELECT USING (bucket_id = 'report-pdfs' AND EXISTS (SELECT 1 FROM profiles WHERE role = 'admin' AND id = auth.uid()));

-- =====================
-- FUNCTIONS & TRIGGERS
-- =====================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user auto-profile creation is handled by Supabase

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();