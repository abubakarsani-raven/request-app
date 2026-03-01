# request_app

A new Flutter project.

## Backend / API URL

By default the app uses **production** (Railway): `https://request-app-production.up.railway.app`.

### Run against local backend (development)

- **Simulator / Emulator** (backend on your machine as `localhost:4000`):

  ```bash
  flutter run --dart-define=ENV=development
  ```

  Or use the script:

  ```bash
  ./run_dev.sh
  ```

- **Physical device** (backend on your machine; device must use your machine’s IP):

  ```bash
  flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://YOUR_IP:4000
  ```

  Replace `YOUR_IP` with your computer’s LAN IP (e.g. `192.168.1.100`). WebSocket URL is derived from the same base.

### “User not found” when using local backend

If you see **404 User not found** on requests after switching the app to the local backend, the app is still using a **JWT from production** (Railway). That token refers to a user that exists only in the production database, not in your local one.

**Fix:** In the app, **log out**, then **log in again**. The new login will hit your local backend and issue a JWT for a user in your local database.

Ensure your local backend has users (it auto-seeds on first run if the DB is empty). Example seeded accounts:

| Role   | Email                   | Password   |
|--------|-------------------------|------------|
| Admin  | admin@example.com       | 12345678   |
| Admin  | administrator@example.com| Admin@2024 |
| Driver | driver@example.com      | Driver@2024|
| Store  | storeofficer@example.com| SO@2024    |
