# Stats Tab & Inline Preview Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add exercise statistics and progress tracking with inline preview on main screen and new Stats tab

**Architecture:** Single-file app (index.html). Add state properties for stats data, implement lazy-loaded Stats tab with dashboard + exercise management + per-exercise sections. Replace "Exercises" tab with "Stats". CSS-only bar charts (no libraries).

**Tech Stack:** Vanilla JS, Supabase, CSS (no new dependencies)

---

## Task 1: Add State Properties

**Files:**
- Modify: `index.html:541-552`

**Step 1: Add new state properties**

Find the state object around line 541-552 and add new properties:

```javascript
const state = {
  user: null,
  exercises: [],
  schedule: [],
  equipment: [],
  syncQueue: [],
  lastStats: {},
  maxWeights: {},
  isInitialized: false,
  selectedDay: new Date().getDay(),
  // NEW PROPERTIES
  recentSets: {},           // {exerciseId: [{weight, reps, logged_at}, ...]} - last 6 sets
  dashboardMetrics: {},     // {prs: 3, trending: 5, streak: 12}
  exerciseStats: {},        // {exerciseId: {pr, lastSession, volume30d, chartData, history}}
  statsLoaded: false        // Flag to prevent redundant loads
};
```

**Step 2: Test in browser**

1. Open browser DevTools console
2. Check that `state` object exists
3. Verify new properties initialized to `{}`/`false`

**Step 3: Commit**

```bash
git add index.html
git commit -m "Add state properties for stats tracking"
```

---

## Task 2: Implement loadRecentSets Function

**Files:**
- Modify: `index.html` (add after `loadMaxWeights()` around line 839)

**Step 1: Add loadRecentSets function**

Insert after line 839 (after `loadMaxWeights()` function):

```javascript
async function loadRecentSets() {
  // Get last 6 sets per exercise for comparison (current + previous session)
  const { data } = await supabase
    .from('sets')
    .select('exercise_id, weight, reps, logged_at')
    .eq('user_id', state.user.id)
    .order('logged_at', { ascending: false });

  if (data) {
    const recentSets = {};
    data.forEach(set => {
      if (!recentSets[set.exercise_id]) {
        recentSets[set.exercise_id] = [];
      }
      // Only store up to 6 sets per exercise
      if (recentSets[set.exercise_id].length < 6) {
        recentSets[set.exercise_id].push({
          weight: set.weight,
          reps: set.reps,
          logged_at: set.logged_at
        });
      }
    });
    state.recentSets = recentSets;
  }
}
```

**Step 2: Call loadRecentSets in initializeApp**

Find `initializeApp()` function around line 663. Add call after `loadMaxWeights()`:

```javascript
async function initializeApp() {
  // ... existing code ...

  if (!schedule || schedule.length === 0) {
    showScreen('onboarding-screen');
  } else {
    state.schedule = schedule;
    await loadExercises();
    await loadEquipment();
    await loadLastStats();
    await loadMaxWeights();
    await loadRecentSets();  // ADD THIS LINE
    loadSyncQueue();
    showMainScreen();
  }
  state.isInitialized = true;
}
```

**Step 3: Test in browser**

1. Sign in to app
2. Open DevTools console
3. Type: `state.recentSets`
4. Verify object contains exercise IDs with arrays of 6 sets (or less if fewer logged)

**Step 4: Commit**

```bash
git add index.html
git commit -m "Add loadRecentSets function for inline preview data"
```

---

## Task 3: Add CSS for Set Chips and Trend Arrows

**Files:**
- Modify: `index.html:10-285` (in `<style>` block)

**Step 1: Add CSS for set chips**

Insert before the closing `</style>` tag around line 285:

```css
/* Set chips for inline preview */
.set-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 8px;
}

.set-chip {
  display: inline-block;
  padding: 4px 10px;
  background: var(--gray-100);
  color: var(--gray-700);
  border-radius: 12px;
  font-size: 13px;
  font-weight: 500;
}

.set-chip .trend-arrow {
  margin-left: 4px;
  font-size: 11px;
}

.trend-arrow.up {
  color: var(--success);
}

.trend-arrow.down {
  color: var(--danger);
}

.trend-arrow.neutral {
  color: var(--gray-700);
}
```

