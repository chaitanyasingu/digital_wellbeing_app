# Digital Mindfulness - Version 2.0 Roadmap

## Overview

Version 2.0 introduces a **freemium model** with advanced features available through a paid subscription. The core enforcement remains free, while power users can upgrade for cloud sync, multiple time windows, and advanced analytics.

---

## Monetization Strategy

### Free Version (v1.x - Current)
- ✅ Single restriction time window (e.g., 21:00 - 10:00)
- ✅ App blocking with allowed list
- ✅ Local storage only
- ✅ Basic anti-tamper detection
- ✅ Settings lock during restrictions
- ✅ All core mindfulness features

### Premium Version (v2.x - Paid Subscription)
- ⭐ **Multiple time windows** (up to 5 periods per day)
- ⭐ **Cloud backup & sync** across devices
- ⭐ **Advanced analytics** dashboard
- ⭐ **Remote management** via web portal
- ⭐ **Custom blocking messages** per app
- ⭐ **Scheduled configuration changes**
- ⭐ **Family sharing** (manage multiple devices)
- ⭐ **Export reports** (PDF/CSV)

### Pricing
- **Starter**: Free forever (single time window)
- **Premium**: $4.99/month or $49.99/year
- **Family**: $9.99/month or $99.99/year (up to 5 devices)

---

## Version 2 Development Phases

### Phase 2.1: Multiple Time Windows (Free → Premium Migration)
**Duration:** 2-3 weeks  
**Status:** ⏳ Pending

#### Features
1. **Time Window Management UI**
   - Add/edit/delete multiple time windows
   - Visual timeline showing all active periods
   - Conflict detection (overlapping windows)
   - Enable/disable individual windows

2. **Enhanced Time Service**
   - Check multiple windows simultaneously
   - Priority system for overlapping rules
   - Different allowed apps per window (optional)

3. **Database Schema Update**
   - New `time_windows` table
   - Window ID, start time, end time, enabled status
   - Foreign key to allowed apps list (per window)

4. **Premium Gate**
   - Free users: 1 time window only
   - Premium users: Up to 5 time windows
   - Upgrade prompt when trying to add 2nd window

#### Technical Implementation
```dart
// New Model
class TimeWindow {
  final int id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> allowedApps; // Optional: per-window apps
  final bool enabled;
  final int priority; // For conflict resolution
}

// Service Enhancement
class TimeWindowService {
  List<TimeWindow> activeWindows = [];
  
  bool isCurrentTimeRestricted() {
    return activeWindows
      .where((w) => w.enabled)
      .any((w) => isTimeInWindow(now(), w));
  }
}
```

#### UI Screens
- **Time Windows List** - Show all configured windows
- **Add/Edit Window** - Configure individual window
- **Timeline View** - Visual representation of daily schedule
- **Upgrade Prompt** - Show premium features

---

### Phase 2.2: In-App Purchases & Subscription
**Duration:** 2 weeks  
**Status:** ⏳ Pending

#### Features
1. **Google Play Billing Integration**
   - Monthly subscription ($4.99)
   - Annual subscription ($49.99 - save 17%)
   - Family plan ($9.99/month)
   - 7-day free trial

2. **Subscription Management**
   - Check subscription status
   - Grace period handling
   - Restore purchases
   - Cancel anytime

3. **Premium Features Gate**
   - Check subscription before premium features
   - Elegant upgrade prompts
   - Feature comparison screen

#### Technical Implementation
```dart
// Dependencies
dependencies:
  in_app_purchase: ^3.1.13

// Subscription Service
class SubscriptionService {
  Future<bool> isPremiumUser() async;
  Future<void> purchaseSubscription(ProductId) async;
  Future<void> restorePurchases() async;
  Stream<SubscriptionStatus> get subscriptionStream;
}
```

#### Screens
- **Pricing Page** - Feature comparison & pricing
- **Subscription Management** - View/manage subscription
- **Restore Purchases** - For device changes

---

### Phase 2.3: Cloud Backend Infrastructure
**Duration:** 3-4 weeks  
**Status:** ⏳ Pending

