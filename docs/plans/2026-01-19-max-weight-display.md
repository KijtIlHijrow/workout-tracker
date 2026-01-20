# Max Weight Display Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display each exercise's max weight (minimum 6 reps) next to the last set in the workout tab

**Architecture:** Query max weights on app load and update optimistically after logging sets. Display inline with last set stats using format "Last: Xkg × Y | Max: Xkg (Y)".

**Tech Stack:** Vanilla JavaScript, Supabase PostgreSQL, single-file HTML app

---

## Task 1: Add maxWeights to State

**Files:**
- Modify: `/Users/keith.ruggier/Fitness/index.html:493`

**Step 1: Add maxWeights property to state object**

Find the state object at line 487-494 and add `maxWeights: {}` after `lastStats: {}`:

```javascript
const state = {
  user: null,
  exercises: [],
  schedule: [],
  equipment: [],
  syncQueue: [],
  lastStats: {},
  maxWeights: {}  // NEW
};
```

**Step 2: Verify the change**

Run: `git diff index.html`
Expected: Shows one line added with `maxWeights: {}`

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add maxWeights to state object"
```

---

## Task 2: Create loadMaxWeights Function

**Files:**
- Modify: `/Users/keith.ruggier/Fitness/index.html:731` (after loadLastStats)

**Step 1: Add loadMaxWeights function**

Insert the following function after `loadLastStats()` (after line 730, before line 731):

```javascript
async function loadMaxWeights() {
  // Get sets with 6+ reps, ordered by weight descending
  const { data } = await supabase
    .from('sets')
    .select('exercise_id, weight, reps')
    .eq('user_id', state.user.id)
    .gte('reps', 6)
    .order('weight', { ascending: false });

  if (data) {
    state.maxWeights = {};
    // Take the first (highest weight) occurrence per exercise
    data.forEach(set => {
      if (!state.maxWeights[set.exercise_id]) {
        state.maxWeights[set.exercise_id] = { weight: set.weight, reps: set.reps };
      }
    });
  }
}
```

**Step 2: Verify the syntax**

Run: `git diff index.html`
Expected: Shows new function added after loadLastStats

**Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add loadMaxWeights function to query max weights from database"
```

---

## Task 3: Call loadMaxWeights in initializeApp

**Files:**
- Modify: `/Users/keith.ruggier/Fitness/index.html:589` (in initializeApp)

**Step 1: Add loadMaxWeights call**

In the `initializeApp()` function, add `await loadMaxWeights();` after line 589:

```javascript
async function initializeApp() {
  // ... existing code ...
  state.schedule = schedule;
  await loadExercises();
  await loadEquipment();
  await loadLastStats();
  await loadMaxWeights();  // NEW
  loadSyncQueue();
  showMainScreen();
}
```

**Step 2: Verify the change**

Run: `git diff index.html`
Expected: Shows one line added with `await loadMaxWeights();`

**Step 3: Test initial load**

1. Open the app in browser
2. Open DevTools console
3. Check: `state.maxWeights` should contain exercise IDs with max weights (6+ reps only)
4. Expected: Object like `{ "uuid-1": { weight: 70, reps: 6 }, "uuid-2": { weight: 100, reps: 8 } }`

**Step 4: Commit**

```bash
git add index.html
git commit -m "feat: load max weights on app initialization"
```

---

## Task 4: Update saveSet to Recalculate Max

**Files:**
- Modify: `/Users/keith.ruggier/Fitness/index.html:825-826` (in saveSet)

**Step 1: Add max weight update logic**

In the `saveSet()` function, add the following after the optimistic lastStats update (after line 825):

```javascript
// Optimistic update
state.lastStats[currentExerciseId] = { weight, reps };

// Update max weight if this set qualifies (6+ reps and beats current max)
if (reps >= 6) {
  const currentMax = state.maxWeights[currentExerciseId]?.weight || 0;
  if (weight > currentMax) {
    state.maxWeights[currentExerciseId] = { weight, reps };
  }
}

updateSyncStatus('pending');
```

