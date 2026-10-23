# Inhouse

A small shopping list (groceries, hardware, anything) hosted on GitHub Pages, with login and sync via Supabase.

- Multiple lists (Groceries, Hardware, …)
- Items auto-sorted into aisles/categories, with quantities
- Check off items as you shop; "Clear checked" when done (with undo)
- Suggestions from things you've bought before
- Share/copy the remaining items as text
- Export/import a JSON backup
- Installable on your phone (Add to Home Screen) and works offline

- Sign in with a one-time code sent to your email
- Lists are shared by everyone in the household and sync live
- Household members are an email allowlist, managed from the ☰ menu (the first account to sign up becomes the first member)

## Backend

Data lives in the Supabase project `inhouse` (tables `lists`, `items`, `history`; see `supabase/schema.sql`).
Row-level security only lets household members (table `members`) read or write anything. The key in `index.html` is the public
publishable key, which is safe to ship in a static site.