#### Backend Stack
- **Platform:** Node.js + Express
- **Database:** PostgreSQL (user data, configs)
- **Cache:** Redis (session management)
- **Storage:** AWS S3 (backups, exports)
- **Hosting:** Railway/Render (or AWS ECS)
- **Auth:** JWT tokens + Firebase Auth

#### API Endpoints

```typescript
// User Management
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
GET    /api/v1/auth/profile

// Configuration Sync
GET    /api/v1/config/sync
POST   /api/v1/config/upload
PUT    /api/v1/config/update
DELETE /api/v1/config/reset

// Time Windows
GET    /api/v1/windows
POST   /api/v1/windows
PUT    /api/v1/windows/:id
DELETE /api/v1/windows/:id

// Analytics
GET    /api/v1/analytics/summary
GET    /api/v1/analytics/tamper-attempts
GET    /api/v1/analytics/export

// Device Management (Family Plan)
GET    /api/v1/devices
POST   /api/v1/devices/register
DELETE /api/v1/devices/:id
```

#### Database Schema

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  subscription_tier VARCHAR(50), -- 'free', 'premium', 'family'
  subscription_expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Devices table (for sync)
CREATE TABLE devices (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  device_name VARCHAR(100),
  device_id VARCHAR(255) UNIQUE,
  last_sync_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Configurations table
CREATE TABLE configurations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  time_windows JSONB, -- Array of time window objects
  allowed_apps JSONB, -- Array of allowed apps
  settings JSONB, -- Other settings
  version INT,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Sync history
CREATE TABLE sync_history (
  id UUID PRIMARY KEY,
  device_id UUID REFERENCES devices(id),
  sync_type VARCHAR(50), -- 'upload', 'download'
  status VARCHAR(50), -- 'success', 'failed'
  synced_at TIMESTAMP DEFAULT NOW()
);
```

#### Security
- ✅ JWT tokens with refresh mechanism
- ✅ Rate limiting (100 requests/hour per user)
- ✅ Input validation and sanitization
- ✅ Encrypted data at rest
- ✅ HTTPS only
- ✅ CORS configuration
- ✅ SQL injection prevention

---

### Phase 2.4: Flutter App Cloud Sync Integration
**Duration:** 2 weeks  
**Status:** ⏳ Pending

#### Features
1. **Authentication Flow**
   - Sign up / Sign in screens
   - Email verification
   - Password reset
   - Biometric login (optional)

2. **Automatic Sync**
   - Background sync every 30 minutes
   - Manual sync button
   - Sync on app startup
   - Conflict resolution (last-write-wins)

3. **Offline Support**
   - Full functionality offline
   - Queue sync when back online
   - Sync status indicator

4. **Multi-Device Management**
   - View linked devices
   - Remote device unlinking
   - Device-specific configurations (future)

#### Technical Implementation

```dart
// API Client
class CloudApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  
  Future<ConfigResponse> syncConfiguration() async;
  Future<void> uploadConfiguration(Config) async;
  Future<List<TimeWindow>> fetchTimeWindows() async;
}

// Sync Service
class SyncService {
  Timer? _syncTimer;
  
  void startAutoSync() {
    _syncTimer = Timer.periodic(
      Duration(minutes: 30),
      (_) => performSync(),
    );
  }
  
  Future<SyncResult> performSync() async {
    // 1. Check network
    // 2. Check subscription status
    // 3. Upload local changes
    // 4. Download remote changes
    // 5. Resolve conflicts
    // 6. Update local database
  }
}

// Dependencies
dependencies:
  dio: ^5.4.0  # HTTP client
  connectivity_plus: ^5.0.2  # Network status
  flutter_secure_storage: ^9.0.0  # Token storage
```

#### UI Components
- **Sync Status Banner** - Shows sync state
- **Account Screen** - User profile, subscription info
- **Device Management** - Linked devices list
- **Sync Logs** - Debug sync history

---

### Phase 2.5: Advanced Analytics Dashboard
**Duration:** 2 weeks  
**Status:** ⏳ Pending

#### Features
1. **Usage Statistics**
   - Total blocked app attempts (daily/weekly/monthly)
   - Most blocked apps
   - Peak blocking hours
   - Streak tracking (days of compliance)
   - Time saved estimate

2. **Tamper Detection Analytics**
   - Force-close attempts over time
   - Accessibility disable events
   - Pattern analysis
   - Success rate of mindful periods

3. **Visual Reports**
   - Line charts (trends)
   - Bar charts (top blocked apps)
   - Heatmap (blocking by hour/day)
   - Pie charts (time distribution)

4. **Export Options**
   - PDF reports (weekly/monthly)
   - CSV data export
   - Email scheduled reports

#### Technical Implementation

```dart
// New Models
class UsageStatistics {
  final int totalBlockedAttempts;
  final Map<String, int> blockedByApp;
  final Map<int, int> blockedByHour;
  final int currentStreak;
  final Duration timeSaved;
}

