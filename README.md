# Cartes Métro Paris

A lightweight, mobile-friendly Paris transit card tracker. Card data is stored locally by default and can be synchronized to a separate Supabase project with individual email/password accounts.

## Supabase setup

1. A dedicated project has already been created: **metro-cards-paris** (Paris region, `eu-west-3`). Project ref: `shntwqeowkuvtdfwpvlh`.
2. In the Supabase SQL Editor, run [supabase/schema.sql](supabase/schema.sql).
3. In **Project Settings → API**, copy the Project URL and the publishable key. Never use the service-role key in this frontend.
4. Add these two values to the beginning of the inline script in `index.html`, replacing the empty strings:
   ```js
   const SUPABASE_URL = 'https://shntwqeowkuvtdfwpvlh.supabase.co';
   const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_e1L8IxkHctgpFMiLD9XCqA_hGTFKeV7';
   ```
5. For email confirmation, set the Supabase Auth Site URL to your deployed URL and configure the email redirect URL there. For private household use you may disable email confirmation in Auth settings after considering account recovery needs.

The database uses row-level security. Each account can read and modify only rows with its own user ID. The browser only uses the publishable key; it cannot bypass those policies.

## Sign in and remember me

Open **Menu → Connexion / compte**. Create an account or sign in. The “Rester connecté” option stores the session on the device for automatic sign-in next time. If unchecked, the session is kept only in memory and ends when the page/app closes.

The first sign-in loads cloud cards. If the account has no cloud cards, existing local cards are uploaded once. Further card changes are saved locally immediately and synchronized to Supabase after a short debounce. Export/import remains available as a backup.

## Hosting recommendation

Use **Cloudflare Pages** connected to the private GitHub repository:
- Framework preset: **None**
- Build command: leave blank
- Build output directory: `/` (repository root)
- Add custom domain only if desired

Pages serves this static app with no server function required, and Cloudflare documents unlimited static bandwidth. “Unlimited” is subject to Cloudflare’s terms and abuse controls. Free plans still have limits such as monthly build deployments and file count; Supabase also has plan quotas and may pause inactive free projects. This is therefore a practical no-cost personal deployment, not an unlimited guarantee.

## Local preview

Serve the repository root with any static HTTP server, for example `python3 -m http.server 8000`, then open `http://localhost:8000`. Avoid opening the file directly with `file://` because browser auth redirects and module loading may not work.
