# Admin Web App - Environment Configuration

## Environment Selection

The admin web app supports easy switching between **production** (Railway) and **development** (local) backends.

### Quick Setup

1. **Create `.env.local` file** in the `admin-web` directory:

```bash
cd admin-web
touch .env.local
```

2. **Choose your environment** by adding one of the following:

#### Option 1: Use Environment Variable (Recommended)

**For Production (Railway):**
```env
NEXT_PUBLIC_ENV=production
```

**For Development (Local):**
```env
NEXT_PUBLIC_ENV=development
```

#### Option 2: Manual URL Configuration

**For Production (Railway):**
```env
NEXT_PUBLIC_API_BASE_URL=https://request-app-production.up.railway.app
NEXT_PUBLIC_API_URL=https://request-app-production.up.railway.app
NEXT_PUBLIC_WS_URL=wss://request-app-production.up.railway.app
```

**For Development (Local):**
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:4000
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_WS_URL=ws://localhost:4000
```

### Default Configuration

If you don't create a `.env.local` file, the app will **automatically use production (Railway)**:
- API URL: `https://request-app-production.up.railway.app`
- WebSocket URL: `wss://request-app-production.up.railway.app`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_ENV` | Environment mode: `production` or `development` | `production` |
| `NEXT_PUBLIC_API_BASE_URL` | Backend API base URL (used by API routes) | Auto-selected based on ENV |
| `NEXT_PUBLIC_API_URL` | Backend API URL (used by client-side axios) | Auto-selected based on ENV |
| `NEXT_PUBLIC_WS_URL` | WebSocket URL for real-time updates | Auto-selected based on ENV |

**Note:** 
- All environment variables must be prefixed with `NEXT_PUBLIC_` to be accessible in the browser
- Setting `NEXT_PUBLIC_ENV` automatically configures all URLs
- You can override individual URLs if needed

### Configuration File

The app uses a centralized config file at `lib/config.ts` that:
- Automatically selects URLs based on `NEXT_PUBLIC_ENV`
- Defaults to Railway production URLs
- Can be overridden with individual environment variables
- Provides a single source of truth for API URLs

### Switching Environments

**Easiest way:** Just change `NEXT_PUBLIC_ENV` in `.env.local`:

```env
# Switch to development
NEXT_PUBLIC_ENV=development

# Switch to production  
NEXT_PUBLIC_ENV=production
```

Then restart your dev server:
```bash
npm run dev
```

### Testing the Connection

After setting up, start the development server:

```bash
npm run dev
```

Then navigate to `http://localhost:3000` and try logging in with:
- Email: `admin@example.com`
- Password: `12345678`

If you see any connection errors, check:
1. Railway backend is running and accessible
2. Environment variables are set correctly
3. CORS is enabled on the backend (should already be configured)
