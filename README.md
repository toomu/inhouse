# Inhouse

A small shopping list (groceries, hardware, anything) hosted on GitHub Pages, with login and sync via Supabase.

- Multiple lists (Groceries, Hardware, …)
- Items auto-sorted into aisles/categories, with quantities
- Check off items as you shop; "Clear checked" when done (with undo)
- Suggestions from things you've bought before
- Share/copy the remaining items as text
- Export/import a JSON backup
- Installable on your phone (Add to Home Screen) and works offline

- Email + password login; lists sync live across all your devices

## Backend

Data lives in the Supabase project `inhouse` (tables `lists`, `items`, `history`; see `supabase/schema.sql`).
Row-level security restricts every row to the signed-in user. The key in `index.html` is the public
publishable key, which is safe to ship in a static site.