**Step 2: Verify the change**

Run: `git diff index.html`
Expected: Shows new conditional block added after lastStats update

**Step 3: Test max update after logging**

1. Open app, navigate to workout tab
2. Log a set with 6+ reps that's heavier than current max
3. Check DevTools: `state.maxWeights[exerciseId]` should update immediately
4. Log a set with <6 reps or lighter weight
5. Check DevTools: `state.maxWeights[exerciseId]` should NOT change

**Step 4: Commit**

```bash
git add index.html
git commit -m "feat: update max weight optimistically after logging qualifying sets"
```

---

## Task 5: Display Max Weight in UI

**Files:**
- Modify: `/Users/keith.ruggier/Fitness/index.html:772-780` (in renderMainScreen)

**Step 1: Update renderMainScreen to show max weight**

Replace the exercise list rendering (lines 772-780) with:

```javascript
listEl.innerHTML = todayExercises.map(ex => {
  const last = state.lastStats[ex.id];
  const max = state.maxWeights[ex.id];
  return `
    <div class="exercise-item exercise-item-clickable" data-exercise-id="${ex.id}">
      <div class="exercise-name">${escapeHtml(ex.name)}</div>
      ${last || max ? `
        <div class="exercise-last">
          ${last ? `Last: ${last.weight}kg × ${last.reps}` : ''}
          ${last && max ? ` | ` : ''}
          ${max ? `Max: ${max.weight}kg (${max.reps})` : ''}
        </div>
      ` : ''}
    </div>
  `;
}).join('');
```

**Step 2: Verify the change**

Run: `git diff index.html`
Expected: Shows updated template with max weight display

**Step 3: Test UI display**

1. Refresh the app
2. Navigate to workout tab
3. Expected format: `Last: 60kg × 8 | Max: 70kg (6)`
4. Test edge cases:
   - Exercise with no sets logged: No stats shown
   - Exercise with only sets <6 reps: Only "Last" shown, no "Max"
   - Exercise with max but no recent set: Only "Max" shown
   - Exercise with both: Both shown with ` | ` separator

**Step 4: Commit**

```bash
git add index.html
git commit -m "feat: display max weight next to last set in workout tab"
```

---

## Task 6: Final Testing and Verification

**Step 1: Complete feature test**

1. Sign in to the app
2. Navigate to workout tab
3. Verify exercises show max weights (6+ reps only)
4. Log a new set with 8 reps at higher weight
5. Verify max updates immediately in UI
6. Refresh the page
7. Verify max weight persists after reload
8. Log a set with 5 reps (should not update max)
9. Verify max stays unchanged

**Step 2: Cross-browser verification**

Test on:
- Safari (iPhone/mobile)
- Chrome desktop
- Any other primary devices

**Step 3: Performance check**

1. Open DevTools Network tab
2. Refresh app
3. Verify loadMaxWeights query completes quickly
4. Check query returns only necessary data (exercise_id, weight, reps)

**Step 4: Final commit (if any fixes needed)**

```bash
git add index.html
git commit -m "fix: <description of any fixes>"
```

---

## Completion Checklist

- [ ] maxWeights added to state object
- [ ] loadMaxWeights function created
- [ ] loadMaxWeights called on app initialization
- [ ] saveSet updates max weight optimistically
- [ ] UI displays max weight with correct format
- [ ] Only sets with 6+ reps count as max
- [ ] Max weight persists after page refresh
- [ ] All commits have descriptive messages
- [ ] Feature tested on mobile (primary use case)

---

## Expected Final Result

Users will see their max weight (minimum 6 reps) displayed next to their last set in the workout tab:

```
Exercise Name
Last: 60kg × 8 | Max: 70kg (6)
```

This provides at-a-glance visibility of both recent performance and personal records for progressive overload tracking.