**Step 2: Test in browser**

1. Inspect element styles in DevTools
2. Verify `.set-chips` and `.set-chip` classes exist

**Step 3: Commit**

```bash
git add index.html
git commit -m "Add CSS for set chips and trend arrows"
```

---

## Task 4: Add Helper Function for Trend Calculation

**Files:**
- Modify: `index.html` (add before `renderMainScreen()` around line 846)

**Step 1: Add calculateTrend helper function**

Insert before `renderMainScreen()` function around line 846:

```javascript
function calculateTrend(currentSet, previousSet) {
  if (!previousSet) return '—'; // No previous session

  const weightUp = currentSet.weight > previousSet.weight;
  const repsUp = currentSet.reps >= previousSet.reps + 2;
  const weightDown = currentSet.weight < previousSet.weight;

  if (weightUp || repsUp) {
    return '↑';
  } else if (weightDown && !repsUp) {
    return '↓';
  }
  return ''; // Neutral (no arrow)
}
```

**Step 2: Test function in console**

1. Open DevTools console
2. Test: `calculateTrend({weight: 20, reps: 8}, {weight: 17.5, reps: 8})`
3. Should return: `'↑'`
4. Test: `calculateTrend({weight: 20, reps: 8}, {weight: 22.5, reps: 8})`
5. Should return: `'↓'`
6. Test: `calculateTrend({weight: 20, reps: 8}, null)`
7. Should return: `'—'`

**Step 3: Commit**

```bash
git add index.html
git commit -m "Add trend calculation helper function"
```

---

## Task 5: Update renderMainScreen for Inline Preview

**Files:**
- Modify: `index.html:888-905`

**Step 1: Replace Last/Max display with set chips**

Find the `listEl.innerHTML` assignment around line 888-905. Replace the entire exercise list rendering:

```javascript
listEl.innerHTML = todayExercises.map(ex => {
  const recentSets = state.recentSets[ex.id] || [];
  const last3 = recentSets.slice(0, 3); // Most recent 3 sets
  const previous3 = recentSets.slice(3, 6); // Previous session (sets 4-6)
  const equipmentText = getEquipmentNames(ex.equipment_ids);

  // Generate set chips with trend arrows
  let setsHTML = '';
  if (last3.length > 0) {
    setsHTML = `
      <div class="set-chips">
        ${last3.map((set, idx) => {
          const prevSet = previous3[idx]; // Compare to same position in previous session
          const trend = calculateTrend(set, prevSet);
          const arrowClass = trend === '↑' ? 'up' : trend === '↓' ? 'down' : 'neutral';

          return `
            <span class="set-chip">
              ${set.weight}kg×${set.reps}${trend ? `<span class="trend-arrow ${arrowClass}">${trend}</span>` : ''}
            </span>
          `;
        }).join('')}
      </div>
    `;
  }

  return `
    <div class="exercise-item exercise-item-clickable" data-exercise-id="${ex.id}">
      <div class="exercise-name">${escapeHtml(ex.name)}</div>
      ${equipmentText ? `<div style="font-size: 12px; color: var(--gray-700); margin-top: 4px;">${escapeHtml(equipmentText)}</div>` : ''}
      ${setsHTML || '<div style="font-size: 14px; color: var(--gray-700); margin-top: 4px;">No history yet</div>'}
    </div>
  `;
}).join('');
```

**Step 2: Test in browser**

