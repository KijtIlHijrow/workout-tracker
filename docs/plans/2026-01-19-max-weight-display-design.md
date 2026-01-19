# Max Weight Display Feature

## Overview
Display each exercise's max weight (minimum 6 reps) next to the last set in the workout tab.

## Data Structure

Add to state:
```javascript
state.maxWeights = {}  // { exerciseId: { weight: 70, reps: 6 } }
```

Storage: In-memory only, derived from Supabase on each load.

## Query Logic

### On App Load
After loading exercises, query max weights:
```javascript
async function loadMaxWeights() {
  const { data } = await supabase
    .from('sets')
    .select('exercise_id, weight, reps')
    .eq('user_id', state.user.id)
    .gte('reps', 6)
    .order('weight', { ascending: false });

  state.maxWeights = {};
  data?.forEach(set => {
    if (!state.maxWeights[set.exercise_id]) {
      state.maxWeights[set.exercise_id] = { weight: set.weight, reps: set.reps };
    }
  });
}
```

### After Logging Set
In `saveSet()`, check if new set qualifies:
```javascript
if (reps >= 6) {
  const currentMax = state.maxWeights[currentExerciseId]?.weight || 0;
  if (weight > currentMax) {
    state.maxWeights[currentExerciseId] = { weight, reps };
  }
}
```

## UI Display

Update `renderMainScreen()` to show both last and max:
```javascript
<div class="exercise-last">
  ${last ? `Last: ${last.weight}kg × ${last.reps}` : ''}
  ${last && max ? ` | ` : ''}
  ${max ? `Max: ${max.weight}kg (${max.reps})` : ''}
</div>
```

**Example output**: `Last: 60kg × 8 | Max: 70kg (6)`

## Performance
- Single query on load (grouped by exercise)
- Smart update after logging (only if qualifies as new max)
- No localStorage overhead
