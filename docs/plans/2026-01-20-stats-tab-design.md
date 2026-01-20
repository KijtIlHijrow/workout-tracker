# Stats Tab & Inline Preview Design

**Date:** 2026-01-20
**Status:** Approved

## Overview

Add exercise statistics and progress tracking to the Fitness app while maintaining the "quickness philosophy" (fast loading, minimal code). This design adds:

1. Inline 3-set preview with trend arrows on main Workout screen
2. New Stats tab (replaces Exercises tab) with progress dashboard and detailed per-exercise analytics
3. CSS-only bar charts (no libraries)
4. Smart data aggregation and caching for performance

## Goals

- Show recent workout progress at a glance (inline preview)
- Provide detailed progress tracking (Stats tab)
- Maintain fast load times and minimal code growth
- Keep UI clean and mobile-optimized

---

## Part 1: Main Screen Inline Preview

### Current State
Each exercise shows: `Last: 20kg × 8 | Max: 25kg (8)`

### New Behavior
Show last 3 sets as horizontal chips with trend arrows:
```
Exercise Name
[Equipment badges]
20kg×8 ↑  22.5kg×6 ↓  20kg×10 ↑
```

### Trend Arrow Logic
Compare each of the 3 most recent sets to the corresponding set from the previous session:
- **↑** = weight increased OR reps increased by 2+
- **↓** = weight decreased AND reps didn't increase by 2+
- **—** = no previous session to compare (first time)
- **No arrow** = neutral (minor changes below threshold)

### Implementation
- Query last 6 sets per exercise (current session + previous session)
- Display 3 most recent as chips (inline-block divs)
- Arrow as text character next to each chip
- CSS: gray background, rounded corners, 4px spacing
- Fallback: "No history yet" for never-logged exercises

### Data Loading
- New function: `loadRecentSets()`
- Gets last 6 sets per exercise for comparison
- Stores in: `state.recentSets[exerciseId] = [{weight, reps, logged_at}, ...]`
- Code: ~20 lines

---

## Part 2: Stats Tab Structure

### Tab Changes
- Remove "Exercises" tab
- New structure: **Workout | Stats** (2 tabs total)
- Stats tab = exercise management + statistics combined

### Stats Tab Layout (Top to Bottom)

**1. Progress Dashboard** (fixed at top)
- New PRs this week: X
- Exercises trending up: Y
- Current streak: Z days
- Height: ~80px, white background, subtle border

**2. Exercise Management Section** (collapsible)
- Header: "Manage Exercises" with collapse arrow
- Same functionality as current Exercises tab (add/edit/delete)
- Starts collapsed to prioritize stats viewing

**3. Exercise Stats List** (scrollable)
- One section per exercise
- Grouped by workout type (Pull, Push, Legs)
- Each section: Stats summary → Bar chart → Session history

### Navigation
- Tap "Stats" tab → Dashboard + collapsed management + stats list
- Tap "Manage Exercises" → Expands exercise manager
- No separate screens, everything in one scrollable view

### Code Impact
- Repurpose existing `renderExercisesTab()` function
- Add dashboard rendering (~40 lines)
- Add stat sections rendering (~60 lines per type)
- Total: ~150 new lines

---

## Part 3: Dashboard Metrics

### Metric 1: New PRs This Week
- Query: All sets from last 7 days where `(weight > previous max) AND reps >= 6`
- Count unique exercise_ids that hit new PRs
- Display: `3 New PRs`

### Metric 2: Exercises Trending Up
- For each exercise with sets in last 14 days:
  - Calculate avg weight for days 1-7 (recent)
  - Calculate avg weight for days 8-14 (previous)
  - If recent avg > previous avg, count as trending up
- Only include exercises with 2+ sets in each window
- Display: `5 Trending Up`

### Metric 3: Current Streak
- Query: All distinct days with logged sets, descending
- Count consecutive days backwards from today
- Skip days with no scheduled workout (rest days OK)
- Display: `12 Day Streak`

