# NoFlame Frontend

React + Vite frontend for the NoFlame fire detection system.

## Local Development

### 1. Start the Backend

```bash
cd Backend
python app.py
# Backend runs on http://localhost:5000
```

### 2. Start the Frontend

```bash
cd Frontend/vite-project
npm install
npm run dev
# Frontend runs on http://localhost:5173
```

The frontend defaults to `http://localhost:5000` for API calls, so no `.env` file is needed for local development.

## Production / Staging Deployment

For non-local deployments, set the backend URL via environment variable:

```bash
# Create .env file
cp .env.example .env

# Edit .env with your backend URL
VITE_API_URL=http://YOUR_EC2_IP:5000
```

Then build:

```bash
npm run build
# Output is in dist/ - deploy to S3 or any static host
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VITE_API_URL` | `http://localhost:5000` | Backend API URL |

## Project Structure

```
src/
├── config/
│   └── api.js        # Centralized API URL configuration
├── Api.jsx           # API client functions
├── App.jsx           # Main application component
├── Fire.jsx          # Fire animation component
└── ...
```

---

*Built with React + Vite*
