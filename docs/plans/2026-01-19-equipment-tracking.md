# Equipment Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add optional user-customizable equipment tags to exercises

**Architecture:** Multi-select equipment chips in exercise form, stored in Supabase with junction table pattern, cached in localStorage for performance

**Tech Stack:** Vanilla JS, Supabase, single HTML file

---

## Task 1: Create Supabase Tables

**Files:**
- Manual: Supabase SQL Editor

**Step 1: Create equipment table**

Navigate to Supabase SQL Editor and run:

```sql
create table equipment (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, name)
);

alter table equipment enable row level security;

create policy "Users can manage their own equipment"
  on equipment for all
  using (auth.uid() = user_id);
```

Expected: Tables created successfully

**Step 2: Create exercise_equipment junction table**

```sql
create table exercise_equipment (
  exercise_id uuid references exercises on delete cascade not null,
  equipment_id uuid references equipment on delete cascade not null,
  primary key (exercise_id, equipment_id)
);

alter table exercise_equipment enable row level security;

create policy "Users can manage their exercise equipment"
  on exercise_equipment for all
  using (
    exists (
      select 1 from exercises
      where exercises.id = exercise_equipment.exercise_id
      and exercises.user_id = auth.uid()
    )
  );
```

Expected: Junction table created with RLS policies

**Step 3: Verify tables**

Run in SQL Editor:
```sql
select table_name from information_schema.tables
where table_schema = 'public'
and table_name in ('equipment', 'exercise_equipment');
```

Expected: Both tables listed

**Step 4: Commit**

```bash
# No files to commit - database only
git commit --allow-empty -m "feat: create equipment and exercise_equipment tables in Supabase

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Add Equipment State and Loading

**Files:**
- Modify: `index.html:459-466` (global state)
- Modify: `index.html:548-564` (initializeApp function)

**Step 1: Add equipment to global state**

In `index.html` around line 460, modify state object:

```javascript
const state = {
  user: null,
  exercises: [],
  schedule: [],
  equipment: [], // ADD THIS LINE
  syncQueue: [],
  lastStats: {}
};
```

Expected: Equipment array added to state

**Step 2: Create loadEquipment function**

Add after `loadExercises()` function (around line 622):

```javascript
async function loadEquipment() {
  // Try localStorage first
  const cached = localStorage.getItem('equipment');
  if (cached) {
    state.equipment = JSON.parse(cached);
  }

  // Fetch fresh from Supabase
  const { data, error } = await supabase
    .from('equipment')
    .select('*')
    .eq('user_id', state.user.id)
    .order('name');

  if (!error && data) {
    state.equipment = data;
    localStorage.setItem('equipment', JSON.stringify(data));
  }
}
```

**Step 3: Call loadEquipment in initializeApp**

Modify `initializeApp()` around line 558:

```javascript
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
    await loadEquipment(); // ADD THIS LINE
    await loadLastStats();
    loadSyncQueue();
    showMainScreen();
  }
}
```

**Step 4: Test in browser**

1. Open app in browser
2. Open DevTools console
3. After login, check: `console.log(state.equipment)`

Expected: Empty array `[]` (no equipment yet)

**Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add equipment state and loading from Supabase

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create Equipment Management Modal UI

**Files:**
- Modify: `index.html:413-416` (add modal after history-screen)

**Step 1: Add equipment modal HTML**

After the `history-screen` div (around line 415), add:

```html
  <div id="equipment-modal" class="modal hidden" onclick="if(event.target === this) hideModal('equipment-modal')">
    <div class="modal-content">
      <div class="modal-header">Manage Equipment</div>

      <input
        type="text"
        id="new-equipment-name"
        placeholder="Equipment name (e.g., Barbell)"
        style="margin-bottom: 16px;"
      />
      <button class="btn btn-primary" onclick="addEquipment()" style="margin-bottom: 24px;">
        Add Equipment
      </button>

      <div id="equipment-list" style="max-height: 300px; overflow-y: auto;">
        <!-- Populated by JS -->
      </div>

      <button class="btn btn-secondary" onclick="hideModal('equipment-modal')" style="margin-top: 16px;">
        Close
      </button>
    </div>
  </div>
