# Workout Tracker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a mobile-first single HTML workout tracker with Supabase backend for logging sets (exercise, weight in kg, reps) with pre-assigned weekly workout schedule.

**Architecture:** Single HTML file with inline CSS/JS, Supabase for persistence, magic link auth, localStorage cache with background sync, optimistic UI updates.

**Tech Stack:** Vanilla JS, Supabase JS SDK (CDN), CSS Grid/Flexbox, iOS-optimized inputs

---

## Task 1: Supabase Project Setup

**Files:**
- Create: `docs/SUPABASE_SETUP.md`
- Create: `migrations/001_initial_schema.sql`

**Step 1: Document Supabase setup instructions**

Create setup documentation:

```markdown
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
```

**Step 2: Create SQL migration**

Create migration file:

```sql
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
```

**Step 3: Commit setup files**

```bash
git add docs/SUPABASE_SETUP.md migrations/001_initial_schema.sql
git commit -m "docs: add Supabase setup and initial migration

- Setup instructions for creating Supabase project
- SQL migration with tables, indexes, and RLS policies"
```

---

## Task 2: HTML Structure and Base Styles

**Files:**
- Create: `index.html`

**Step 1: Create HTML skeleton with CDN imports**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <title>Workout Tracker</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <style>
    /* CSS will go here in next step */
  </style>
</head>
<body>
  <!-- Screens -->
  <div id="auth-screen" class="screen">
    <!-- Auth UI -->
  </div>

  <div id="onboarding-screen" class="screen hidden">
    <!-- First-run setup -->
  </div>

  <div id="main-screen" class="screen hidden">
    <!-- Main workout logging -->
  </div>

  <div id="settings-screen" class="screen hidden">
    <!-- Settings -->
  </div>

  <div id="exercises-screen" class="screen hidden">
    <!-- Manage exercises -->
  </div>

  <div id="history-screen" class="screen hidden">
    <!-- Workout history -->
  </div>

  <!-- Modals -->
  <div id="log-set-modal" class="modal hidden">
    <!-- Log set form -->
  </div>

  <script>
    // Configuration - REPLACE WITH YOUR SUPABASE CREDENTIALS
    const SUPABASE_URL = 'YOUR_SUPABASE_URL_HERE';
    const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY_HERE';

    // JavaScript will go here in next steps
  </script>
</body>
</html>
```

**Step 2: Add mobile-optimized CSS**

Add inside `<style>` tag:

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --primary: #2563eb;
  --primary-dark: #1d4ed8;
  --success: #10b981;
  --danger: #ef4444;
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-700: #374151;
  --gray-900: #111827;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: 16px;
  line-height: 1.5;
  color: var(--gray-900);
  background: var(--gray-50);
  -webkit-font-smoothing: antialiased;
  padding-bottom: env(safe-area-inset-bottom);
}

.screen {
  min-height: 100vh;
  padding: 20px;
  padding-top: max(20px, env(safe-area-inset-top));
}

.hidden {
  display: none !important;
}

/* Headers */
h1 {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
}

h2 {
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 16px;
}

/* Buttons */
.btn {
  display: block;
  width: 100%;
  padding: 16px;
  font-size: 16px;
  font-weight: 600;
  text-align: center;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
}

.btn-primary {
  background: var(--primary);
  color: white;
}

.btn-primary:active {
  background: var(--primary-dark);
  transform: scale(0.98);
}

.btn-secondary {
  background: var(--gray-100);
  color: var(--gray-900);
}

.btn-secondary:active {
  background: var(--gray-200);
}

/* Inputs */
input {
  display: block;
  width: 100%;
  padding: 16px;
  font-size: 16px;
  border: 2px solid var(--gray-200);
  border-radius: 12px;
  margin-bottom: 12px;
  -webkit-appearance: none;
}

input:focus {
  outline: none;
  border-color: var(--primary);
}

/* Lists */
.exercise-list {
  margin: 20px 0;
}

.exercise-item {
  background: white;
  padding: 20px;
  margin-bottom: 12px;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}

.exercise-item:active {
  transform: scale(0.98);
  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
}

.exercise-name {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 4px;
}

.exercise-last {
  font-size: 14px;
  color: var(--gray-700);
}

/* Modal */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 24px;
  border-radius: 16px;
  width: 100%;
  max-width: 400px;
}

.modal-header {
  font-size: 20px;
  font-weight: 600;
  margin-bottom: 20px;
}

/* Badge */
.badge {
  display: inline-block;
  padding: 8px 16px;
  background: var(--primary);
  color: white;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 20px;
}

/* Sync status */
.sync-status {
  position: fixed;
  top: 20px;
  right: 20px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--success);
  z-index: 100;
}

.sync-status.pending {
  background: #f59e0b;
}

/* Navigation */
.nav-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  border-top: 1px solid var(--gray-200);
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  padding-bottom: env(safe-area-inset-bottom);
}

.nav-item {
  padding: 12px;
  text-align: center;
  font-size: 12px;
  cursor: pointer;
  border: none;
  background: none;
  color: var(--gray-700);
}

.nav-item.active {
  color: var(--primary);
  font-weight: 600;
}
```

