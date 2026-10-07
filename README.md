# Cartes Métro Paris

A lightweight, mobile-friendly Paris transit card tracker. New users start with one empty **“Ma carte”** card and an always-visible + tile for adding more. Card data is stored locally until the user signs in to synchronize it with the dedicated Supabase project.

## Supabase setup

1. The dedicated **metro-cards-paris** project is active in the Paris region (`eu-west-3`), project ref `shntwqeowkuvtdfwpvlh`.
2. The base schema and [atomic versioned sync migration](supabase/versioned_sync.sql) have already been applied.
3. The app is configured with this project's URL and **publishable key**. The service-role key is never used in the browser.
4. After GitHub Pages is deployed, set the Supabase Auth **Site URL** and allowed redirect URL to `https://sigibrechtus.github.io/metro-cards/`.

The database uses row-level security. Each account can read and modify only rows with its own user ID. The browser only uses the publishable key; it cannot bypass those policies.

## Sign in and remember me

Open **Menu → Connexion / compte**. Create an account or sign in. The “Rester connecté” option stores the session on the device for automatic sign-in next time. If unchecked, the session is kept only in memory and ends when the page/app closes.

The in-app **Aide** menu explains how to add the site to the home screen or install it as a browser app. This creates a shortcut to the same website; sign in to the same account on each device to sync cards. An internet connection is required for syncing. If a device was offline and another device saved a newer version meanwhile, the online version wins when the offline device reconnects.

The first sign-in loads the online card set. If the account has no saved set, the local cards are uploaded. Changes are saved locally and synchronized after a short debounce. Every save checks the database revision and uses an atomic compare-and-swap operation. **If another device has already advanced the online revision, the online database wins:** the stale device reloads it and does not overwrite it. If two devices save at the same revision simultaneously, the first accepted database transaction wins; the other device reloads that result. Open devices check for updates every 8 seconds and reload newer online data. The app shows a visible local-only/offline status when data is not syncing. Closing a normal browser window alone usually does not erase local data; clearing site data, private browsing, or switching browser/device can lose it. Export/import remains available as a backup. Statistics show daily usage for the last seven days plus seven-day and 30-day totals.

## GitHub Pages deployment

The repository includes [a GitHub Actions workflow](.github/workflows/deploy-pages.yml). To publish:
1. Open **Settings → Pages** in the repository.
2. Set **Source** to **GitHub Actions**.
3. Push to `main` or run **Deploy Metro Cards to GitHub Pages** from the Actions tab.

The workflow copies only `index.html` into the Pages artifact. Expected site URL: `https://sigibrechtus.github.io/metro-cards/`. Set that URL as Supabase Auth's Site URL and allowed redirect URL after the first deployment.

GitHub Pages sites are publicly reachable, even when their source repository is private. GitHub's current plan rules allow Pages for private repositories on Pro/Team/Enterprise; GitHub Free requires a public repository. Keep this source repo private and ensure the account plan supports Pages for private repos. The app data remains protected by Supabase authentication and RLS.

## Local preview

Serve the repository root with any static HTTP server, for example `python3 -m http.server 8000`, then open `http://localhost:8000`. Avoid opening the file directly with `file://` because browser auth redirects and module loading may not work.
