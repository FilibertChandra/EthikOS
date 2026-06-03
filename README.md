# EthikOS — Social Media Mobile App

## Tech Stack
- **Mobile App:** Flutter (Dart)
- **Backend:** Node.js + Express
- **Database:** MongoDB Atlas
- **Auth:** JWT
- **Container:** Docker

## Getting Started

### Prerequisites
- Docker Desktop
- Flutter SDK
- MongoDB Atlas account

### Backend Setup
1. Clone the repo
```bash
git clone https://github.com/FilibertChandra/EthikOS.git
cd EthikOS/backend
```

2. Create `.env` file
```bash
cp .env.example .env
# Fill in your values
```

3. Run with Docker
```bash
docker compose up -d
```

### Flutter Setup
1. Install dependencies
```bash
cd social_app
flutter pub get
```

2. Update `lib/config/app_config.dart` with your backend URL

3. Run the app
```bash
flutter run
```

## API Documentation
See https://hackmd.io/LpzJcEysR4K5HKfHa11mzg?view

## Security
This app implements OWASP Top 10 mitigations including JWT authentication, bcrypt password hashing, rate limiting, XSS prevention, and NoSQL injection prevention.