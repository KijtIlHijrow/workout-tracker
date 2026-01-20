-- Remove unique constraint on exercise names to allow same exercise in different workout types
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_user_id_name_key;