```

**Step 2: Test modal visibility**

In DevTools console:
```javascript
showModal('equipment-modal')
```

Expected: Modal appears with input and buttons

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add equipment management modal UI

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Implement Equipment Management Functions

**Files:**
- Modify: `index.html:~1012` (after handleSignOut function)

**Step 1: Add renderEquipmentList function**

After `handleSignOut()` (around line 1012):

```javascript
function renderEquipmentList() {
  const listEl = document.getElementById('equipment-list');

  if (state.equipment.length === 0) {
    listEl.innerHTML = '<p style="color: var(--gray-700); font-size: 14px;">No equipment yet. Add your first one above!</p>';
    return;
  }

  listEl.innerHTML = state.equipment.map(eq => `
    <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px; background: var(--gray-50); border-radius: 8px; margin-bottom: 8px;">
      <span>${eq.name}</span>
      <button
        onclick="deleteEquipment('${eq.id}')"
        style="background: var(--danger); color: white; border: none; padding: 6px 12px; border-radius: 6px; font-size: 14px; cursor: pointer;"
      >
        Delete
      </button>
    </div>
  `).join('');
}
```

**Step 2: Add addEquipment function**

```javascript
async function addEquipment() {
  const name = document.getElementById('new-equipment-name').value.trim();

  if (!name) {
    alert('Please enter equipment name');
    return;
  }

  const { data, error } = await supabase
    .from('equipment')
    .insert({
      user_id: state.user.id,
      name
    })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      alert('Equipment already exists');
    } else {
      alert('Error adding equipment: ' + error.message);
    }
    return;
  }

  state.equipment.push(data);
  state.equipment.sort((a, b) => a.name.localeCompare(b.name));
  localStorage.setItem('equipment', JSON.stringify(state.equipment));
  document.getElementById('new-equipment-name').value = '';
  renderEquipmentList();
}
```

**Step 3: Add deleteEquipment function**

```javascript
async function deleteEquipment(equipmentId) {
  // Check usage count
  const { data: usageData } = await supabase
    .from('exercise_equipment')
    .select('exercise_id')
    .eq('equipment_id', equipmentId);

  const usageCount = usageData ? usageData.length : 0;

  const confirmMsg = usageCount > 0
    ? `Remove this equipment? Used by ${usageCount} exercise${usageCount > 1 ? 's' : ''}.`
    : 'Remove this equipment?';

  if (!confirm(confirmMsg)) {
    return;
  }

  const { error } = await supabase
    .from('equipment')
    .delete()
    .eq('id', equipmentId);

  if (error) {
    alert('Error deleting equipment: ' + error.message);
    return;
  }

  state.equipment = state.equipment.filter(eq => eq.id !== equipmentId);
  localStorage.setItem('equipment', JSON.stringify(state.equipment));
  renderEquipmentList();
}
```

**Step 4: Test equipment management**

1. Open DevTools console: `showModal('equipment-modal')`
2. Add equipment: "Barbell"
3. Check state: `console.log(state.equipment)`
4. Delete equipment

Expected: Equipment added/removed, persisted in Supabase

**Step 5: Commit**

```bash
git add index.html
git commit -m "feat: implement equipment add/delete functions

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Add Equipment Selector to Exercise Form

**Files:**
- Modify: `index.html:391-398` (exercise form)

**Step 1: Add "Manage Equipment" link and chip selector**

Modify the "Add Exercise" section (around line 391):