**Step 3: Commit HTML structure**

```bash
git add index.html
git commit -m "feat: add HTML structure and mobile styles

- Mobile-first responsive layout
- iOS-optimized inputs and tap targets
- Screen and modal structure
- CDN import for Supabase client"
```

---

## Task 3: Supabase Client and Auth

**Files:**
- Modify: `index.html` (add to `<script>` section)

**Step 1: Initialize Supabase client**

Add after configuration constants:

```javascript
// Initialize Supabase
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Global state
const state = {
  user: null,
  exercises: [],
  schedule: [],
  syncQueue: [],
  lastStats: {}
};

// Initialize app
document.addEventListener('DOMContentLoaded', async () => {
  // Check for existing session
  const { data: { session } } = await supabase.auth.getSession();

  if (session) {
    state.user = session.user;
    await initializeApp();
  } else {
    showScreen('auth-screen');
  }

  // Listen for auth changes
  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN') {
      state.user = session.user;
      initializeApp();
    } else if (event === 'SIGNED_OUT') {
      state.user = null;
      showScreen('auth-screen');
    }
  });
});

// Screen navigation
function showScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
  document.getElementById(screenId).classList.remove('hidden');
}

// Show/hide modal
function showModal(modalId) {
  document.getElementById(modalId).classList.remove('hidden');
}

function hideModal(modalId) {
  document.getElementById(modalId).classList.add('hidden');
}
```

**Step 2: Build auth UI**

Update `#auth-screen` div:

```html
<div id="auth-screen" class="screen">
  <h1>Workout Tracker</h1>
  <p style="color: var(--gray-700); margin-bottom: 32px;">
    Track your sets with ease. Sign in to get started.
  </p>

  <input
    type="email"
    id="auth-email"
    placeholder="your@email.com"
    autocomplete="email"
  />

  <button class="btn btn-primary" onclick="handleAuth()">
    Send Magic Link
  </button>

  <div id="auth-message" style="margin-top: 16px; text-align: center;"></div>
</div>
```

**Step 3: Implement auth functions**

Add to script section:

```javascript
async function handleAuth() {
  const email = document.getElementById('auth-email').value.trim();
  const messageEl = document.getElementById('auth-message');

  if (!email) {
    messageEl.innerHTML = '<span style="color: var(--danger);">Please enter your email</span>';
    return;
  }

  messageEl.innerHTML = '<span style="color: var(--gray-700);">Sending magic link...</span>';

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: window.location.href
    }
  });

  if (error) {
    messageEl.innerHTML = `<span style="color: var(--danger);">${error.message}</span>`;
  } else {
    messageEl.innerHTML = '<span style="color: var(--success);">Check your email for the magic link!</span>';
  }
}
```

**Step 4: Test auth flow**

Manual testing:
1. Open index.html in browser
2. Enter email address
3. Click "Send Magic Link"
4. Expected: "Check your email" message
5. Check email, click magic link
6. Expected: Redirects back, should call `initializeApp()`

**Step 5: Commit auth implementation**

```bash
git add index.html
git commit -m "feat: implement magic link authentication

- Supabase client initialization
- Auth UI with email input
- Magic link sending
- Session persistence
- Auth state listener"
```

