-- Create users table extension (Supabase has auth.users, we just reference it)

-- Workout schedule table
CREATE TABLE workout_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  workout_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, day_of_week)
);

-- Exercises table
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  workout_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- Sets table
CREATE TABLE sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE NOT NULL,
  weight NUMERIC(5,1) NOT NULL CHECK (weight > 0),
  reps INTEGER NOT NULL CHECK (reps > 0),
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_sets_logged_at ON sets(logged_at DESC);
CREATE INDEX idx_sets_exercise_id ON sets(exercise_id);
CREATE INDEX idx_sets_user_id ON sets(user_id);
CREATE INDEX idx_exercises_user_workout ON exercises(user_id, workout_type);

-- Row Level Security (RLS) Policies
ALTER TABLE workout_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE sets ENABLE ROW LEVEL SECURITY;

-- Users can only see/modify their own data
CREATE POLICY "Users can view own schedule" ON workout_schedule
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own schedule" ON workout_schedule
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own schedule" ON workout_schedule
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own schedule" ON workout_schedule
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own exercises" ON exercises
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own exercises" ON exercises
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own exercises" ON exercises
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own exercises" ON exercises
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own sets" ON sets
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sets" ON sets
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sets" ON sets
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sets" ON sets
  FOR DELETE USING (auth.uid() = user_id);
