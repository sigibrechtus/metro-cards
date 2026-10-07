# Cartes Métro Paris

A lightweight, mobile-friendly Paris transit card tracker. Card data is stored locally by default and can be synchronized to a separate Supabase project with individual email/password accounts.

## Supabase setup

1. The dedicated **metro-cards-paris** project is active in the Paris region (`eu-west-3`), project ref `shntwqeowkuvtdfwpvlh`.
2. The [schema migration](supabase/schema.sql) has already been applied.
3. The app is configured with this project's URL and **publishable key**. The service-role key is never used in the browser.
4. After GitHub Pages is deployed, set the Supabase Auth **Site URL** and allowed redirect URL to `https://sigibrechtus.github.io/metro-cards/`.

The database uses row-level security. Each account can read and modify only rows with its own user ID. The browser only uses the publishable key; it cannot bypass those policies.

## Sign in and remember me

Open **Menu → Connexion / compte**. Create an account or sign in. The “Rester connecté” option stores the session on the device for automatic sign-in next time. If unchecked, the session is kept only in memory and ends when the page/app closes.

The first sign-in loads cloud cards. If the account has no cloud cards, existing local cards are uploaded once. Further card changes are saved locally immediately and synchronized to Supabase after a short debounce. Export/import remains available as a backup.

## GitHub Pages deployment

The repository includes [a GitHub Actions workflow](.github/workflows/deploy-pages.yml). To publish:
1. Open **Settings → Pages** in the repository.
2. Set **Source** to **GitHub Actions**.
3. Push to `main` or run **Deploy Metro Cards to GitHub Pages** from the Actions tab.

The workflow copies only `index.html` into the Pages artifact. Expected site URL: `https://sigibrechtus.github.io/metro-cards/`. Set that URL as Supabase Auth's Site URL and allowed redirect URL after the first deployment.

GitHub Pages sites are publicly reachable, even when their source repository is private. GitHub's current plan rules allow Pages for private repositories on Pro/Team/Enterprise; GitHub Free requires a public repository. Keep this source repo private and ensure the account plan supports Pages for private repos. The app data remains protected by Supabase authentication and RLS.

## Local preview

Serve the repository root with any static HTTP server, for example `python3 -m http.server 8000`, then open `http://localhost:8000`. Avoid opening the file directly with `file://` because browser auth redirects and module loading may not work.