---

## Task 4: First-Run Onboarding

**Files:**
- Modify: `index.html`

**Step 1: Add onboarding UI**

Update `#onboarding-screen`:

```html
<div id="onboarding-screen" class="screen hidden">
  <h1>Welcome!</h1>
  <p style="color: var(--gray-700); margin-bottom: 24px;">
    Let's set up your weekly workout schedule.
  </p>

  <div id="schedule-setup">
    <div class="schedule-day" data-day="1">
      <label>Monday</label>
      <input type="text" placeholder="e.g., Push" />
    </div>
    <div class="schedule-day" data-day="2">
      <label>Tuesday</label>
      <input type="text" placeholder="e.g., Pull" />
    </div>
    <div class="schedule-day" data-day="3">
      <label>Wednesday</label>
      <input type="text" placeholder="e.g., Legs" />
    </div>
    <div class="schedule-day" data-day="4">
      <label>Thursday</label>
      <input type="text" placeholder="e.g., Push" />
    </div>
    <div class="schedule-day" data-day="5">
      <label>Friday</label>
      <input type="text" placeholder="e.g., Pull" />
    </div>
    <div class="schedule-day" data-day="6">
      <label>Saturday</label>
      <input type="text" placeholder="e.g., Legs" />
    </div>
    <div class="schedule-day" data-day="0">
      <label>Sunday</label>
      <input type="text" placeholder="Rest day" />
    </div>
  </div>

  <button class="btn btn-primary" onclick="saveSchedule()" style="margin-top: 24px;">
    Continue
  </button>
</div>
```

Add CSS for schedule setup:

```css
.schedule-day {
  margin-bottom: 16px;
}

.schedule-day label {
  display: block;
  font-weight: 600;
  margin-bottom: 4px;
  color: var(--gray-700);
}
```

**Step 2: Implement onboarding logic**

Add to script section:

```javascript
async function initializeApp() {
  // Check if user has schedule
  const { data: schedule } = await supabase
    .from('workout_schedule')
    .select('*')
    .eq('user_id', state.user.id);

  if (!schedule || schedule.length === 0) {
    showScreen('onboarding-screen');
  } else {
    state.schedule = schedule;
    await loadExercises();
    await loadLastStats();
    showMainScreen();
  }
}

async function saveSchedule() {
  const days = document.querySelectorAll('.schedule-day');
  const scheduleData = [];

  days.forEach(day => {
    const dayNum = parseInt(day.dataset.day);
    const input = day.querySelector('input');
    const workoutType = input.value.trim();

    if (workoutType) {
      scheduleData.push({
        user_id: state.user.id,
        day_of_week: dayNum,
        workout_type: workoutType
      });
    }
  });

  if (scheduleData.length === 0) {
    alert('Please add at least one workout day');
    return;
  }

  const { error } = await supabase
    .from('workout_schedule')
    .insert(scheduleData);

  if (error) {
    alert('Error saving schedule: ' + error.message);
    return;
  }

  state.schedule = scheduleData;
  showScreen('exercises-screen');
  renderExerciseManager();
}
```

**Step 3: Commit onboarding**

```bash
git add index.html
git commit -m "feat: add first-run onboarding for schedule setup

- Weekly schedule configuration UI
- Save schedule to Supabase
- Check for existing schedule on app init"
```

---

## Task 5: Main Workout Screen

**Files:**
- Modify: `index.html`

**Step 1: Build main screen UI**

Update `#main-screen`:

```html
<div id="main-screen" class="screen hidden">
  <div class="sync-status" id="sync-indicator"></div>

  <div id="today-header">
    <!-- Populated by JS -->
  </div>

  <div id="exercise-list" class="exercise-list">
    <!-- Populated by JS -->
  </div>

  <div class="nav-bar">
    <button class="nav-item active" onclick="showMainScreen()">
      Workout
    </button>
    <button class="nav-item" onclick="showScreen('exercises-screen'); renderExerciseManager();">
      Exercises
    </button>
    <button class="nav-item" onclick="showScreen('settings-screen'); renderSettings();">
      Settings
    </button>
  </div>
</div>
```

**Step 2: Build log set modal**