```html
    <div style="margin-top: 24px;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <h3 style="font-size: 18px; margin: 0;">Add Exercise</h3>
        <a href="#" onclick="showModal('equipment-modal'); renderEquipmentList(); return false;" style="color: var(--primary); font-size: 14px; text-decoration: none;">
          Manage Equipment
        </a>
      </div>
      <input type="text" id="new-exercise-name" placeholder="Exercise name" />
      <select id="new-exercise-type" style="display: block; width: 100%; padding: 16px; font-size: 16px; border: 2px solid var(--gray-200); border-radius: 12px; margin-bottom: 12px;">
        <!-- Populated by JS -->
      </select>
      <div id="equipment-chips" style="margin-bottom: 12px;">
        <!-- Populated by JS -->
      </div>
      <button class="btn btn-primary" onclick="addExercise()">Add Exercise</button>
    </div>
```

**Step 2: Create renderEquipmentChips function**

Add before `renderExerciseManager()` (around line 765):

```javascript
function renderEquipmentChips() {
  const chipsEl = document.getElementById('equipment-chips');

  if (state.equipment.length === 0) {
    chipsEl.innerHTML = '';
    return;
  }

  chipsEl.innerHTML = `
    <label style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: var(--gray-700);">
      Equipment (optional)
    </label>
    <div style="display: flex; flex-wrap: wrap; gap: 8px;">
      ${state.equipment.map(eq => `
        <div
          onclick="toggleEquipmentChip('${eq.id}')"
          data-equipment-id="${eq.id}"
          class="equipment-chip"
          style="padding: 8px 12px; background: var(--gray-100); color: var(--gray-700); border-radius: 16px; font-size: 14px; cursor: pointer; user-select: none;"
        >
          ${eq.name}
        </div>
      `).join('')}
    </div>
  `;
}
```

**Step 3: Add toggleEquipmentChip function**

```javascript
function toggleEquipmentChip(equipmentId) {
  const chip = document.querySelector(`[data-equipment-id="${equipmentId}"]`);

  if (chip.classList.contains('selected')) {
    chip.classList.remove('selected');
    chip.style.background = 'var(--gray-100)';
    chip.style.color = 'var(--gray-700)';
  } else {
    chip.classList.add('selected');
    chip.style.background = 'var(--primary)';
    chip.style.color = 'white';
  }
}
```

**Step 4: Update renderExerciseManager to render chips**

Modify `renderExerciseManager()` at the end (around line 814):

```javascript
function renderExerciseManager() {
  // ... existing code ...

  // ADD THIS AT THE END before closing brace:
  renderEquipmentChips();
}
```

**Step 5: Test equipment chips**

1. Go to Exercises screen
2. Add equipment: "Barbell", "Dumbbell"
3. Click chips to toggle selection

Expected: Chips toggle blue/gray on click

**Step 6: Commit**

