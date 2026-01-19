# Equipment Tracking Design

## Overview
Add optional equipment tracking to exercises using user-customizable tags.

## Data Model

### Supabase Tables
```sql
-- Equipment types
equipment (
  id uuid primary_key,
  user_id uuid references auth.users,
  name text unique per user,
  created_at timestamp
)

-- Link exercises to equipment
exercise_equipment (
  exercise_id uuid references exercises,
  equipment_id uuid references equipment,
  primary_key (exercise_id, equipment_id)
)
```

### Storage Strategy
- Supabase is source of truth
- LocalStorage cache for performance (same pattern as exercises)
- Equipment list loaded on app init
- Offline queue support for syncing

## UI Changes

### Exercise Manager Screen
**Add Exercise Form:**
- Name input (existing)
- Workout type dropdown (existing)
- **NEW:** Multi-select equipment chips (tap to toggle)
- **NEW:** "Manage Equipment" link

**Equipment Display:**
- Exercise list: show tags under name (e.g., "Bench Press • Barbell • Bench")
- Main workout screen: no equipment shown (keep clean)
- Subtle gray styling for tags

### Equipment Management Modal
- Text input + "Add" button
- List of user's equipment with delete buttons
- Keyboard shortcuts: Enter adds, Esc clears

## Implementation Details

### Data Flow
1. Load equipment list on app init (alongside exercises)
2. When adding exercise, optionally select equipment tags
3. Save creates exercise + links to selected equipment
4. Display equipment in exercise manager only

### Edge Cases
- Equipment is optional (0+ per exercise)
- Deleting equipment shows confirmation with usage count
- Deleted equipment removes tags from exercises
- Exercises still work without equipment tags

### Performance
- Load equipment once (~10-50 items max)
- No extra queries during workout
- Cached with exercises for instant display
- Maintains "extremely fast loading" priority

### Offline Support
- Exercise + equipment saves to sync queue if offline
- Retries when connection restored (existing pattern)

## Key Principles
- User-customizable equipment list
- Optional feature - doesn't block workflow
- Minimal code addition
- Fast loading maintained