Update `#log-set-modal`:

```html
<div id="log-set-modal" class="modal hidden" onclick="if(event.target === this) hideModal('log-set-modal')">
  <div class="modal-content">
    <div class="modal-header" id="modal-exercise-name"></div>

    <label style="display: block; font-weight: 600; margin-bottom: 4px;">Weight (kg)</label>
    <input
      type="number"
      id="set-weight"
      inputmode="decimal"
      step="0.5"
      placeholder="0"
      autofocus
    />

    <label style="display: block; font-weight: 600; margin-bottom: 4px;">Reps</label>
    <input
      type="number"
      id="set-reps"
      inputmode="numeric"
      placeholder="0"
    />

    <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 12px; margin-top: 20px;">
      <button class="btn btn-secondary" onclick="hideModal('log-set-modal')">
        Cancel
      </button>
      <button class="btn btn-primary" onclick="saveSet()">
        Log Set
      </button>
    </div>
  </div>
</div>
```

**Step 3: Implement main screen logic**

Add to script:

```javascript
async function loadExercises() {
  const { data, error } = await supabase
    .from('exercises')
    .select('*')
    .eq('user_id', state.user.id)
    .order('name');

  if (!error) {
    state.exercises = data || [];
  }
}

async function loadLastStats() {
  // Get last logged set for each exercise
  const { data } = await supabase
    .from('sets')
    .select('exercise_id, weight, reps, logged_at')
    .eq('user_id', state.user.id)
    .order('logged_at', { ascending: false });

  if (data) {
    const stats = {};
    data.forEach(set => {
      if (!stats[set.exercise_id]) {
        stats[set.exercise_id] = { weight: set.weight, reps: set.reps };
      }
    });
    state.lastStats = stats;
  }
}

function showMainScreen() {
  showScreen('main-screen');
  renderMainScreen();
}

function renderMainScreen() {
  const today = new Date().getDay(); // 0 = Sunday
  const todaySchedule = state.schedule.find(s => s.day_of_week === today);

  // Render header
  const headerEl = document.getElementById('today-header');
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  if (todaySchedule) {
    headerEl.innerHTML = `
      <div class="badge">${todaySchedule.workout_type.toUpperCase()} - ${dayNames[today]}</div>
    `;
  } else {
    headerEl.innerHTML = `
      <div class="badge" style="background: var(--gray-700);">REST DAY - ${dayNames[today]}</div>
    `;
  }

  // Filter exercises for today
  const todayExercises = todaySchedule
    ? state.exercises.filter(ex => ex.workout_type === todaySchedule.workout_type)
    : [];

  // Render exercise list
  const listEl = document.getElementById('exercise-list');

  if (todayExercises.length === 0) {
    listEl.innerHTML = `
      <p style="text-align: center; color: var(--gray-700); margin-top: 40px;">
        ${todaySchedule ? 'No exercises yet. Add some in the Exercises tab.' : 'Enjoy your rest day!'}
      </p>
    `;
    return;
  }

  listEl.innerHTML = todayExercises.map(ex => {
    const last = state.lastStats[ex.id];
    return `
      <div class="exercise-item" onclick="openLogModal('${ex.id}', '${ex.name}')">
        <div class="exercise-name">${ex.name}</div>
        ${last ? `<div class="exercise-last">Last: ${last.weight}kg × ${last.reps}</div>` : ''}
      </div>
    `;
  }).join('');
}

let currentExerciseId = null;

function openLogModal(exerciseId, exerciseName) {
  currentExerciseId = exerciseId;
  document.getElementById('modal-exercise-name').textContent = exerciseName;

  // Pre-fill with last values
  const last = state.lastStats[exerciseId];
  if (last) {
    document.getElementById('set-weight').value = last.weight;
    document.getElementById('set-reps').value = last.reps;
  } else {
    document.getElementById('set-weight').value = '';
    document.getElementById('set-reps').value = '';
  }

  showModal('log-set-modal');

  // Focus weight input after modal opens
  setTimeout(() => {
    document.getElementById('set-weight').focus();
  }, 100);
}

async function saveSet() {
  const weight = parseFloat(document.getElementById('set-weight').value);
  const reps = parseInt(document.getElementById('set-reps').value);

  if (!weight || weight <= 0 || !reps || reps <= 0) {
    alert('Please enter valid weight and reps');
    return;
  }

  const setData = {
    user_id: state.user.id,
    exercise_id: currentExerciseId,
    weight,
    reps,
    logged_at: new Date().toISOString()
  };

  // Optimistic update
  state.lastStats[currentExerciseId] = { weight, reps };
  updateSyncStatus('pending');

  hideModal('log-set-modal');
  renderMainScreen();

  // Save to Supabase
  const { error } = await supabase
    .from('sets')
    .insert(setData);

  if (error) {
    console.error('Error saving set:', error);
    // Add to sync queue for retry
    state.syncQueue.push({ type: 'set', data: setData });
    localStorage.setItem('syncQueue', JSON.stringify(state.syncQueue));
  } else {
    updateSyncStatus('synced');
  }
}

function updateSyncStatus(status) {
  const indicator = document.getElementById('sync-indicator');
  if (status === 'synced') {
    indicator.classList.remove('pending');
  } else {
    indicator.classList.add('pending');
  }
}
```

