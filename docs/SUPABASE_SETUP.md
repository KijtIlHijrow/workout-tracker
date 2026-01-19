# Supabase Setup Instructions

## Create Project

1. Go to https://supabase.com
2. Click "Start your project"
3. Sign in with GitHub
4. Click "New project"
5. Enter:
   - Name: "workout-tracker"
   - Database password: (generate strong password, save it)
   - Region: Choose closest to Malta (Europe West)
6. Click "Create new project"
7. Wait 2-3 minutes for provisioning

## Get Credentials

1. In Supabase dashboard, click "Settings" (gear icon)
2. Click "API" in sidebar
3. Copy these values:
   - Project URL (e.g., https://xxxxx.supabase.co)
   - Anon/Public key (starts with "eyJ...")
4. Save these - you'll add them to index.html

## Run Migration

1. In Supabase dashboard, click "SQL Editor"
2. Click "New query"
3. Paste contents of `migrations/001_initial_schema.sql`
4. Click "Run"
5. Verify: Click "Table Editor" - should see 3 tables

## Configure Auth

1. Click "Authentication" in sidebar
2. Click "Providers"
3. Enable "Email" provider
4. Configure email templates (optional, defaults work fine)
5. Click "Email Templates" to customize magic link email (optional)

Done! Use the Project URL and Anon key in index.html.