// Database Schema
CREATE TABLE blocking_events (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  app_package VARCHAR(255),
  blocked_at TIMESTAMP,
  window_id UUID REFERENCES time_windows(id)
);

// Dependencies
dependencies:
  fl_chart: ^0.66.0  # Beautiful charts
  pdf: ^3.10.7  # PDF generation
  path_provider: ^2.1.2  # File storage
```

#### Screens
- **Dashboard Home** - Key metrics overview
- **Detailed Analytics** - Deep dive charts
- **Reports** - Generate/download reports
- **Insights** - AI-generated recommendations (future)

---

### Phase 2.6: Web Portal (Premium Feature)
**Duration:** 3 weeks  
**Status:** ⏳ Pending

#### Features
1. **Remote Dashboard**
   - View all devices
   - Real-time sync status
   - Current restriction status per device

2. **Remote Configuration**
   - Modify time windows from web
   - Update allowed apps lists
   - Emergency unlock (with cooldown)

3. **Family Management** (Family Plan Only)
   - Add family members
   - View individual analytics
   - Set restrictions for children
   - Receive alerts on tamper attempts

#### Tech Stack
- **Frontend:** React + TypeScript + Tailwind CSS
- **Charts:** Recharts or Chart.js
- **State:** Redux Toolkit
- **Auth:** Firebase Auth (matches mobile)
- **Hosting:** Vercel or Netlify

#### Pages
- `/dashboard` - Overview of all devices
- `/devices/:id` - Individual device management
- `/analytics` - Detailed analytics
- `/settings` - Account & subscription
- `/family` - Family member management

---

### Phase 2.7: Enhanced Premium Features
**Duration:** 2 weeks  
**Status:** ⏳ Pending

#### Features
1. **Custom Block Messages**
   - Different messages per app
   - Motivational quotes
   - Custom images/GIFs
   - Time-based messages (morning vs night)

2. **Scheduled Configuration Changes**
   - Enable/disable time windows on specific dates
   - Vacation mode (disable all restrictions)
   - Work mode (different rules on weekdays)
   - Weekend mode

3. **Smart Suggestions** (AI-powered)
   - Recommend apps to block based on usage
   - Suggest optimal restriction times
   - Identify pattern changes
   - Encourage healthy habits

4. **Widgets**
   - Home screen widget showing current status
   - Quick access to enable/disable enforcement
   - Countdown to next mindful period

---

## Migration Path from v1.x to v2.x

### For Free Users
1. All current features continue working
2. Prompt to try premium features (7-day free trial)
3. No disruption to existing enforcement

### For Premium Users
1. Automatic cloud backup on first premium activation
2. Sync existing configuration to cloud
3. Unlock all premium features immediately

### Database Migration
```sql
-- Add premium columns to existing tables
ALTER TABLE restriction_rules ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
ALTER TABLE restriction_rules ADD COLUMN cloud_sync_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE restriction_rules ADD COLUMN last_synced_at TIMESTAMP;
ALTER TABLE restriction_rules ADD COLUMN user_id UUID;