**Step 4: Test main screen flow**

Manual testing:
1. Complete onboarding
2. Add an exercise (next task)
3. Go to main screen
4. Expected: See today's workout type
5. Click exercise
6. Expected: Modal opens with number inputs
7. Enter weight and reps
8. Click "Log Set"
9. Expected: Modal closes, last set shows under exercise

**Step 5: Commit main screen**

```bash
git add index.html
git commit -m "feat: implement main workout logging screen

- Display today's workout type
- Filter exercises by workout type
- Log set modal with weight/reps inputs
- Optimistic UI updates
- Sync status indicator
- Last set display per exercise"
```

---

## Task 6: Exercise Management

**Files:**
- Modify: `index.html`

**Step 1: Build exercise manager UI**

Update `#exercises-screen`:

```html
<div id="exercises-screen" class="screen hidden">
  <h2>Manage Exercises</h2>

  <div id="exercise-groups">
    <!-- Populated by JS -->
  </div>

  <div style="margin-top: 24px;">
    <h3 style="font-size: 18px; margin-bottom: 12px;">Add Exercise</h3>
    <input type="text" id="new-exercise-name" placeholder="Exercise name" />
    <select id="new-exercise-type" style="display: block; width: 100%; padding: 16px; font-size: 16px; border: 2px solid var(--gray-200); border-radius: 12px; margin-bottom: 12px;">
      <!-- Populated by JS -->
    </select>
    <button class="btn btn-primary" onclick="addExercise()">Add Exercise</button>
  </div>

  <div class="nav-bar">
    <button class="nav-item" onclick="showMainScreen()">
      Workout
    </button>
    <button class="nav-item active">
      Exercises
    </button>
    <button class="nav-item" onclick="showScreen('settings-screen'); renderSettings();">
      Settings
    </button>
  </div>
</div>
```

**Step 2: Implement exercise manager**

Add to script:

```javascript
function renderExerciseManager() {
  // Get unique workout types from schedule
  const workoutTypes = [...new Set(state.schedule.map(s => s.workout_type))];

  // Populate workout type select
  const selectEl = document.getElementById('new-exercise-type');
  selectEl.innerHTML = workoutTypes.map(type =>
    `<option value="${type}">${type}</option>`
  ).join('');

  // Group exercises by workout type
  const groupsEl = document.getElementById('exercise-groups');

  if (state.exercises.length === 0) {
    groupsEl.innerHTML = '<p style="color: var(--gray-700);">No exercises yet. Add your first one below!</p>';
    return;
  }

  const grouped = {};
  state.exercises.forEach(ex => {
    if (!grouped[ex.workout_type]) grouped[ex.workout_type] = [];
    grouped[ex.workout_type].push(ex);
  });

  groupsEl.innerHTML = Object.entries(grouped).map(([type, exercises]) => `
    <div style="margin-bottom: 24px;">
      <h3 style="font-size: 16px; font-weight: 600; margin-bottom: 8px; color: var(--gray-700);">
        ${type}
      </h3>
      ${exercises.map(ex => `
        <div class="exercise-item" style="display: flex; justify-content: space-between; align-items: center;">
          <span>${ex.name}</span>
          <button
            onclick="deleteExercise('${ex.id}')"
            style="background: var(--danger); color: white; border: none; padding: 8px 12px; border-radius: 8px; font-size: 14px; cursor: pointer;"
          >
            Delete
          </button>
        </div>
      `).join('')}
    </div>
  `).join('');
}

async function addExercise() {
  const name = document.getElementById('new-exercise-name').value.trim();
  const workoutType = document.getElementById('new-exercise-type').value;

  if (!name) {
    alert('Please enter exercise name');
    return;
  }

  const { data, error } = await supabase
    .from('exercises')
    .insert({
      user_id: state.user.id,
      name,
      workout_type: workoutType
    })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') { // Unique constraint violation
      alert('Exercise already exists');
    } else {
      alert('Error adding exercise: ' + error.message);
    }
    return;
  }

  state.exercises.push(data);
  document.getElementById('new-exercise-name').value = '';
  renderExerciseManager();
}

async function deleteExercise(exerciseId) {
  if (!confirm('Delete this exercise? This will also delete all logged sets.')) {
    return;
  }

  const { error } = await supabase
    .from('exercises')
    .delete()
    .eq('id', exerciseId);

  if (error) {
    alert('Error deleting exercise: ' + error.message);
    return;
  }

  state.exercises = state.exercises.filter(ex => ex.id !== exerciseId);
  delete state.lastStats[exerciseId];
  renderExerciseManager();
}
```

**Step 3: Commit exercise management**

```bash
git add index.html
git commit -m "feat: add exercise management screen

- View exercises grouped by workout type
- Add new exercises with workout type
- Delete exercises with confirmation
- Auto-populate workout types from schedule"
```

---

## Task 7: Settings Screen

**Files:**
- Modify: `index.html`

**Step 1: Build settings UI**

Update `#settings-screen`:

```html
<div id="settings-screen" class="screen hidden">
  <h2>Settings</h2>

  <div id="schedule-editor">
    <!-- Populated by JS -->
  </div>

  <button class="btn btn-primary" onclick="updateSchedule()" style="margin-top: 24px;">
    Save Schedule
  </button>

  <button class="btn btn-secondary" onclick="handleSignOut()" style="margin-top: 12px;">
    Sign Out
  </button>

  <div class="nav-bar">
    <button class="nav-item" onclick="showMainScreen()">
      Workout
    </button>
    <button class="nav-item" onclick="showScreen('exercises-screen'); renderExerciseManager();">
      Exercises
    </button>
    <button class="nav-item active">
      Settings
    </button>
  </div>
</div>
```

**Step 2: Implement settings logic**

Add to script:

```javascript
function renderSettings() {
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const editorEl = document.getElementById('schedule-editor');

  editorEl.innerHTML = dayNames.map((dayName, dayNum) => {
    const existing = state.schedule.find(s => s.day_of_week === dayNum);
    return `
      <div class="schedule-day" data-day="${dayNum}">
        <label>${dayName}</label>
        <input type="text" placeholder="Rest day" value="${existing ? existing.workout_type : ''}" />
      </div>
    `;
  }).join('');
}

async function updateSchedule() {
  // Delete existing schedule
  await supabase
    .from('workout_schedule')
    .delete()
    .eq('user_id', state.user.id);

  // Collect new schedule
  const days = document.querySelectorAll('#schedule-editor .schedule-day');
  const scheduleData = [];

  days.forEach(day => {
    const dayNum = parseInt(day.dataset.day);
    const input = day.querySelector('input');
    const workoutType = input.value.trim();

    if (workoutType) {
      scheduleData.push({
        user_id: state.user.id,
        day_of_week: dayNum,
        workout_type: workoutType
      });
    }
  });

  if (scheduleData.length > 0) {
    const { error } = await supabase
      .from('workout_schedule')
      .insert(scheduleData);

    if (error) {
      alert('Error saving schedule: ' + error.message);
      return;
    }
  }

  state.schedule = scheduleData;
  alert('Schedule updated!');
  showMainScreen();
}

async function handleSignOut() {
  if (!confirm('Sign out?')) return;

  await supabase.auth.signOut();
  state.user = null;
  state.exercises = [];
  state.schedule = [];
  state.lastStats = {};
  showScreen('auth-screen');
}
```

