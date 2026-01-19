# Workout Tracker Design

**Date:** 2026-01-19
**Type:** Mobile-first HTML workout logger with Supabase backend

## Overview

Single HTML file workout tracker optimized for iPhone gym usage. Priority: quick loading and convenience. Uses Supabase (free tier) for data persistence with magic link auth.

## Core Requirements

- Quick set logging: exercise name, weight (kg), reps
- Pre-assigned workout schedule (day of week → workout type)
- Exercise library filtered by workout type
- Magic link authentication for data persistence
- Single user (personal use)

## Architecture

**Approach:** Single HTML file with inline CSS/JS
- No build step required
- Instant page load
- Supabase JS client via CDN (~50KB)
- Mobile-first responsive design
- Offline-capable with localStorage cache + Supabase sync

**Alternative considered:** PWA with service worker - rejected for simplicity. Single file is faster to build and sufficient.

## Data Model

### Supabase Tables

**workout_schedule**
- `day_of_week` (integer 0-6, Sunday=0)
- `workout_type` (text: "Push", "Pull", "Legs", etc.)
- `user_id` (uuid, foreign key)

**exercises**
- `id` (uuid, primary key)
- `name` (text)
- `workout_type` (text)
- `user_id` (uuid, foreign key)
- `created_at` (timestamp)

**sets**
- `id` (uuid, primary key)
- `exercise_id` (uuid, foreign key)
- `weight` (numeric, in kg)
- `reps` (integer)
- `logged_at` (timestamp with timezone)
- `user_id` (uuid, foreign key)

### Indexes
- `sets.logged_at` (for history queries)
- `sets.exercise_id` (for exercise stats)
- `exercises.user_id, exercises.workout_type` (for filtering)

## UI/UX Design

### Main Screen
- **Header:** Today's workout type badge (e.g., "PUSH DAY - Monday")
- **Exercise list:** Filtered to today's workout type
  - Large tap targets (min 44px for iOS)
  - Shows exercise name + last logged weight/reps
- **Tap exercise:** Opens modal with number inputs
  - Weight (kg) - iOS numeric keyboard
  - Reps
  - Tab order: weight → reps → save button
  - Large "Log Set" button
- **Submit:** Instant save + close modal, return to list

### Secondary Screens
- **Settings:** Edit weekly schedule (assign workout types to days)
- **Manage Exercises:** Add/edit/delete exercises by workout type
- **History:** Calendar view of past workouts with set details

### Visual Style
- Minimal design, high contrast
- Large text (16px+ minimum)
- Gym lighting friendly (works in bright/dim conditions)
- Dark mode support

## Technical Implementation

### Libraries (CDN)
- Supabase JS client
- Vanilla JavaScript (no framework)
- Custom CSS (~2-3KB)

### Performance Optimizations
- Lazy load history/settings screens
- Cache exercise list in localStorage
- Optimistic UI updates (show immediately, sync in background)
- Prefetch today's exercises on page load
- Sync status indicator (green dot=synced, yellow=pending)

### Supabase Configuration
- Free tier: 500MB database, 2GB bandwidth/month
- Row Level Security (RLS) policies per user
- Realtime subscriptions disabled (not needed)
- Magic link authentication (passwordless)

### Authentication Flow
1. User enters email
2. Supabase sends magic link
3. Click link → authenticated
4. Session persists in localStorage

## Error Handling

### Network Failures
- Queue failed requests in localStorage
- Auto-retry on reconnect
- Show sync status indicator

### Data Conflicts
- Timestamp-based resolution
- Server always wins (unlikely conflicts with single user)

### Validation
- Weight/reps must be positive numbers
- Exercise names required (no duplicates per user)
- Workout types required

### Empty States
- No exercises → "Add your first exercise" prompt
- No schedule → Quick setup wizard on first launch
- No sets logged today → Motivational message

### Loading States
- Skeleton screens during fetch
- Cached data displays immediately
- Updates when fresh data loads

## Setup & Deployment

### Initial Setup
1. Create Supabase project (free tier)
2. Run SQL migration to create tables
3. Configure RLS policies
4. Add Supabase URL + anon key to HTML

### Deployment Options
- GitHub Pages (free)
- Netlify/Vercel (free tier)
- Self-host (single HTML file)

### First Run Experience
1. Magic link authentication
2. Quick wizard: "Set your weekly schedule"
3. "Add your exercises for each workout type"
4. Ready to log sets

## Future Enhancements (YAGNI - not included in v1)
- Rest timer between sets
- Progress charts/graphs
- Exercise form videos
- Workout templates
- Social sharing
- Multiple users

## Success Criteria
- Page loads in <1 second on 4G
- Can log a set in 3 taps (exercise → weight → reps → save)
- Works offline with sync queue
- No data loss between sessions
- Mobile keyboard doesn't cover inputs
