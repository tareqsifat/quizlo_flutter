# Quizlo — Flutter App Software Development Document
### Mobile App Team · v1.0

**Framework:** Flutter  
**Language:** Dart  
**Architecture:** Clean Architecture  
**State Management:** Riverpod  
**Networking:** Dio  
**Routing:** GoRouter  
**Local Storage:** Hive

---

# 1. Core Principles

## 1.1 Clean Architecture

Architecture Layers:

```text
Presentation
   ↓
Domain
   ↓
Data
```

Rules:
- UI never directly calls APIs
- Business logic isolated from widgets
- Repository pattern mandatory
- Domain layer independent from Flutter UI

---

# 2. Project Structure

```text
lib/
├── core/
│   ├── network/
│   ├── errors/
│   ├── constants/
│   ├── utils/
│   ├── storage/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── subjects/
│   ├── exams/
│   ├── gamification/
│   ├── profile/
│   └── notifications/
│
├── shared/
└── main.dart
```

---

# 3. Feature Architecture

Each feature contains:

```text
feature/
├── data/
│   ├── datasource/
│   ├── dto/
│   ├── models/
│   └── repository/
│
├── domain/
│   ├── entities/
│   ├── repository/
│   └── usecases/
│
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── providers/
│   └── controllers/
```

---

# 4. Repository Pattern

Example:

```dart
abstract class UserRepository {
  Future<UserEntity> getProfile();
}
```

Rules:
- Repository interfaces inside domain
- Repository implementations inside data layer
- UI depends only on abstractions

---

# 5. State Management Rules

Use:
- Riverpod

Rules:
- Avoid excessive setState
- Async states must support:
  - loading
  - success
  - error
  - empty

---

# 6. Networking Rules

Use:
- Dio wrapper service

Mandatory Features:
- JWT injection
- Refresh token handling
- Error interceptors
- Request timeout
- Retry handling
- API logging

---

# 7. DTO & Entity Separation

Rules:
- API models are not entities
- UI never directly consumes DTOs

Structure:
```text
dto/
entities/
models/
```

---

# 8. Error Handling

Create:
```text
Failure
ApiException
NetworkException
ValidationException
```

Rules:
- Never expose raw API messages
- Centralized error mapper mandatory

---

# 9. Routing Rules

Use:
- GoRouter

Rules:
- Route guards mandatory
- Authentication checks centralized
- Deep linking support ready

---

# 10. Widget Rules

Rules:
- Widgets stay presentation-only
- Business logic outside widgets
- Prefer reusable widgets

Avoid:
- Giant widget trees
- Massive build methods

---

# 11. Performance Rules

Mandatory:
- Use const widgets
- Pagination for large datasets
- Lazy loading
- Dispose controllers properly
- Minimize rebuilds

---

# 12. Offline & Cache Strategy

Use:
- Hive

Cache:
- User profile
- Settings
- Static content
- Recently viewed lessons

Rules:
- Avoid unnecessary API requests
- Sync intelligently

---

# 13. Authentication Rules

Authentication via:
- Laravel Passport
- Access token
- Refresh token

Rules:
- Secure token storage
- Auto token refresh
- Logout on invalid refresh token

---

# 14. Security Rules

Mandatory:
- Obfuscate release builds
- SSL pinning if required
- Secure local storage
- Never store secrets in code

---

# 15. Environment Rules

Use:
```text
dev
staging
production
```

Never hardcode:
- URLs
- Tokens
- Firebase configs

---

# 16. API Response Standard

```json
{
  "success": true,
  "data": {},
  "message": null
}
```

---

# 17. Form Validation Rules

Rules:
- Validation logic outside widgets
- Shared validators reusable
- Use Form + Riverpod validation flow

---

# 18. Notification System

Use:
- Firebase Cloud Messaging

Features:
- Daily reminders
- Streak notifications
- Exam alerts
- League updates

---

# 19. Local Database Rules

Use:
- Hive for lightweight storage
- SQLite/Drift only if relational data needed

---

# 20. Naming Convention

```text
snake_case → file names
PascalCase → classes
camelCase → variables/functions
```

Examples:
```text
user_repository.dart
auth_provider.dart
get_profile_usecase.dart
```

---

# 21. Testing Strategy

Use:
- flutter_test
- mocktail

Tests:
- Unit tests
- Widget tests
- Integration tests

---

# 22. Build & Release Rules

Mandatory:
- Separate dev/staging/prod builds
- Flavor support
- CI/CD pipeline
- Automated APK/AAB generation

---

# 23. Analytics & Crash Reporting

Use:
- Firebase Analytics
- Firebase Crashlytics

Track:
- Retention
- Session duration
- Crash reports
- Feature usage

---

# 24. Code Generation Rules

Allowed:
- freezed
- json_serializable

Rules:
- Use consistently
- Avoid mixing manual/generated patterns

---

# 25. Development Rules Summary

Mandatory:
- Clean architecture
- Feature modularization
- Repository pattern
- Riverpod state management
- DTO/entity separation
- Centralized networking
- Centralized error handling
- Reusable widgets
- Scalable production architecture

