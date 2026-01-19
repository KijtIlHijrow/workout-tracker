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