```bash
git add index.html
git commit -m "feat: add equipment chip selector to exercise form

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Save Exercise with Equipment

**Files:**
- Modify: `index.html:817-849` (addExercise function)

**Step 1: Modify addExercise to save equipment links**

Replace the `addExercise()` function (around line 817):

```javascript
async function addExercise() {
  const name = document.getElementById('new-exercise-name').value.trim();
  const workoutType = document.getElementById('new-exercise-type').value;

  if (!name) {
    alert('Please enter exercise name');
    return;
  }

  // Get selected equipment IDs
  const selectedChips = document.querySelectorAll('.equipment-chip.selected');
  const equipmentIds = Array.from(selectedChips).map(chip => chip.dataset.equipmentId);

  // Create exercise
  const { data: exercise, error: exerciseError } = await supabase
    .from('exercises')
    .insert({
      user_id: state.user.id,
      name,
      workout_type: workoutType
    })
    .select()
    .single();

  if (exerciseError) {
    if (exerciseError.code === '23505') {
      alert('Exercise already exists');
    } else {
      alert('Error adding exercise: ' + exerciseError.message);
    }
    return;
  }

  // Link equipment
  if (equipmentIds.length > 0) {
    const equipmentLinks = equipmentIds.map(eqId => ({
      exercise_id: exercise.id,
      equipment_id: eqId
    }));

    const { error: linkError } = await supabase
      .from('exercise_equipment')
      .insert(equipmentLinks);

    if (linkError) {
      console.error('Error linking equipment:', linkError);
    }
  }

  // Add equipment_ids to exercise for local display
  exercise.equipment_ids = equipmentIds;

  state.exercises.push(exercise);
  localStorage.setItem('exercises', JSON.stringify(state.exercises));
  document.getElementById('new-exercise-name').value = '';

  // Deselect all chips
  document.querySelectorAll('.equipment-chip.selected').forEach(chip => {
    chip.classList.remove('selected');
    chip.style.background = 'var(--gray-100)';
    chip.style.color = 'var(--gray-700)';
  });

  renderExerciseManager();
}
```

**Step 2: Test adding exercise with equipment**

1. Go to Exercises screen
2. Enter exercise name
3. Select equipment chips
4. Add exercise
5. Check Supabase exercise_equipment table

Expected: Exercise created with equipment links in database

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: save exercise equipment links to Supabase

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Load Exercise Equipment on App Init

**Files:**
- Modify: `index.html:603-621` (loadExercises function)

**Step 1: Modify loadExercises to fetch equipment links**

Replace `loadExercises()` function:

```javascript
async function loadExercises() {
  // Try localStorage first
  const cached = localStorage.getItem('exercises');
  if (cached) {
    state.exercises = JSON.parse(cached);
  }

  // Fetch fresh from Supabase
  const { data: exercises, error } = await supabase
    .from('exercises')
    .select('*')
    .eq('user_id', state.user.id)
    .order('name');

  if (!error && exercises) {
    // Fetch equipment links for all exercises
    const { data: links } = await supabase
      .from('exercise_equipment')
      .select('exercise_id, equipment_id')
      .in('exercise_id', exercises.map(ex => ex.id));

    // Group equipment IDs by exercise ID
    const equipmentByExercise = {};
    if (links) {
      links.forEach(link => {
        if (!equipmentByExercise[link.exercise_id]) {
          equipmentByExercise[link.exercise_id] = [];
        }
        equipmentByExercise[link.exercise_id].push(link.equipment_id);
      });
    }

    // Add equipment_ids to each exercise
    exercises.forEach(ex => {
      ex.equipment_ids = equipmentByExercise[ex.id] || [];
    });

    state.exercises = exercises;
    localStorage.setItem('exercises', JSON.stringify(exercises));
  }
}
```

**Step 2: Test loading**

1. Refresh app
2. Open DevTools: `console.log(state.exercises)`
3. Check exercise objects have `equipment_ids` array

Expected: Exercises load with equipment_ids populated

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: load exercise equipment relationships on init

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Display Equipment Tags in Exercise List

**Files:**
- Modify: `index.html:789-814` (renderExerciseManager display)

**Step 1: Add helper function to get equipment names**

Before `renderExerciseManager()`:

```javascript
function getEquipmentNames(equipmentIds) {
  if (!equipmentIds || equipmentIds.length === 0) return '';

  return equipmentIds
    .map(id => {
      const eq = state.equipment.find(e => e.id === id);
      return eq ? eq.name : null;
    })
    .filter(Boolean)
    .join(' • ');
}
```

**Step 2: Modify exercise display to show equipment**

In `renderExerciseManager()`, update the exercises.map section (around line 794):

```javascript
${exercises.map(ex => {
  const equipmentText = getEquipmentNames(ex.equipment_ids);
  return `
    <div class="exercise-item" style="display: flex; justify-content: space-between; align-items: center;">
      <div style="flex: 1;">
        <span style="display: block; font-weight: 600;">${ex.name}</span>
        ${equipmentText ? `<span style="display: block; font-size: 12px; color: var(--gray-700); margin-top: 4px;">${equipmentText}</span>` : ''}
      </div>
      <div style="display: flex; gap: 8px;">
        <button
          onclick="editExercise('${ex.id}', '${ex.name.replace(/'/g, "\\'")}')"
          style="background: var(--primary); color: white; border: none; padding: 8px 12px; border-radius: 8px; font-size: 14px; cursor: pointer;"
        >
          Edit
        </button>
        <button
          onclick="deleteExercise('${ex.id}')"
          style="background: var(--danger); color: white; border: none; padding: 8px 12px; border-radius: 8px; font-size: 14px; cursor: pointer;"
        >
          Delete
        </button>
      </div>
    </div>
  `;
}).join('')}
```

**Step 3: Test equipment display**

1. Go to Exercises screen
2. Check exercises show equipment tags below name

Expected: Equipment displayed as "Barbell • Dumbbell" in gray text

**Step 4: Commit**

```bash
git add index.html
git commit -m "feat: display equipment tags in exercise list

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Add Equipment Input Keyboard Shortcuts