**Step 3: Commit settings**

```bash
git add index.html
git commit -m "feat: add settings screen

- Edit weekly workout schedule
- Update schedule in database
- Sign out functionality
- Pre-fill existing schedule values"
```

---

## Task 8: Offline Support and Sync Queue

**Files:**
- Modify: `index.html`

**Step 1: Add sync queue processing**

Add to script (after `initializeApp` function):

```javascript
// Load sync queue from localStorage
function loadSyncQueue() {
  const queue = localStorage.getItem('syncQueue');
  if (queue) {
    state.syncQueue = JSON.parse(queue);
    if (state.syncQueue.length > 0) {
      processSyncQueue();
    }
  }
}

// Process pending sync queue
async function processSyncQueue() {
  if (state.syncQueue.length === 0) {
    updateSyncStatus('synced');
    return;
  }

  updateSyncStatus('pending');

  const queue = [...state.syncQueue];
  const failed = [];

  for (const item of queue) {
    if (item.type === 'set') {
      const { error } = await supabase
        .from('sets')
        .insert(item.data);

      if (error) {
        failed.push(item);
      }
    }
  }

  state.syncQueue = failed;
  localStorage.setItem('syncQueue', JSON.stringify(failed));

  if (failed.length === 0) {
    updateSyncStatus('synced');
  }
}

// Update initializeApp to load sync queue
// Modify existing initializeApp function to add this at the end:
async function initializeApp() {
  const { data: schedule } = await supabase
    .from('workout_schedule')
    .select('*')
    .eq('user_id', state.user.id);

  if (!schedule || schedule.length === 0) {
    showScreen('onboarding-screen');
  } else {
    state.schedule = schedule;
    await loadExercises();
    await loadLastStats();
    loadSyncQueue(); // ADD THIS LINE
    showMainScreen();
  }
}

// Retry sync on visibility change (app comes back to foreground)
document.addEventListener('visibilitychange', () => {
  if (!document.hidden && state.user) {
    processSyncQueue();
  }
});
```

**Step 2: Cache exercises in localStorage**

Add to `loadExercises` function:

```javascript
async function loadExercises() {
  // Try localStorage first
  const cached = localStorage.getItem('exercises');
  if (cached) {
    state.exercises = JSON.parse(cached);
  }

  // Fetch fresh from Supabase
  const { data, error } = await supabase
    .from('exercises')
    .select('*')
    .eq('user_id', state.user.id)
    .order('name');

  if (!error && data) {
    state.exercises = data;
    localStorage.setItem('exercises', JSON.stringify(data));
  }
}
```

Update `addExercise` and `deleteExercise` to update cache:

```javascript
// In addExercise, after state.exercises.push(data):
localStorage.setItem('exercises', JSON.stringify(state.exercises));

// In deleteExercise, after state.exercises = state.exercises.filter(...):
localStorage.setItem('exercises', JSON.stringify(state.exercises));
```

**Step 3: Test offline functionality**

Manual testing:
1. Log in and add some exercises
2. Open browser DevTools → Network tab
3. Set throttling to "Offline"
4. Try logging a set
5. Expected: Set appears in UI, sync indicator shows yellow
6. Re-enable network
7. Expected: Sync indicator turns green

**Step 4: Commit offline support**

```bash
git add index.html
git commit -m "feat: add offline support and sync queue

- Queue failed requests in localStorage
- Retry on app visibility change
- Cache exercises in localStorage
- Optimistic UI with background sync"
```

---

## Task 9: Final Polish and Documentation

**Files:**
- Modify: `index.html`
- Create: `README.md`

**Step 1: Add keyboard shortcuts and UX improvements**

Add to script:

```javascript
// Enter key submits in modal
document.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !document.getElementById('log-set-modal').classList.contains('hidden')) {
    saveSet();
  }
});

// Tab order in modal
document.getElementById('set-weight').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    document.getElementById('set-reps').focus();
  }
});
```

**Step 2: Add loading states**

Add CSS:

```css
.loading {
  text-align: center;
  padding: 40px 20px;
  color: var(--gray-700);
}
```

Update `initializeApp` to show loading:

```javascript
async function initializeApp() {
  document.body.innerHTML = '<div class="loading">Loading your workout data...</div>';

  const { data: schedule } = await supabase
    .from('workout_schedule')
    .select('*')
    .eq('user_id', state.user.id);

  // Rest of function...
}
```

**Step 3: Create README**

```markdown
# Workout Tracker

A mobile-first workout tracker for logging sets (exercise, weight, reps) with pre-assigned weekly schedules.

## Features

- 📱 **Mobile-optimized** - Fast loading, large tap targets, iOS keyboard support
- 🔐 **Magic link auth** - Passwordless authentication via email
- 📊 **Smart logging** - Shows last set for each exercise
- 📅 **Weekly schedule** - Pre-assign workout types to days
- 💪 **Exercise library** - Manage exercises by workout type
- ⚡ **Offline support** - Works offline with background sync
- 🇲🇹 **Metric units** - Weight in kg

## Setup

### 1. Create Supabase Project

Follow instructions in [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md)

### 2. Configure Credentials

Edit `index.html` and replace:

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL_HERE';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

### 3. Deploy

Upload `index.html` to:
- GitHub Pages
- Netlify
- Vercel
- Or any static host

## Usage

1. **Sign in** with magic link (email)
2. **Set weekly schedule** - Assign workout types to days
3. **Add exercises** - Organize by workout type
4. **Log sets** - Tap exercise → enter weight/reps → done!

## Tech Stack

- Vanilla JavaScript (no framework)
- Supabase (auth + database)
- CSS Grid/Flexbox
- localStorage cache

## Development

This is a single HTML file - no build step required.

Open `index.html` in browser for local development (requires Supabase credentials).

## License

MIT
```

**Step 4: Commit final polish**

```bash
git add index.html README.md
git commit -m "feat: final polish and documentation

- Keyboard shortcuts (Enter to submit, Tab navigation)
- Loading states during data fetch
- README with setup and usage instructions
- UX improvements for mobile experience"
```

---

## Task 10: Testing and Validation

**Manual Testing Checklist:**

1. **Auth Flow**
   - [ ] Can request magic link
   - [ ] Magic link redirects correctly
   - [ ] Session persists on refresh

2. **Onboarding**
   - [ ] Can set weekly schedule
   - [ ] Schedule saves to database
   - [ ] Redirects to exercises after schedule

3. **Exercise Management**
   - [ ] Can add exercises
   - [ ] Exercises grouped by workout type
   - [ ] Can delete exercises
   - [ ] Duplicate names rejected

4. **Workout Logging**
   - [ ] Today's workout type displays correctly
   - [ ] Exercises filtered by workout type
   - [ ] Modal opens on exercise tap
   - [ ] Can log set with weight/reps
   - [ ] Last set displays under exercise
   - [ ] Modal closes after save

5. **Settings**
   - [ ] Can edit schedule
   - [ ] Schedule updates persist
   - [ ] Can sign out

6. **Offline Support**
   - [ ] Can log sets offline
   - [ ] Sync indicator shows pending
   - [ ] Sets sync when back online

7. **Mobile Experience**
   - [ ] iOS keyboard appears correctly
   - [ ] Tap targets are large enough
   - [ ] No horizontal scroll
   - [ ] Safe area insets work

**Run through all tests and fix any issues found.**

**When all tests pass:**

```bash
git add .
git commit -m "test: validate all features working

All manual tests passing:
- Auth flow
- Onboarding
- Exercise management
- Workout logging
- Settings
- Offline support
- Mobile UX"
```

---

## Deployment

1. Get Supabase credentials from your project
2. Add credentials to `index.html`
3. Choose deployment option:
   - **GitHub Pages**: Push to repo, enable Pages in settings
   - **Netlify**: Drag and drop `index.html`
   - **Vercel**: Import repo or drag file

4. Test deployed version on iPhone

5. Add to iPhone home screen:
   - Open in Safari
   - Tap Share button
   - Tap "Add to Home Screen"
   - Now works like native app!

Done! 🎉