1. Navigate to main Workout screen
2. Verify each exercise shows 3 set chips (if logged before)
3. Verify trend arrows appear (↑, ↓, —, or none)
4. Click an exercise to verify log modal still opens
5. Test on exercise with <3 sets logged (should show what's available)
6. Test on exercise with no sets (should show "No history yet")

**Step 3: Commit**

```bash
git add index.html
git commit -m "Replace Last/Max display with inline 3-set preview"
```

---

## Task 6: Replace "Exercises" Tab with "Stats" Tab

**Files:**
- Modify: `index.html:373-383` (main-screen nav-bar)
- Modify: `index.html:411-421` (settings-screen nav-bar)
- Modify: `index.html:448-458` (exercises-screen nav-bar - will become stats-screen)

**Step 1: Rename exercises-screen to stats-screen**

Find `<div id="exercises-screen"` around line 424 and change to:

```html
<div id="stats-screen" class="screen hidden">
```

**Step 2: Update all nav-bar buttons**

Replace nav-bar in main-screen (lines 373-383):

```html
<div class="nav-bar">
  <button class="nav-item active" onclick="showMainScreen()">
    Workout
  </button>
  <button class="nav-item" onclick="showStatsTab()">
    Stats
  </button>
  <button class="nav-item" onclick="showScreen('settings-screen'); renderSettings();">
    Settings
  </button>
</div>
```

Replace nav-bar in settings-screen (lines 411-421):

```html
<div class="nav-bar">
  <button class="nav-item" onclick="showMainScreen()">
    Workout
  </button>
  <button class="nav-item" onclick="showStatsTab()">
    Stats
  </button>
  <button class="nav-item active">
    Settings
  </button>
</div>
```

Replace nav-bar in stats-screen (formerly exercises-screen, lines 448-458):

```html
<div class="nav-bar">
  <button class="nav-item" onclick="showMainScreen()">
    Workout
  </button>
  <button class="nav-item active">
    Stats
  </button>
  <button class="nav-item" onclick="showScreen('settings-screen'); renderSettings();">
    Settings
  </button>
</div>
```

**Step 3: Update modal equipment link**

Find line 434 in stats-screen (equipment management link). Update onclick to use stats-screen:

```html
<a href="#" onclick="showModal('equipment-modal'); renderEquipmentList(); return false;" style="color: var(--primary); font-size: 14px; text-decoration: none;">
  Manage Equipment
</a>
```

**Step 4: Test tab navigation**

1. Click each tab: Workout, Stats, Settings
2. Verify correct screen shows
3. Verify active state on tab buttons
4. Verify no console errors

**Step 5: Commit**

```bash
git add index.html
git commit -m "Rename Exercises tab to Stats tab"
```

---

## Task 7: Implement Dashboard Metrics Functions

**Files:**
- Modify: `index.html` (add after `loadRecentSets()`)

**Step 1: Add loadDashboardMetrics function**

Insert after `loadRecentSets()` function:

```javascript
async function loadDashboardMetrics() {
  const metrics = { prs: 0, trending: 0, streak: 0 };

  // Metric 1: New PRs this week
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);

  const { data: recentSets } = await supabase
    .from('sets')
    .select('exercise_id, weight, reps, logged_at')
    .eq('user_id', state.user.id)
    .gte('logged_at', weekAgo.toISOString())
    .gte('reps', 6)
    .order('weight', { ascending: false });

  if (recentSets) {
    const prExercises = new Set();
    recentSets.forEach(set => {
      const currentMax = state.maxWeights[set.exercise_id];
      if (!currentMax || set.weight > currentMax.weight) {
        prExercises.add(set.exercise_id);
      }
    });
    metrics.prs = prExercises.size;
  }

  // Metric 2: Exercises trending up (last 7 days avg > previous 7 days avg)
  const twoWeeksAgo = new Date();
  twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);

  const { data: twoWeeksSets } = await supabase
    .from('sets')
    .select('exercise_id, weight, logged_at')
    .eq('user_id', state.user.id)
    .gte('logged_at', twoWeeksAgo.toISOString())
    .order('logged_at', { ascending: false });

  if (twoWeeksSets) {
    const exerciseTrends = {};
    twoWeeksSets.forEach(set => {
      const daysAgo = Math.floor((Date.now() - new Date(set.logged_at).getTime()) / (1000 * 60 * 60 * 24));

      if (!exerciseTrends[set.exercise_id]) {
        exerciseTrends[set.exercise_id] = { recent: [], previous: [] };
      }

      if (daysAgo < 7) {
        exerciseTrends[set.exercise_id].recent.push(set.weight);
      } else {
        exerciseTrends[set.exercise_id].previous.push(set.weight);
      }
    });

    let trendingCount = 0;
    Object.values(exerciseTrends).forEach(trend => {
      if (trend.recent.length >= 2 && trend.previous.length >= 2) {
        const recentAvg = trend.recent.reduce((a, b) => a + b, 0) / trend.recent.length;
        const previousAvg = trend.previous.reduce((a, b) => a + b, 0) / trend.previous.length;
        if (recentAvg > previousAvg) {
          trendingCount++;
        }
      }
    });
    metrics.trending = trendingCount;
  }

  // Metric 3: Current streak (consecutive workout days)
  const { data: allSets } = await supabase
    .from('sets')
    .select('logged_at')
    .eq('user_id', state.user.id)
    .order('logged_at', { ascending: false });

  if (allSets && allSets.length > 0) {
    const uniqueDays = [...new Set(allSets.map(s => s.logged_at.split('T')[0]))];
    let streak = 0;
    let currentDate = new Date();

    for (let i = 0; i < uniqueDays.length; i++) {
      const logDate = new Date(uniqueDays[i]);
      const diffDays = Math.floor((currentDate - logDate) / (1000 * 60 * 60 * 24));

      if (diffDays === streak) {
        streak++;
        currentDate = logDate;
      } else {
        break;
      }
    }
    metrics.streak = streak;
  }

  state.dashboardMetrics = metrics;
}
```

**Step 2: Test in console**

1. Sign in to app
2. Open DevTools console
3. Type: `await loadDashboardMetrics()`
4. Type: `state.dashboardMetrics`
5. Verify object has `{prs: X, trending: Y, streak: Z}` with numbers

**Step 3: Commit**

```bash
git add index.html
git commit -m "Add dashboard metrics calculation function"
```

---

## Task 8: Implement showStatsTab Function and Layout

**Files:**
- Modify: `index.html` (add after `showMainScreen()` around line 844)
- Modify: `index.html:424-459` (stats-screen HTML structure)

**Step 1: Add showStatsTab function**

Insert after `showMainScreen()` function around line 844:

```javascript
async function showStatsTab() {
  showScreen('stats-screen');

  // Lazy load stats data on first visit
  if (!state.statsLoaded) {
    // Show loading indicator
    document.getElementById('stats-content').innerHTML = '<div class="loading">Loading stats...</div>';

    await loadDashboardMetrics();
    state.statsLoaded = true;
  }

  renderStatsScreen();
}
```

**Step 2: Update stats-screen HTML structure**

Replace the stats-screen HTML (lines 424-459) with new structure:

```html
<div id="stats-screen" class="screen hidden">
  <h2>Stats</h2>

  <div id="stats-content">
    <!-- Populated by renderStatsScreen() -->
  </div>

  <div class="nav-bar">
    <button class="nav-item" onclick="showMainScreen()">
      Workout
    </button>
    <button class="nav-item active">
      Stats
    </button>
    <button class="nav-item" onclick="showScreen('settings-screen'); renderSettings();">
      Settings
    </button>
  </div>
</div>
```

**Step 3: Test in browser**

1. Click "Stats" tab
2. Verify "Loading stats..." appears briefly
3. Verify no console errors

**Step 4: Commit**

```bash
git add index.html
git commit -m "Add showStatsTab function and update Stats screen structure"
```

---

## Task 9: Implement renderStatsScreen with Dashboard

**Files:**
- Modify: `index.html` (add after `showStatsTab()`)

**Step 1: Add renderStatsScreen function**

Insert after `showStatsTab()` function:

```javascript
function renderStatsScreen() {
  const contentEl = document.getElementById('stats-content');
  const metrics = state.dashboardMetrics;

  // Dashboard section
  const dashboardHTML = `
    <div style="background: white; padding: 20px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
      <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; text-align: center;">
        <div>
          <div style="font-size: 28px; font-weight: 700; color: var(--primary);">${metrics.prs || 0}</div>
          <div style="font-size: 13px; color: var(--gray-700); margin-top: 4px;">New PRs</div>
        </div>
        <div>
          <div style="font-size: 28px; font-weight: 700; color: var(--success);">${metrics.trending || 0}</div>
          <div style="font-size: 13px; color: var(--gray-700); margin-top: 4px;">Trending Up</div>
        </div>
        <div>
          <div style="font-size: 28px; font-weight: 700; color: var(--gray-900);">${metrics.streak || 0}</div>
          <div style="font-size: 13px; color: var(--gray-700); margin-top: 4px;">Day Streak</div>
        </div>
      </div>
    </div>
  `;

  // Exercise Management section (collapsible)
  const managementHTML = `
    <div style="margin-bottom: 20px;">
      <div
        onclick="toggleExerciseManagement()"
        style="background: white; padding: 16px 20px; border-radius: 12px; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center;"
      >
        <h3 style="font-size: 18px; font-weight: 600; margin: 0;">Manage Exercises</h3>
        <span id="management-arrow" style="font-size: 14px; transition: transform 0.2s;">▼</span>
      </div>
      <div id="exercise-management-content" class="hidden" style="margin-top: 12px;">
        <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
          <div id="exercise-groups">
            <!-- Populated by renderExerciseManager() -->
          </div>

          <div style="margin-top: 24px; padding-top: 24px; border-top: 1px solid var(--gray-200);">
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
        </div>
      </div>
    </div>
  `;

  // Exercise Stats sections (placeholder for now)
  const statsHTML = `
    <div style="color: var(--gray-700); text-align: center; padding: 40px 20px;">
      Per-exercise stats coming in next task...
    </div>
  `;

  contentEl.innerHTML = dashboardHTML + managementHTML + statsHTML;

  // Trigger renderExerciseManager to populate the management section
  renderExerciseManager();
}

function toggleExerciseManagement() {
  const content = document.getElementById('exercise-management-content');
  const arrow = document.getElementById('management-arrow');

  if (content.classList.contains('hidden')) {
    content.classList.remove('hidden');
    arrow.style.transform = 'rotate(180deg)';
  } else {
    content.classList.add('hidden');
    arrow.style.transform = 'rotate(0deg)';
  }
}
```

**Step 2: Test in browser**

1. Click "Stats" tab
2. Verify dashboard shows 3 metrics (PRs, Trending, Streak)
3. Verify "Manage Exercises" section appears (collapsed)
4. Click "Manage Exercises" to expand
5. Verify exercise manager appears (same as old Exercises tab)
6. Verify can add/edit/delete exercises
7. Click "Manage Exercises" again to collapse

**Step 3: Commit**

```bash
git add index.html
git commit -m "Implement Stats screen with dashboard and collapsible exercise management"
```

---

## Task 10: Implement Per-Exercise Stats Sections

**Files:**
- Modify: `index.html` (update `renderStatsScreen()`)

**Step 1: Add loadExerciseStats function**

Insert after `loadDashboardMetrics()`:

```javascript
async function loadExerciseStats() {
  const stats = {};
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  for (const exercise of state.exercises) {
    const exerciseId = exercise.id;

    // Get all sets for this exercise (last 30 days for history)
    const { data: sets } = await supabase
      .from('sets')
      .select('weight, reps, logged_at')
      .eq('user_id', state.user.id)
      .eq('exercise_id', exerciseId)
      .gte('logged_at', thirtyDaysAgo.toISOString())
      .order('logged_at', { ascending: false });

    if (!sets || sets.length === 0) {
      stats[exerciseId] = {
        pr: null,
        lastSession: [],
        volume30d: 0,
        chartData: [],
        history: []
      };
      continue;
    }

    // PR (all-time max from state.maxWeights)
    const pr = state.maxWeights[exerciseId] || null;

    // Last session (group by date, take most recent date)
    const sessionsByDate = {};
    sets.forEach(set => {
      const date = set.logged_at.split('T')[0];
      if (!sessionsByDate[date]) sessionsByDate[date] = [];
      sessionsByDate[date].push({ weight: set.weight, reps: set.reps });
    });

    const dates = Object.keys(sessionsByDate).sort().reverse();
    const lastSession = dates.length > 0 ? sessionsByDate[dates[0]] : [];

    // Total volume (30 days)
    const volume30d = sets.reduce((sum, set) => sum + (set.weight * set.reps), 0);

    // Chart data (last 10 sessions + weekly aggregation for older)
    const chartData = [];
    if (dates.length > 0) {
      const recentDates = dates.slice(0, 10);
      recentDates.reverse().forEach(date => {
        const sessionSets = sessionsByDate[date];
        const maxWeight = Math.max(...sessionSets.map(s => s.weight));
        chartData.push({ date, weight: maxWeight, type: 'session' });
      });

      // Weekly aggregation for older sessions (if more than 10)
      if (dates.length > 10) {
        const olderDates = dates.slice(10);
        const weeklyData = {};

        olderDates.forEach(date => {
          const weekStart = getWeekStart(new Date(date));
          if (!weeklyData[weekStart]) weeklyData[weekStart] = [];
          const sessionSets = sessionsByDate[date];
          weeklyData[weekStart].push(...sessionSets.map(s => s.weight));
        });

        Object.entries(weeklyData).forEach(([week, weights]) => {
          const avgWeight = weights.reduce((a, b) => a + b, 0) / weights.length;
          chartData.unshift({ date: week, weight: avgWeight, type: 'weekly' });
        });
      }
    }

    // History (grouped by session date)
    const history = dates.map(date => ({
      date,
      sets: sessionsByDate[date]
    }));

    stats[exerciseId] = { pr, lastSession, volume30d, chartData, history };
  }

  state.exerciseStats = stats;
}

function getWeekStart(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day;
  return new Date(d.setDate(diff)).toISOString().split('T')[0];
}
```

**Step 2: Call loadExerciseStats in showStatsTab**

Update `showStatsTab()` to load exercise stats:

```javascript
async function showStatsTab() {
  showScreen('stats-screen');

  // Lazy load stats data on first visit
  if (!state.statsLoaded) {
    // Show loading indicator
    document.getElementById('stats-content').innerHTML = '<div class="loading">Loading stats...</div>';

    await loadDashboardMetrics();
    await loadExerciseStats();  // ADD THIS LINE
    state.statsLoaded = true;
  }

  renderStatsScreen();
}
```

**Step 3: Update renderStatsScreen to render per-exercise sections**

Replace the `statsHTML` placeholder in `renderStatsScreen()`:

```javascript
// Exercise Stats sections
const workoutTypes = [...new Set(state.schedule.map(s => s.workout_type))];
const statsHTML = workoutTypes.map(type => {
  const exercises = state.exercises.filter(ex => ex.workout_type === type);

  const exerciseSections = exercises.map(ex => {
    const stats = state.exerciseStats[ex.id];
    if (!stats) return '';

    // Stats summary
    const prText = stats.pr ? `${stats.pr.weight}kg × ${stats.pr.reps}` : 'N/A';
    const lastSessionText = stats.lastSession.length > 0
      ? stats.lastSession.map(s => `${s.weight}kg × ${s.reps}`).join(', ')
      : 'N/A';
    const volumeText = `${Math.round(stats.volume30d)}kg`;

    // Bar chart (CSS bars)
    let chartHTML = '';
    if (stats.chartData.length > 0) {
      const maxWeight = Math.max(...stats.chartData.map(d => d.weight));
      const barWidth = 8;
      const barGap = 2;
      const chartWidth = stats.chartData.length * (barWidth + barGap);

      chartHTML = `
        <div style="margin: 16px 0; padding: 12px; background: var(--gray-50); border-radius: 8px; overflow-x: auto;">
          <div style="display: flex; align-items: flex-end; height: 150px; gap: ${barGap}px; width: ${chartWidth}px;">
            ${stats.chartData.map(d => {
              const height = (d.weight / maxWeight) * 100;
              return `
                <div
                  title="${d.weight}kg"
                  style="width: ${barWidth}px; height: ${height}%; background: var(--primary); border-radius: 4px 4px 0 0; transition: opacity 0.2s;"
                ></div>
              `;
            }).join('')}
          </div>
        </div>
      `;
    } else {
      chartHTML = '<div style="padding: 40px 20px; text-align: center; color: var(--gray-700); background: var(--gray-50); border-radius: 8px; margin: 16px 0;">No data to chart yet</div>';
    }

    // Session history
    let historyHTML = '';
    if (stats.history.length > 0) {
      historyHTML = `
        <div style="margin-top: 16px;">
          <h4 style="font-size: 14px; font-weight: 600; color: var(--gray-700); margin-bottom: 8px;">History (Last 30 Days)</h4>
          ${stats.history.map(session => `
            <div style="margin-bottom: 12px;">
              <div style="font-size: 13px; font-weight: 600; color: var(--gray-700); margin-bottom: 4px;">${formatDate(session.date)}</div>
              <div style="padding-left: 12px; font-size: 13px; color: var(--gray-700);">
                ${session.sets.map(s => `• ${s.weight}kg × ${s.reps}`).join('<br>')}
              </div>
            </div>
          `).join('')}
        </div>
      `;
    } else {
      historyHTML = '<div style="margin-top: 16px; text-align: center; color: var(--gray-700); padding: 20px;">No history yet</div>';
    }

    return `
      <div style="background: white; padding: 20px; border-radius: 12px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
        <h3 style="font-size: 18px; font-weight: 600; margin-bottom: 12px;">${escapeHtml(ex.name)}</h3>
        <div style="display: flex; justify-content: space-between; padding: 12px; background: var(--gray-50); border-radius: 8px; font-size: 13px; margin-bottom: 8px;">
          <div>
            <div style="color: var(--gray-700); margin-bottom: 4px;">All-time PR</div>
            <div style="font-weight: 700; font-size: 16px;">${prText}</div>
          </div>
          <div>
            <div style="color: var(--gray-700); margin-bottom: 4px;">Last Session</div>
            <div style="font-weight: 600;">${lastSessionText}</div>
          </div>
          <div>
            <div style="color: var(--gray-700); margin-bottom: 4px;">Volume (30d)</div>
            <div style="font-weight: 600;">${volumeText}</div>
          </div>
        </div>
        ${chartHTML}
        ${historyHTML}
      </div>
    `;
  }).join('');

  return `
    <div style="margin-bottom: 24px;">
      <h3 style="font-size: 20px; font-weight: 700; margin-bottom: 16px; color: var(--gray-900);">${escapeHtml(type)}</h3>
      ${exerciseSections}
    </div>
  `;
}).join('');

function formatDate(dateStr) {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}
```

**Step 4: Test in browser**

1. Click "Stats" tab
2. Scroll down past dashboard and exercise management
3. Verify exercises grouped by workout type (Pull, Push, Legs)
4. Verify each exercise shows:
   - All-time PR
   - Last session
   - Total volume (30 days)
   - Bar chart (if data exists)
   - Session history (last 30 days)
5. Test exercise with no history (should show "No data" messages)

**Step 5: Commit**

```bash
git add index.html
git commit -m "Implement per-exercise stat sections with charts and history"
```

---

## Task 11: Refresh Stats After Logging Set

**Files:**
- Modify: `index.html:983-1029` (saveSet function)

**Step 1: Update saveSet to refresh stats**

Find `saveSet()` function and add stats refresh after successful save:

```javascript
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

  // Update max weight if this set qualifies (6+ reps and beats current max)
  if (reps >= 6) {
    const currentMax = state.maxWeights[currentExerciseId]?.weight || 0;
    if (weight > currentMax) {
      state.maxWeights[currentExerciseId] = { weight, reps };
    }
  }

  // Update recentSets for inline preview
  if (!state.recentSets[currentExerciseId]) {
    state.recentSets[currentExerciseId] = [];
  }
  state.recentSets[currentExerciseId].unshift({ weight, reps, logged_at: setData.logged_at });
  if (state.recentSets[currentExerciseId].length > 6) {
    state.recentSets[currentExerciseId] = state.recentSets[currentExerciseId].slice(0, 6);
  }

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

    // Refresh stats if Stats tab has been loaded
    if (state.statsLoaded) {
      await loadDashboardMetrics();
      await loadExerciseStats();
      // Only re-render if currently on Stats screen
      if (!document.getElementById('stats-screen').classList.contains('hidden')) {
        renderStatsScreen();
      }
    }
  }
}
```

**Step 2: Test end-to-end**

1. Navigate to main Workout screen
2. Log a set for an exercise
3. Verify inline preview updates immediately (new chip appears)
4. Navigate to Stats tab
5. Verify dashboard metrics updated (if PR, streak, or trending changed)
6. Verify that exercise's stats updated (last session, volume, chart, history)
7. Go back to Workout screen
8. Log another set
9. Verify inline preview updates again
10. Return to Stats tab
11. Verify stats refreshed automatically

**Step 3: Commit**

```bash
git add index.html
git commit -m "Refresh stats after logging sets"
```

---

## Task 12: Add CSS for Stats Screen Elements

**Files:**
- Modify: `index.html:10-285` (CSS section)

**Step 1: Add additional CSS for better stats display**

Insert before closing `</style>` tag:

```css
/* Stats screen enhancements */
#stats-content {
  padding-bottom: 80px; /* Account for nav bar */
}

#stats-content h3 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
}

#stats-content h4 {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 8px;
}

/* Responsive dashboard grid */
@media (max-width: 360px) {
  #stats-content > div:first-child > div {
    grid-template-columns: 1fr !important;
    gap: 12px !important;
  }
}
```

**Step 2: Test responsive design**

1. Open browser DevTools
2. Toggle device toolbar (mobile view)
3. Test various screen widths (320px, 375px, 414px)
4. Verify dashboard metrics stack on very small screens
5. Verify charts scroll horizontally if needed

**Step 3: Commit**

```bash
git add index.html
git commit -m "Add CSS enhancements for Stats screen responsiveness"
```

---

## Task 13: Final Testing & Cleanup

**Files:**
- None (testing only)

**Step 1: Full feature test**

1. **Initial state:**
   - Sign out and sign back in
   - Verify Stats tab loads correctly on first visit
   - Verify "Loading stats..." appears briefly

2. **Dashboard metrics:**
   - Log a PR (6+ reps, higher weight than previous max)
   - Navigate to Stats tab
   - Verify "New PRs" count increased
   - Log sets for multiple days
   - Verify "Day Streak" updates correctly

3. **Inline preview:**
   - Log 3 sets for an exercise
   - Verify 3 chips appear with trend arrows
   - Log 3 more sets next session
   - Verify trend arrows compare to previous session correctly

4. **Exercise management:**
   - Add new exercise from Stats tab
   - Edit exercise name from Stats tab
   - Delete exercise from Stats tab
   - Verify all operations work same as before

5. **Per-exercise stats:**
   - Verify all exercises show correct PR
   - Verify last session matches recent logs
   - Verify volume calculation is accurate
   - Verify chart displays correctly
   - Verify history groups by session date

6. **Edge cases:**
   - Test exercise with no logged sets
   - Test exercise with only 1 logged set
   - Test exercise with >10 sessions (verify weekly aggregation)
   - Test Stats tab with no exercises at all

**Step 2: Performance check**

1. Open DevTools Network tab
2. Navigate to Stats tab
3. Verify only 3 database queries execute (metrics, exercise stats, history)
4. Navigate away and back
5. Verify no additional queries (data cached in state)

**Step 3: Commit final state**

```bash
git add -A
git commit -m "Final testing and validation complete"
git push
```

---

## Summary

**Total Tasks:** 13
**Estimated Time:** 2-3 hours
**Lines of Code Added:** ~300 (matching design estimate)
**New Dependencies:** 0 (pure CSS charts, no libraries)

**Key Files Modified:**
- `index.html` (all changes in single file)

**Features Delivered:**
1. ✅ Inline 3-set preview with trend arrows on main screen
2. ✅ Stats tab with progress dashboard (PRs, trending, streak)
3. ✅ Collapsible exercise management section
4. ✅ Per-exercise stat sections (PR, last session, volume, chart, history)
5. ✅ CSS-only bar charts with session/weekly aggregation
6. ✅ Lazy loading of stats data
7. ✅ Automatic refresh after logging sets

**Alignment with "Quickness Philosophy":**
- Zero new dependencies ✅
- Lazy loading for fast initial load ✅
- Minimal code growth (~300 lines) ✅
- Mobile-optimized layout ✅
- Pure CSS charts (no JS libraries) ✅