**Files:**
- Modify: `index.html:1088` (end of script, after existing keyboard handlers)

**Step 1: Add keyboard handler for equipment input**

At end of script section (after line 1088):

```javascript
// Enter key submits equipment, Esc clears
document.getElementById('new-equipment-name').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    addEquipment();
  } else if (e.key === 'Escape' && e.target.value) {
    e.preventDefault();
    e.target.value = '';
  }
});
```

**Step 2: Test keyboard shortcuts**

1. Open equipment modal
2. Type equipment name, press Enter
3. Type text, press Escape

Expected: Enter adds, Escape clears

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add keyboard shortcuts for equipment input

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Clear Equipment State on Sign Out

**Files:**
- Modify: `index.html:1003-1012` (handleSignOut function)

**Step 1: Add equipment to state clearing**

Modify `handleSignOut()` (around line 1003):

```javascript
async function handleSignOut() {
  if (!confirm('Sign out?')) return;

  await supabase.auth.signOut();
  state.user = null;
  state.exercises = [];
  state.schedule = [];
  state.equipment = []; // ADD THIS LINE
  state.lastStats = {};
  showScreen('auth-screen');
}
```

**Step 2: Test sign out**

1. Add equipment
2. Sign out
3. Check DevTools: `state.equipment`

Expected: Empty array after sign out

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: clear equipment state on sign out

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Final Testing & Polish

**Step 1: Complete workflow test**

1. Sign in
2. Add equipment: "Barbell", "Dumbbell", "Kettlebell"
3. Go to Exercises, add exercise with equipment selected
4. Verify equipment tags appear in list
5. Delete equipment that's in use
6. Confirm usage count shown
7. Verify exercise still exists after equipment deleted

Expected: All flows work smoothly

**Step 2: Performance check**

1. Open DevTools Network tab
2. Refresh app
3. Count Supabase requests

Expected: 4 requests max on init (session, schedule, exercises, equipment)

**Step 3: Mobile test**

1. Open in iPhone browser
2. Test equipment modal on small screen
3. Test chip selection

Expected: Responsive, chips don't overflow

**Step 4: Final commit**

```bash
git add index.html
git commit -m "feat: equipment tracking feature complete

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Step 5: Push to remote**

```bash
git push origin main
```

Expected: All commits pushed successfully

---

## Implementation Complete

**Total Tasks:** 11
**Estimated Time:** 45-60 minutes
**Commits:** 11 small, focused commits

**Testing Checklist:**
- [ ] Equipment CRUD operations work
- [ ] Equipment links to exercises correctly
- [ ] Equipment displays in exercise list
- [ ] Deleting equipment shows usage count
- [ ] Equipment persists across page refresh
- [ ] Keyboard shortcuts work
- [ ] Mobile responsive
- [ ] Performance maintained (fast loading)