### Data Queries
- New function: `loadDashboardMetrics()`
- Runs 3 separate queries (PRs, trending, streak)
- Caches in: `state.dashboardMetrics = {prs, trending, streak}`
- Refreshes: On Stats tab open or after logging a set
- Code: ~60 lines

### Performance
- All queries use indexed columns (`logged_at`, `exercise_id`)
- Limited to last 14 days max
- Results cached in state

---

## Part 4: Exercise Stat Sections

Each exercise gets its own section containing:

### A. Stats Summary (Top Bar)
- **All-time PR:** `80kg × 6` (bold, larger)
- **Last session:** `75kg × 8, 77.5kg × 6, 75kg × 8` (gray, smaller)
- **Total volume (30 days):** `12,450kg` (sum of weight × reps)
- Layout: Single row, pipe-separated

### B. CSS Bar Chart
- Pure CSS bars (no libraries)
- X-axis: Timeline (left = old, right = recent)
- Y-axis: Weight (bar height)

**Aggregation:**
- Last 10 sessions: Individual bars (max weight per session)
- Older than 10 sessions: Weekly average bars

**Styling:**
- Blue fill, 8px width, 2px gap, rounded top
- Height: 150px chart area
- Hover shows weight value (CSS title attribute)
- No axes lines (minimal clean look)

### C. Session History
- Grouped by date: `Jan 20, 2026` header
- Indented sets: `• 20kg × 8`, `• 22.5kg × 6`
- Show last 30 days only
- Gray timestamp per session
- Newest at top

### Code Structure
- Function: `renderExerciseStatSection(exercise)`
- Queries: Reuse `state.maxWeights` for PR, new query for history
- Bar chart: Pure HTML/CSS with inline styles for heights
- Code: ~80 lines per render function

---

## Part 5: Data Loading Strategy

### Load Timing

**1. On app init (`initApp()`):**
- Load last 3 sets per exercise: `loadRecentSets()`
- Don't load Stats tab data yet (lazy load)

**2. On Stats tab click (first time):**
- Load dashboard metrics: `loadDashboardMetrics()`
- Load per-exercise data: `loadExerciseStats()`
- Cache in state, don't reload on subsequent tab switches

**3. After logging a set:**
- Optimistically update `state.recentSets[exerciseId]`
- Recalculate affected dashboard metrics
- Invalidate and reload that exercise's stat section
- Don't reload everything (targeted updates)

### New State Properties

```javascript
state.recentSets = {}           // {exerciseId: [{weight, reps, logged_at}, ...]}
state.dashboardMetrics = {}     // {prs: 3, trending: 5, streak: 12}
state.exerciseStats = {}        // {exerciseId: {pr, lastSession, volume30d, chartData, history}}
state.statsLoaded = false       // Prevent redundant loads
```

### Query Optimization
- Use existing indexes on `sets` table
- Batch queries where possible
- Limit to 30-day windows for trends/history
- Total queries on Stats tab load: 3 (metrics, chart data, history)

### Code Additions
- 3 new data loading functions (~150 lines)
- State updates (~10 lines)
- Tab click handler update (~5 lines)

---

## Summary

**Code Growth:** ~300 lines total
**New Dependencies:** None (pure CSS charts)
**Performance Impact:** Minimal (lazy loading, indexed queries, caching)
**UI Changes:**
- Main screen: Replace Last/Max with 3-chip preview
- Tabs: Workout | Stats (2 tabs)
- Stats tab: Dashboard + Management + Per-exercise sections

**Alignment with "Quickness Philosophy":**
- No libraries added (pure CSS charts)
- Lazy loading (Stats data only loads on tab open)
- Targeted updates (don't reload everything on changes)
- Minimal code growth (~300 lines for significant feature)
- Mobile-optimized layout (scrollable, collapsible sections)