-- Create new tables for v2 features
-- (See Phase 2.3 for full schema)
```

---

## Development Timeline

| Phase | Duration | Start Date | Status |
|-------|----------|------------|--------|
| 2.1 Multiple Time Windows | 3 weeks | TBD | ⏳ Pending |
| 2.2 IAP Integration | 2 weeks | After 2.1 | ⏳ Pending |
| 2.3 Backend Development | 4 weeks | Parallel with 2.1-2.2 | ⏳ Pending |
| 2.4 Cloud Sync (Flutter) | 2 weeks | After 2.2 + 2.3 | ⏳ Pending |
| 2.5 Analytics Dashboard | 2 weeks | After 2.4 | ⏳ Pending |
| 2.6 Web Portal | 3 weeks | After 2.4 | ⏳ Pending |
| 2.7 Enhanced Features | 2 weeks | After 2.5 | ⏳ Pending |
| **Total** | **18 weeks** (~4.5 months) | | |

---

## Technical Considerations

### Architecture Changes
```
v1.x: App → SQLite → Local Storage
v2.x: App → SQLite → Local Storage
            ↓
            → Cloud API → PostgreSQL → S3
```

### Dependencies to Add
```yaml
dependencies:
  # Subscription
  in_app_purchase: ^3.1.13
  
  # Cloud Sync
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  flutter_secure_storage: ^9.0.0
  
  # Analytics
  fl_chart: ^0.66.0
  pdf: ^3.10.7
  
  # Authentication
  firebase_auth: ^4.16.0
  google_sign_in: ^6.2.1
  
  # Widgets
  home_widget: ^0.5.0
```

### Backend Cost Estimation
- **Hosting:** $10-50/month (Railway/Render)
- **Database:** $15-30/month (PostgreSQL)
- **Storage:** $5-20/month (AWS S3)
- **Auth:** Free (Firebase)
- **CDN:** $0-10/month (Cloudflare)
- **Total:** ~$30-110/month

### Break-even Analysis
- Monthly cost: ~$70/month
- Premium price: $4.99/month
- Break-even: 15 paying users
- Target: 100 users in 6 months = $499/month revenue

---

## Success Metrics

### v2.0 Launch Goals
- 📊 1,000+ free users in first 3 months
- 💰 5% conversion to premium (50 paying users)
- ⭐ 4.5+ rating on Play Store
- 🔄 <1% churn rate per month
- 📈 30% MoM growth in first 6 months

### Premium Feature Adoption
- Multiple Time Windows: 80% of premium users
- Cloud Sync: 90% of premium users
- Analytics Dashboard: 60% of premium users
- Web Portal: 40% of premium users

---

## Risk Mitigation

### Technical Risks
- **Risk:** Backend downtime affects premium users
  - **Mitigation:** Full offline functionality, local caching
  
- **Risk:** IAP integration issues
  - **Mitigation:** Extensive testing, restore purchases flow
  
- **Risk:** Data sync conflicts
  - **Mitigation:** Last-write-wins + conflict resolution UI

### Business Risks
- **Risk:** Low conversion to premium
  - **Mitigation:** 7-day free trial, compelling premium features
  
- **Risk:** High backend costs
  - **Mitigation:** Optimize queries, implement caching, scale gradually
  
- **Risk:** Competition from free alternatives
  - **Mitigation:** Superior UX, unique features, ethical approach

---

## Next Steps

### Immediate Actions (Before Starting v2.x)
1. ✅ Complete v1.x Phase 4 testing
2. ✅ Deploy v1.x to Play Store (free version)
3. ✅ Gather user feedback (1-2 months)
4. ✅ Validate demand for premium features
5. ✅ Set up backend infrastructure
6. 🚀 Start Phase 2.1 development

### Before v2.0 Launch
- [ ] Legal: Terms of Service, Privacy Policy updates
- [ ] Google Play: In-app purchase setup
- [ ] Backend: Load testing (1000+ concurrent users)
- [ ] Security: Penetration testing
- [ ] Marketing: Landing page, demo video, blog posts
- [ ] Support: Documentation, FAQ, help center

---

## Appendix: Alternative Features Considered

These didn't make v2.0 but could be v3.0:

1. **AI Coach** - Personalized recommendations using ML
2. **Gamification** - Points, badges, leaderboards
3. **Social Features** - Share achievements, compete with friends
4. **Integrations** - Sync with Apple Health, Google Fit
5. **Voice Control** - "Hey Google, start mindful time"
6. **Wearable Support** - Manage from smartwatch
7. **Browser Extension** - Block websites on desktop
8. **Screen Time Predictions** - ML-based usage forecasting

---

**Document Version:** 1.0  
**Last Updated:** February 16, 2026  
**Author:** Digital Mindfulness Team  
**Status:** Planning Phase
