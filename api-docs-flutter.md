# Quizlo API Documentation — Flutter Mobile App

> **For:** Flutter Development Team (User-Facing Mobile Application)
> **Backend:** Laravel 13 · PHP 8.3 · MySQL 8 · Redis · Laravel Passport (OAuth2)
> **Base URL:** `https://api.quizlo.app/api/v1`
> **Version:** v2.0 · Updated: May 2026

---

## Table of Contents

1. [Authentication — OTP Phone Login](#1-authentication--otp-phone-login)
2. [Standard Response Format](#2-standard-response-format)
3. [Exam Types — Onboarding & Enrollment](#3-exam-types--onboarding--enrollment)
4. [User Profile](#4-user-profile)
5. [Content — Subjects, Lessons, Questions](#5-content--subjects-lessons-questions)
6. [Answer Submission](#6-answer-submission)
7. [Gamification Dashboard](#7-gamification-dashboard)
8. [Streak](#8-streak)
9. [Hearts](#9-hearts)
10. [Coins](#10-coins)
11. [League](#11-league)
12. [Model Tests & Exam Sessions](#12-model-tests--exam-sessions)
13. [Progress Tracking](#13-progress-tracking)
14. [Achievements](#14-achievements)
15. [Social](#15-social)
16. [Notifications](#16-notifications)
17. [Error Reference](#17-error-reference)
18. [Appendix — Enums & Constants](#18-appendix--enums--constants)

---

## 1. Authentication — OTP Phone Login

### Flow Overview

```
Step 1: POST /auth/send-otp    → sends OTP to user's phone
Step 2: POST /auth/verify-otp  → verifies OTP, returns access_token + refresh_token
Step 3: All future calls       → Authorization: Bearer {access_token}
Step 4: Token expired?         → POST /auth/refresh-token
```

**Token Scope for Mobile App:** `user`
All user routes require a Bearer token with the `user` scope.

---

### POST /auth/send-otp

Sends a 6-digit OTP to the provided phone number. Works for both **new registration** and **returning login** — the backend detects automatically.

**Authentication:** Not required

**Request Body (application/json)**

| Field   | Type   | Required | Validation                           | Description                           |
| ------- | ------ | -------- | ------------------------------------ | ------------------------------------- |
| `phone` | string | ✅       | Bangladeshi format: `+8801XXXXXXXXX` | User's phone number with country code |

**Example Request**

```json
{
    "phone": "+8801700000000"
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "phone": "+8801700000000",
        "purpose": "login",
        "expires_in": 300,
        "message": "OTP sent successfully."
    },
    "message": null
}
```

| Field        | Type    | Description                             |
| ------------ | ------- | --------------------------------------- |
| `phone`      | string  | Phone number the OTP was sent to        |
| `purpose`    | string  | `login` or `register`                   |
| `expires_in` | integer | Seconds until OTP expires (300 = 5 min) |

**Error Response `422`** (invalid phone format)

```json
{
    "success": false,
    "data": null,
    "message": "Validation failed",
    "errors": {
        "phone": ["The phone must be a valid Bangladeshi mobile number."]
    }
}
```

> **Flutter tip:** Display a 5-minute countdown timer after this call. Show a "Resend OTP" button when the timer hits 0.

---

### POST /auth/verify-otp

Verifies the OTP and returns Passport tokens. Creates a new user account automatically if the phone number is new.

**Authentication:** Not required

**Request Body (application/json)**

| Field      | Type   | Required | Validation         | Description                 |
| ---------- | ------ | -------- | ------------------ | --------------------------- |
| `phone`    | string | ✅       | valid phone format | Same phone used in send-otp |
| `otp_code` | string | ✅       | exactly 6 digits   | OTP received via SMS        |

**Example Request**

```json
{
    "phone": "+8801700000000",
    "otp_code": "483920"
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "token_type": "Bearer",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def502009c1a3d6...",
        "expires_in": 1296000,
        "scope": "user",
        "user": {
            "id": 1001,
            "name": "Sajid Ahmed",
            "phone": "+8801700000000",
            "email": null,
            "avatar": null,
            "district": null,
            "division": null,
            "daily_goal": 20,
            "first_session_completed": false,
            "is_new_user": true,
            "exam_types": []
        }
    },
    "message": null
}
```

| Field              | Type    | Description                                                 |
| ------------------ | ------- | ----------------------------------------------------------- |
| `access_token`     | string  | JWT token — use in `Authorization: Bearer` header           |
| `refresh_token`    | string  | Use this to get a new access token when it expires          |
| `expires_in`       | integer | Seconds until access_token expires (1296000 = 15 days)      |
| `user.is_new_user` | boolean | `true` if this is first login — redirect to onboarding flow |
| `user.exam_types`  | array   | Empty `[]` if new user — must call exam enrollment next     |

**Error Response `422`** (wrong OTP)

```json
{
    "success": false,
    "data": null,
    "message": "Invalid or expired OTP.",
    "errors": {
        "otp_code": ["The OTP is invalid or has expired."]
    }
}
```

> **Flutter tip:** Store both `access_token` and `refresh_token` in `flutter_secure_storage`. If `is_new_user` is true, navigate to the onboarding/exam-type selection screen.

---

### POST /auth/refresh-token

Exchanges an expired access token for a new one using the refresh token. No re-login needed.

**Authentication:** Not required (refresh token is the credential)

**Request Body (application/json)**

| Field           | Type   | Required | Description                         |
| --------------- | ------ | -------- | ----------------------------------- |
| `refresh_token` | string | ✅       | The refresh_token from verify-otp   |
| `grant_type`    | string | ✅       | Must be `refresh_token`             |
| `client_id`     | string | ✅       | Mobile app's Passport client ID     |
| `client_secret` | string | ✅       | Mobile app's Passport client secret |

**Example Request**

```json
{
    "grant_type": "refresh_token",
    "refresh_token": "def502009c1a3d6...",
    "client_id": "1",
    "client_secret": "MOBILE_CLIENT_SECRET"
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "token_type": "Bearer",
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
        "refresh_token": "def502009c1a3d7...",
        "expires_in": 1296000,
        "scope": "user"
    }
}
```

> **Flutter tip:** Implement a Dio interceptor that automatically calls this endpoint when a `401` response is received, then retries the original request with the new token. Refresh tokens expire in **30 days**.

---

## 2. Standard Response Format

All responses follow this consistent envelope.

### Success

```json
{
  "success": true,
  "data": { ... },
  "message": null,
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total": 35,
      "last_page": 4
    }
  }
}
```

### Error

```json
{
    "success": false,
    "data": null,
    "message": "Validation failed",
    "errors": {
        "field_name": ["Error message."]
    }
}
```

### HTTP Status Codes

| Code | Meaning           | Flutter Action                                            |
| ---- | ----------------- | --------------------------------------------------------- |
| 200  | OK                | Consume `data`                                            |
| 201  | Created           | Consume `data`, show success state                        |
| 401  | Unauthorized      | Trigger token refresh, then retry                         |
| 403  | Forbidden         | Show "access denied" screen                               |
| 404  | Not Found         | Show empty/error state                                    |
| 422  | Validation Error  | Show field-level errors from `errors` map                 |
| 429  | Too Many Requests | Show rate limit message, retry after `Retry-After` header |
| 500  | Server Error      | Show generic error toast, do not retry automatically      |

---

## 3. Exam Types — Onboarding & Enrollment

### GET /exam-types

Fetches the list of available active exam types. Call this during **onboarding** before user enrollment.

**Authentication:** Not required

**Query Parameters:** None

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "BCS Preliminary",
            "name_bn": "বিসিএস প্রিলিমিনারি",
            "code": "BCS",
            "slug": "bcs-preliminary",
            "description": "Bangladesh Civil Service preliminary examination",
            "icon": "bcs-icon",
            "sort_order": 1
        }
    ]
}
```

> **Flutter tip:** Show these as selectable cards on the onboarding screen. Allow multi-select. After selection, call `POST /user/exam-types` for each chosen type.

---

### POST /user/exam-types

Enrolls the authenticated user in an exam type.

**Authentication:** Required (`user` scope)

**Request Body (application/json)**

| Field          | Type    | Required | Validation                   | Description                                  |
| -------------- | ------- | -------- | ---------------------------- | -------------------------------------------- |
| `exam_type_id` | integer | ✅       | exists:exam_types,id         | ID of the exam type to enroll in             |
| `is_primary`   | boolean | ❌       | default: false               | Mark as primary exam type (only one allowed) |
| `target_year`  | integer | ❌       | nullable, min:2024, max:2035 | Year the user plans to sit the exam          |

**Example Request**

```json
{
    "exam_type_id": 1,
    "is_primary": true,
    "target_year": 2027
}
```

**Success Response `201 Created`**

```json
{
    "success": true,
    "data": {
        "user_id": 1001,
        "exam_type_id": 1,
        "exam_type_name": "BCS Preliminary",
        "is_primary": true,
        "target_year": 2027,
        "enrolled_at": "2026-05-29T09:00:00Z"
    },
    "message": "Successfully enrolled in BCS Preliminary."
}
```

---

### DELETE /user/exam-types/{examType}

Removes an exam type enrollment for the authenticated user.

**Authentication:** Required (`user` scope)
**Route Parameter:** `examType` — integer, exam type ID

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": null,
    "message": "Exam type enrollment removed."
}
```

---

### PATCH /user/exam-types/{examType}/set-primary

Sets a different enrolled exam type as the user's primary one. Automatically unsets the previous primary.

**Authentication:** Required (`user` scope)
**Route Parameter:** `examType` — integer, exam type ID
**Request Body:** None required.

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "exam_type_id": 1,
        "is_primary": true
    },
    "message": "Primary exam type updated."
}
```

---

## 4. User Profile

### GET /user/profile

Returns the authenticated user's full profile with enrolled exam types and basic gamification stats.

**Authentication:** Required (`user` scope)

**Query Parameters:** None

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "id": 1001,
        "name": "Sajid Ahmed",
        "phone": "+8801700000000",
        "email": null,
        "avatar": "https://cdn.quizlo.app/avatars/1001.jpg",
        "district": "Dhaka",
        "division": "Dhaka",
        "daily_goal": 20,
        "first_session_completed": true,
        "exam_types": [
            {
                "id": 1,
                "name": "BCS Preliminary",
                "name_bn": "বিসিএস প্রিলিমিনারি",
                "code": "BCS",
                "is_primary": true,
                "target_year": 2027,
                "enrolled_at": "2026-01-10T00:00:00Z"
            }
        ],
        "gamification": {
            "total_xp": 4250,
            "level": 5,
            "current_streak": 12,
            "current_hearts": 4,
            "max_hearts": 5,
            "coin_balance": 230,
            "streak_freeze_count": 2
        },
        "created_at": "2026-01-10T00:00:00Z",
        "updated_at": "2026-05-20T00:00:00Z"
    }
}
```

---

### PUT /user/profile

Updates the authenticated user's profile information.

**Authentication:** Required (`user` scope)

**Request Body (application/json)**

| Field      | Type   | Required | Validation                          | Description                |
| ---------- | ------ | -------- | ----------------------------------- | -------------------------- |
| `name`     | string | ❌       | max:100                             | Display name               |
| `email`    | string | ❌       | nullable, email, unique:users,email | Email address              |
| `avatar`   | string | ❌       | nullable, url or base64             | Avatar URL or base64 image |
| `district` | string | ❌       | nullable, max:100                   | District name              |
| `division` | string | ❌       | nullable, max:100                   | Division name              |

**Example Request**

```json
{
    "name": "Sajid Ahmed",
    "email": "sajid@example.com",
    "district": "Chittagong",
    "division": "Chittagong"
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "id": 1001,
        "name": "Sajid Ahmed",
        "email": "sajid@example.com",
        "district": "Chittagong",
        "division": "Chittagong",
        "updated_at": "2026-05-29T09:00:00Z"
    },
    "message": "Profile updated successfully."
}
```

---

### PUT /user/daily-goal

Updates the authenticated user's daily question goal.

**Authentication:** Required (`user` scope)

**Request Body (application/json)**

| Field        | Type    | Required | Validation  | Description                            |
| ------------ | ------- | -------- | ----------- | -------------------------------------- |
| `daily_goal` | integer | ✅       | in:10,20,30 | Daily questions target (10, 20, or 30) |

**Example Request**

```json
{
    "daily_goal": 30
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "daily_goal": 30
    },
    "message": "Daily goal updated."
}
```

---

## 5. Content — Subjects, Lessons, Questions

> **Important:** All content endpoints are **exam-type scoped**. Always pass `exam_type_id` as a query parameter to get the correct content for the user's active exam context.

### GET /subjects

Returns subjects available for the specified exam type.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description             |
| -------------- | ------- | -------- | ----------------------- |
| `exam_type_id` | integer | ✅       | The active exam type ID |

**Example Request**

```
GET /api/v1/subjects?exam_type_id=1
Authorization: Bearer {access_token}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 3,
            "name": "Bangladesh Affairs",
            "name_bn": "বাংলাদেশ বিষয়াবলী",
            "slug": "bangladesh-affairs",
            "icon": "bd-flag",
            "color_hex": "#006A4E",
            "total_marks": 30,
            "syllabus_note": "Covers history, geography, culture, and current affairs",
            "user_mastery_percentage": 42.5,
            "total_lessons": 12,
            "completed_lessons": 5
        },
        {
            "id": 4,
            "name": "International Affairs",
            "name_bn": "আন্তর্জাতিক বিষয়াবলী",
            "slug": "international-affairs",
            "icon": "globe",
            "color_hex": "#1A6FB4",
            "total_marks": 20,
            "syllabus_note": null,
            "user_mastery_percentage": 28.0,
            "total_lessons": 8,
            "completed_lessons": 2
        }
    ]
}
```

| Field                     | Type    | Description                                             |
| ------------------------- | ------- | ------------------------------------------------------- |
| `total_marks`             | integer | Marks allocated for this subject in the exam type       |
| `user_mastery_percentage` | float   | This user's mastery ring percentage (0.00–100.00)       |
| `total_lessons`           | integer | Total active lessons in this subject for this exam type |
| `completed_lessons`       | integer | How many lessons this user has completed                |

---

### GET /subjects/{subject}/lessons

Returns lessons for a specific subject within the active exam type context.

**Authentication:** Required (`user` scope)
**Route Parameter:** `subject` — integer, subject ID

**Query Parameters**

| Parameter      | Type    | Required | Description             |
| -------------- | ------- | -------- | ----------------------- |
| `exam_type_id` | integer | ✅       | The active exam type ID |

**Example Request**

```
GET /api/v1/subjects/3/lessons?exam_type_id=1
Authorization: Bearer {access_token}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 45,
            "title": "মুক্তিযুদ্ধের ইতিহাস",
            "title_bn": "মুক্তিযুদ্ধের ইতিহাস",
            "description": "Key events of the 1971 Liberation War",
            "difficulty": "medium",
            "question_count": 10,
            "xp_reward": 20,
            "coin_reward": 10,
            "sort_order": 1,
            "is_completed": true,
            "best_score": 80,
            "xp_earned": 20,
            "coins_earned": 10,
            "completed_at": "2026-05-20T10:00:00Z"
        },
        {
            "id": 46,
            "title": "মুজিবনগর সরকার",
            "title_bn": "মুজিবনগর সরকার",
            "description": "The provisional government during liberation war",
            "difficulty": "hard",
            "question_count": 10,
            "xp_reward": 20,
            "coin_reward": 10,
            "sort_order": 2,
            "is_completed": false,
            "best_score": null,
            "xp_earned": 0,
            "coins_earned": 0,
            "completed_at": null
        }
    ]
}
```

---

### GET /lessons/{lesson}/questions

Returns the questions for a specific lesson. The server automatically applies the **First Win Guarantee** — new users always receive easy questions first (this logic is invisible to the client).

**Authentication:** Required (`user` scope)
**Route Parameter:** `lesson` — integer, lesson ID

**Query Parameters:** None

**Example Request**

```
GET /api/v1/lessons/45/questions
Authorization: Bearer {access_token}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 101,
            "question_text": "বাংলাদেশের স্বাধীনতা ঘোষণা কত তারিখে?",
            "question_bn": "বাংলাদেশের স্বাধীনতা ঘোষণা কত তারিখে?",
            "difficulty": "easy",
            "xp_value": 10,
            "options": [
                {
                    "id": 401,
                    "option_text": "২৬ মার্চ ১৯৭১",
                    "option_text_bn": "২৬ মার্চ ১৯৭১",
                    "sort_order": 1
                },
                {
                    "id": 402,
                    "option_text": "১৬ ডিসেম্বর ১৯৭১",
                    "option_text_bn": "১৬ ডিসেম্বর ১৯৭১",
                    "sort_order": 2
                },
                {
                    "id": 403,
                    "option_text": "৭ মার্চ ১৯৭১",
                    "option_text_bn": "৭ মার্চ ১৯৭১",
                    "sort_order": 3
                },
                {
                    "id": 404,
                    "option_text": "১৭ এপ্রিল ১৯৭১",
                    "option_text_bn": "১৭ এপ্রিল ১৯৭১",
                    "sort_order": 4
                }
            ]
        }
    ]
}
```

> ⚠️ **Critical:** The `is_correct` field is **never** included in questions fetched here. Only revealed after answer submission. Showing the correct answer before submission would expose it to the client.

---

### POST /lessons/{lesson}/complete

Marks a lesson as completed. Call this **after** all questions in the lesson have been answered (do not call after each question).

**Authentication:** Required (`user` scope)
**Route Parameter:** `lesson` — integer, lesson ID

**Request Body (application/json)**

| Field          | Type    | Required | Validation           | Description                        |
| -------------- | ------- | -------- | -------------------- | ---------------------------------- |
| `exam_type_id` | integer | ✅       | exists:exam_types,id | The active exam type context       |
| `score`        | integer | ✅       | min:0, max:100       | Percentage score (e.g. 80 for 80%) |

**Example Request**

```json
{
    "exam_type_id": 1,
    "score": 80
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "lesson_id": 45,
        "score": 80,
        "xp_earned": 20,
        "coins_earned": 10,
        "total_xp": 4270,
        "coin_balance": 240,
        "is_first_completion": true,
        "achievements_unlocked": [
            {
                "id": 3,
                "key": "first_lesson",
                "title": "First Step",
                "title_bn": "প্রথম পদক্ষেপ",
                "icon": "footstep",
                "xp_reward": 50
            }
        ]
    },
    "message": "Lesson completed! Well done!"
}
```

---

## 6. Answer Submission

### POST /questions/answer

Submits a user's answer to a question. This is the **most critical endpoint** — it triggers the entire gamification pipeline via queued events.

**Authentication:** Required (`user` scope)

> **Middleware applied:** `EnsureUserHasHearts` — returns `403` if user has 0 hearts.
> **Middleware applied:** `EnsureUserEnrolledInExamType` — validates exam_type_id enrollment.

**Request Body (application/json)**

| Field                | Type    | Required | Validation                                  | Description                          |
| -------------------- | ------- | -------- | ------------------------------------------- | ------------------------------------ |
| `exam_type_id`       | integer | ✅       | exists:exam_types,id, user must be enrolled | Active exam type context             |
| `question_id`        | integer | ✅       | exists:questions,id                         | Question being answered              |
| `selected_option_id` | integer | ✅       | exists:question_options,id                  | The option the user selected         |
| `session_id`         | integer | ❌       | nullable, exists:exam_sessions,id           | For model test or exam mode sessions |
| `session_type`       | string  | ✅       | in:lesson,model_test,practice,exam_mode     | Context of this answer               |
| `time_taken_ms`      | integer | ❌       | nullable, min:0, max:300000                 | Time taken to answer in milliseconds |

**Example Request**

```json
{
    "exam_type_id": 1,
    "question_id": 101,
    "selected_option_id": 401,
    "session_type": "lesson",
    "session_id": null,
    "time_taken_ms": 4200
}
```

**Success Response `200 OK`** (immediate — before queued side effects complete)

```json
{
    "success": true,
    "data": {
        "is_correct": true,
        "correct_option_id": 401,
        "explanation": "২৬ মার্চ ১৯৭১ সালে বাংলাদেশের স্বাধীনতা ঘোষণা করা হয়। বঙ্গবন্ধু শেখ মুজিবুর রহমান...",
        "xp_earned": 10,
        "total_xp": 4260,
        "streak": {
            "current": 13,
            "updated": true,
            "milestone_reached": false,
            "milestone_day": null
        },
        "hearts": {
            "current": 5,
            "max": 5,
            "deducted": false
        },
        "mastery": {
            "subject_id": 3,
            "exam_type_id": 1,
            "new_percentage": 43.0
        },
        "daily_progress": {
            "exam_type_id": 1,
            "date": "2026-05-29",
            "answered_questions": 8,
            "goal_questions": 20,
            "goal_met": false
        }
    }
}
```

**Response Fields Detail**

| Field                               | Type    | Description                                                          |
| ----------------------------------- | ------- | -------------------------------------------------------------------- |
| `is_correct`                        | boolean | Whether the selected option was correct                              |
| `correct_option_id`                 | integer | ID of the correct option (show even if wrong)                        |
| `explanation`                       | string  | Shame-free explanation text (show always, not just on wrong answers) |
| `xp_earned`                         | integer | XP awarded for this answer (0 if wrong)                              |
| `total_xp`                          | integer | User's total XP after this answer                                    |
| `streak.current`                    | integer | Updated streak count                                                 |
| `streak.updated`                    | boolean | Whether streak was incremented this answer                           |
| `streak.milestone_reached`          | boolean | `true` if hit a streak milestone (7, 14, 30, 60, 100, 365)           |
| `streak.milestone_day`              | integer | The milestone day hit, or `null`                                     |
| `hearts.current`                    | integer | Current heart count after this answer                                |
| `hearts.deducted`                   | boolean | `true` if a heart was deducted (wrong answer)                        |
| `mastery.new_percentage`            | float   | Updated mastery ring % for this subject + exam type                  |
| `daily_progress.answered_questions` | integer | Total questions answered today for this exam type                    |
| `daily_progress.goal_met`           | boolean | Whether daily goal was just met (trigger celebration animation!)     |

**Error — No Hearts `403`**

```json
{
    "success": false,
    "data": {
        "hearts": {
            "current": 0,
            "max": 5,
            "next_refill_at": "2026-05-29T10:30:00Z",
            "minutes_until_refill": 28
        }
    },
    "message": "You have no hearts left. Wait for refill or spend coins.",
    "errors": null
}
```

---

## 7. Gamification Dashboard

### GET /gamification/dashboard

Single aggregated endpoint that returns all gamification state for the home screen. Use this to populate the dashboard with one API call instead of multiple.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description              |
| -------------- | ------- | -------- | ------------------------ |
| `exam_type_id` | integer | ✅       | Active exam type context |

**Example Request**

```
GET /api/v1/gamification/dashboard?exam_type_id=1
Authorization: Bearer {access_token}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "user": {
            "id": 1001,
            "name": "Sajid Ahmed",
            "avatar": null,
            "level": 5
        },
        "xp": {
            "total_xp": 4260,
            "level": 5,
            "level_progress_percent": 52
        },
        "streak": {
            "current_streak": 13,
            "longest_streak": 30,
            "freeze_count": 2,
            "last_activity_date": "2026-05-29"
        },
        "hearts": {
            "current_hearts": 4,
            "max_hearts": 5,
            "next_refill_at": "2026-05-29T10:30:00Z",
            "minutes_until_refill": 28
        },
        "coins": {
            "balance": 230
        },
        "daily_progress": {
            "exam_type_id": 1,
            "date": "2026-05-29",
            "answered_questions": 8,
            "correct_questions": 6,
            "goal_questions": 20,
            "xp_earned_today": 80,
            "goal_met": false,
            "goal_percent": 40
        },
        "league": {
            "current_tier": "Silver",
            "current_tier_order": 2,
            "weekly_xp": 340,
            "rank_in_group": 5,
            "group_size": 30,
            "season_ends_at": "2026-06-01T00:00:00Z"
        },
        "exam_countdown": {
            "batch_label": "47th BCS",
            "exam_stage": "preliminary",
            "scheduled_date": "2027-01-15",
            "days_remaining": 231,
            "is_confirmed": true
        }
    }
}
```

---

## 8. Streak

### GET /gamification/streak

Returns the user's current streak status.

**Authentication:** Required (`user` scope)
**Query Parameters:** None

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "current_streak": 13,
        "longest_streak": 30,
        "streak_freeze_count": 2,
        "last_activity_date": "2026-05-29",
        "freeze_used_today": false
    }
}
```

---

### POST /gamification/streak/freeze

Spends one streak freeze to protect the current streak for a missed day.

**Authentication:** Required (`user` scope)
**Request Body:** None required.

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "freeze_used": true,
        "streak_freeze_count": 1,
        "current_streak": 13,
        "message": "Streak freeze applied. Your streak is protected!"
    }
}
```

**Error — No Freezes Available `200 OK`**

```json
{
    "success": false,
    "data": null,
    "message": "No streak freezes available."
}
```

> **Note:** Streak freeze can only be used if the user missed **exactly 1 day** (a 2-day gap). It cannot undo a reset. Users earn freezes at milestones or buy with coins.

---

## 9. Hearts

### GET /gamification/hearts

Returns the user's current heart count and refill timing.

**Authentication:** Required (`user` scope)

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "current_hearts": 4,
        "max_hearts": 5,
        "last_refill_at": "2026-05-29T08:00:00Z",
        "next_refill_at": "2026-05-29T08:30:00Z",
        "minutes_until_refill": 28
    }
}
```

| Field                  | Type    | Description                                                 |
| ---------------------- | ------- | ----------------------------------------------------------- |
| `current_hearts`       | integer | Current number of hearts (0–5)                              |
| `max_hearts`           | integer | Maximum hearts possible (5)                                 |
| `next_refill_at`       | string  | ISO 8601 datetime when next heart refills                   |
| `minutes_until_refill` | integer | Minutes until next auto-refill (hearts refill every 30 min) |

---

### POST /gamification/hearts/refill

Manually triggers an instant heart refill using coins. The server deducts the coin cost.

**Authentication:** Required (`user` scope)
**Request Body:** None required.

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "current_hearts": 5,
        "max_hearts": 5,
        "coins_spent": 50,
        "coin_balance": 180
    },
    "message": "Hearts refilled!"
}
```

**Error — Insufficient Coins `422`**

```json
{
    "success": false,
    "data": {
        "required_coins": 50,
        "current_balance": 30
    },
    "message": "Insufficient coins to refill hearts.",
    "errors": null
}
```

**Error — Hearts Already Full `422`**

```json
{
    "success": false,
    "data": null,
    "message": "Your hearts are already full.",
    "errors": null
}
```

---

## 10. Coins

### GET /gamification/coins

Returns the user's coin balance and recent transactions.

**Authentication:** Required (`user` scope)

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "balance": 230,
        "recent_transactions": [
            {
                "amount": 10,
                "type": "earn",
                "reason": "lesson_complete",
                "created_at": "2026-05-29T08:00:00Z"
            },
            {
                "amount": -50,
                "type": "spend",
                "reason": "extra_heart_purchase",
                "created_at": "2026-05-28T15:00:00Z"
            }
        ]
    }
}
```

---

### POST /gamification/coins/spend

Spends coins on in-app purchases (streak freezes, heart refills, hints).

**Authentication:** Required (`user` scope)

**Request Body (application/json)**

| Field    | Type   | Required | Validation                                                   | Description            |
| -------- | ------ | -------- | ------------------------------------------------------------ | ---------------------- |
| `reason` | string | ✅       | in:streak_freeze_purchase,extra_heart_purchase,hint_purchase | What to spend coins on |

**Example Request**

```json
{
    "reason": "streak_freeze_purchase"
}
```

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "reason": "streak_freeze_purchase",
        "coins_spent": 100,
        "coin_balance": 130,
        "result": {
            "streak_freeze_count": 3
        }
    },
    "message": "Streak freeze purchased!"
}
```

**Error — Insufficient Coins `422`**

```json
{
    "success": false,
    "data": {
        "required_coins": 100,
        "current_balance": 30
    },
    "message": "Insufficient coins.",
    "errors": null
}
```

---

## 11. League

### GET /league/current

Returns the user's current league standing for the active exam type's season.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "season": {
            "id": 12,
            "week_number": 22,
            "year": 2026,
            "starts_at": "2026-05-25T00:00:00Z",
            "ends_at": "2026-06-01T00:00:00Z",
            "days_remaining": 3
        },
        "user_standing": {
            "tier": "Silver",
            "tier_order": 2,
            "color_hex": "#C0C0C0",
            "weekly_xp": 340,
            "rank": 5,
            "group_size": 30,
            "promotion_spots": 10,
            "relegation_spots": 5,
            "is_safe": true,
            "is_in_promotion_zone": false,
            "is_in_relegation_zone": false
        },
        "leaderboard": [
            {
                "rank": 1,
                "user_id": 2050,
                "name": "Rashed Karim",
                "avatar": null,
                "weekly_xp": 1250,
                "is_current_user": false
            },
            {
                "rank": 5,
                "user_id": 1001,
                "name": "Sajid Ahmed",
                "avatar": null,
                "weekly_xp": 340,
                "is_current_user": true
            }
        ]
    }
}
```

| Field                   | Description                               |
| ----------------------- | ----------------------------------------- |
| `is_in_promotion_zone`  | Rank ≤ 10 → will be promoted to next tier |
| `is_in_relegation_zone` | Rank > 25 (bottom 5) → will be relegated  |
| `is_safe`               | In neither promotion nor relegation zone  |

---

### GET /league/history

Returns the user's past league seasons and promotion/relegation history.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |
| `page`         | integer | ❌       | Page number (default: 1)     |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "season_id": 11,
            "week_number": 21,
            "year": 2026,
            "tier": "Bronze",
            "weekly_xp": 520,
            "rank": 3,
            "promoted": true,
            "relegated": false,
            "ends_at": "2026-05-25T00:00:00Z"
        }
    ],
    "meta": {
        "pagination": { "current_page": 1, "per_page": 10, "total": 5 }
    }
}
```

---

## 12. Model Tests & Exam Sessions

### GET /model-tests

Lists available model tests for the given exam type.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 5,
            "title": "BCS Preliminary Mock Test #1",
            "title_bn": "বিসিএস প্রিলিমিনারি মক টেস্ট #১",
            "total_questions": 100,
            "duration_minutes": 60,
            "xp_reward": 100,
            "is_active": true,
            "user_best_score": 72.0,
            "attempt_count": 2,
            "last_attempted_at": "2026-05-20T10:00:00Z"
        }
    ]
}
```

---

### POST /model-tests/{test}/start

Starts a new model test session. Returns all questions for the test.

**Authentication:** Required (`user` scope)
**Route Parameter:** `test` — integer, model test ID

**Request Body (application/json)**

| Field          | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Example Request**

```json
{
    "exam_type_id": 1
}
```

**Success Response `201 Created`**

```json
{
    "success": true,
    "data": {
        "session": {
            "id": 2001,
            "model_test_id": 5,
            "session_type": "model_test",
            "status": "in_progress",
            "total_questions": 100,
            "duration_minutes": 60,
            "started_at": "2026-05-29T09:00:00Z",
            "expires_at": "2026-05-29T10:00:00Z"
        },
        "questions": [
            {
                "id": 101,
                "question_text": "...",
                "question_bn": "...",
                "difficulty": "medium",
                "options": [
                    { "id": 401, "option_text": "...", "sort_order": 1 },
                    { "id": 402, "option_text": "...", "sort_order": 2 },
                    { "id": 403, "option_text": "...", "sort_order": 3 },
                    { "id": 404, "option_text": "...", "sort_order": 4 }
                ]
            }
        ]
    }
}
```

> **Flutter tip:** Store `session.id` and `session.expires_at` locally. Use the `session_id` when calling `POST /questions/answer` with `session_type: "model_test"`. Display a countdown timer based on `expires_at`.

---

### POST /exam-sessions/{session}/submit

Submits a completed exam session. Call after the user answers all questions or the timer expires.

**Authentication:** Required (`user` scope)
**Route Parameter:** `session` — integer, exam session ID

**Request Body:** None required (all answers already submitted via `/questions/answer`).

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "session_id": 2001,
        "status": "completed",
        "total_questions": 100,
        "answered_count": 97,
        "correct_count": 70,
        "score_percent": 72.16,
        "xp_earned": 100,
        "total_xp": 4360,
        "completed_at": "2026-05-29T09:54:00Z"
    },
    "message": "Exam session submitted successfully."
}
```

---

### GET /exam-sessions/{session}/result

Gets the detailed result of a completed exam session.

**Authentication:** Required (`user` scope)
**Route Parameter:** `session` — integer, exam session ID

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "session_id": 2001,
        "model_test_id": 5,
        "session_type": "model_test",
        "status": "completed",
        "total_questions": 100,
        "answered_count": 97,
        "correct_count": 70,
        "score_percent": 72.16,
        "xp_earned": 100,
        "started_at": "2026-05-29T09:00:00Z",
        "completed_at": "2026-05-29T09:54:00Z",
        "time_taken_minutes": 54,
        "answers": [
            {
                "question_id": 101,
                "question_text": "বাংলাদেশের স্বাধীনতা ঘোষণা কত তারিখে?",
                "selected_option_id": 401,
                "correct_option_id": 401,
                "is_correct": true,
                "explanation": "২৬ মার্চ ১৯৭১ সালে...",
                "time_taken_ms": 4200
            }
        ],
        "subject_breakdown": [
            {
                "subject_id": 3,
                "subject_name": "Bangladesh Affairs",
                "total": 30,
                "correct": 22,
                "accuracy": 73.3
            }
        ]
    }
}
```

---

### GET /exam-countdown

Returns the next upcoming exam date and days remaining for the countdown widget.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "exam_type_id": 1,
        "batch_label": "47th BCS",
        "exam_stage": "preliminary",
        "scheduled_date": "2027-01-15",
        "days_remaining": 231,
        "is_confirmed": true,
        "note": "Based on official BPSC circular"
    }
}
```

**No Upcoming Exam `200 OK`**

```json
{
    "success": true,
    "data": null,
    "message": "No upcoming exam schedule found for this exam type."
}
```

---

## 13. Progress Tracking

### GET /progress/subjects

Returns the user's subject mastery rings for the given exam type.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "subject_id": 3,
            "exam_type_id": 1,
            "subject_name": "Bangladesh Affairs",
            "subject_name_bn": "বাংলাদেশ বিষয়াবলী",
            "color_hex": "#006A4E",
            "total_answered": 240,
            "total_correct": 150,
            "mastery_percentage": 62.5,
            "badge_earned": false,
            "badge_earned_at": null,
            "last_activity_at": "2026-05-29T09:00:00Z"
        }
    ]
}
```

| Field                | Description                                      |
| -------------------- | ------------------------------------------------ |
| `mastery_percentage` | 0.00–100.00, drives the ring animation           |
| `badge_earned`       | `true` if mastery reached 100% (show badge icon) |

---

### GET /progress/daily

Returns the user's daily goal progress for the current day.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "date": "2026-05-29",
        "exam_type_id": 1,
        "goal_questions": 20,
        "answered_questions": 8,
        "correct_questions": 6,
        "xp_earned_today": 80,
        "goal_met": false,
        "goal_percent": 40
    }
}
```

---

### GET /progress/personal-best

Returns the user's personal best statistics for a given exam type.

**Authentication:** Required (`user` scope)

**Query Parameters**

| Parameter      | Type    | Required | Description                  |
| -------------- | ------- | -------- | ---------------------------- |
| `exam_type_id` | integer | ✅       | The active exam type context |

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": {
        "exam_type_id": 1,
        "best_streak": 30,
        "total_xp_earned": 4260,
        "total_questions_answered": 1850,
        "total_correct": 1240,
        "overall_accuracy": 67.0,
        "lessons_completed": 45,
        "model_tests_completed": 8,
        "best_model_test_score": 82.5
    }
}
```

---

## 14. Achievements

### GET /achievements

Returns all achievement definitions (earned and unearned).

**Authentication:** Required (`user` scope)
**Query Parameters:** None

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "key": "streak_7",
            "title": "Week Warrior",
            "title_bn": "সপ্তাহের যোদ্ধা",
            "description": "Maintain a 7-day streak",
            "icon": "fire-7",
            "xp_reward": 100,
            "type": "streak",
            "exam_type_id": null,
            "is_earned": true,
            "earned_at": "2026-03-10T00:00:00Z"
        },
        {
            "id": 2,
            "key": "streak_30",
            "title": "Monthly Champion",
            "title_bn": "মাসিক চ্যাম্পিয়ন",
            "description": "Maintain a 30-day streak",
            "icon": "fire-30",
            "xp_reward": 300,
            "type": "streak",
            "exam_type_id": null,
            "is_earned": false,
            "earned_at": null
        }
    ]
}
```

| Field          | Description                                          |
| -------------- | ---------------------------------------------------- |
| `exam_type_id` | `null` = achievement applies to all exam types       |
| `is_earned`    | Whether the current user has earned this achievement |
| `type`         | `streak`, `subject`, `exam`, `social`, or `daily`    |

---

### GET /achievements/earned

Returns only the achievements the authenticated user has earned.

**Authentication:** Required (`user` scope)

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "key": "streak_7",
            "title": "Week Warrior",
            "title_bn": "সপ্তাহের যোদ্ধা",
            "icon": "fire-7",
            "xp_reward": 100,
            "type": "streak",
            "earned_at": "2026-03-10T00:00:00Z"
        }
    ]
}
```

---

## 15. Social

### GET /social/activity-feed

Returns a social activity feed showing recent activity from other users (for community/social features).

**Authentication:** Required (`user` scope)
**Query Parameters:** None

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "type": "achievement_earned",
            "user": {
                "id": 2050,
                "name": "Rashed Karim",
                "avatar": null
            },
            "achievement": {
                "key": "streak_30",
                "title": "Monthly Champion",
                "icon": "fire-30"
            },
            "occurred_at": "2026-05-29T08:00:00Z"
        },
        {
            "type": "league_promotion",
            "user": {
                "id": 1302,
                "name": "Nasrin Akter",
                "avatar": null
            },
            "from_tier": "Bronze",
            "to_tier": "Silver",
            "occurred_at": "2026-05-28T00:00:00Z"
        }
    ]
}
```

---

### POST /achievements/{id}/share

Records that the user shared an achievement (for analytics and potential social rewards).

**Authentication:** Required (`user` scope)
**Route Parameter:** `id` — integer, achievement ID

**Request Body:** None required.

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": null,
    "message": "Achievement share recorded."
}
```

---

## 16. Notifications

### GET /notifications

Returns the user's in-app notifications (unread + recent read).

**Authentication:** Required (`user` scope)

**Success Response `200 OK`**

```json
{
    "success": true,
    "data": [
        {
            "id": 501,
            "type": "streak_warning",
            "title": "Don't break your streak!",
            "title_bn": "আপনার স্ট্রিক ভাঙবেন না!",
            "body": "Complete at least one question today to maintain your 13-day streak.",
            "is_read": false,
            "created_at": "2026-05-29T08:00:00Z"
        },
        {
            "id": 499,
            "type": "daily_reminder",
            "title": "Time to study!",
            "title_bn": "পড়াশোনার সময়!",
            "body": "You have completed 8 of your 20 daily goals. Keep going!",
            "is_read": true,
            "created_at": "2026-05-28T08:00:00Z"
        }
    ],
    "meta": {
        "unread_count": 1
    }
}
```

---

## 17. Error Reference

### Standard Error Formats

#### 401 Unauthorized — Token Missing or Expired

```json
{
    "success": false,
    "data": null,
    "message": "Unauthenticated.",
    "errors": null
}
```

> **Flutter Action:** Trigger the refresh token flow. If refresh also fails (401), redirect to login screen.

#### 403 Forbidden — No Hearts

```json
{
    "success": false,
    "data": {
        "hearts": {
            "current": 0,
            "max": 5,
            "next_refill_at": "2026-05-29T10:30:00Z",
            "minutes_until_refill": 28
        }
    },
    "message": "You have no hearts left."
}
```

#### 403 Forbidden — Not Enrolled in Exam Type

```json
{
    "success": false,
    "data": null,
    "message": "You are not enrolled in this exam type.",
    "errors": null
}
```

#### 404 Not Found

```json
{
    "success": false,
    "data": null,
    "message": "Resource not found.",
    "errors": null
}
```

#### 422 Validation Error

```json
{
    "success": false,
    "data": null,
    "message": "Validation failed",
    "errors": {
        "selected_option_id": ["Invalid answer option."],
        "exam_type_id": ["Invalid exam type."]
    }
}
```

#### 429 Too Many Requests

```json
{
    "success": false,
    "data": null,
    "message": "Too many requests. Please wait before trying again.",
    "errors": null
}
```

> **Flutter Action:** Read `Retry-After` response header for seconds to wait. Show a rate limit message.

---

## 18. Appendix — Enums & Constants

### Difficulty Levels

| Value    | Description        |
| -------- | ------------------ |
| `easy`   | Beginner level     |
| `medium` | Intermediate level |
| `hard`   | Advanced level     |

### Session Types

| Value        | Description                   |
| ------------ | ----------------------------- |
| `lesson`     | Learning a lesson             |
| `model_test` | Taking a full model test      |
| `practice`   | Free practice mode            |
| `exam_mode`  | Timed, strict exam simulation |

### Achievement Types

| Value     | Description                         |
| --------- | ----------------------------------- |
| `streak`  | Streak milestones (7, 14, 30...)    |
| `subject` | Subject mastery achievements        |
| `exam`    | Model test performance achievements |
| `social`  | Social interaction achievements     |
| `daily`   | Daily goal achievements             |

### Coin Spend Reasons & Costs

| Reason                   | Coins Required | Result                          |
| ------------------------ | -------------- | ------------------------------- |
| `extra_heart_purchase`   | 50             | Instant full heart refill       |
| `streak_freeze_purchase` | 100            | +1 streak freeze added to count |
| `hint_purchase`          | 10             | Eliminates 1 wrong option       |

### Gamification Constants

| Constant               | Value                   | Description                        |
| ---------------------- | ----------------------- | ---------------------------------- |
| Max Hearts             | 5                       | Maximum hearts a user can have     |
| Heart Refill Time      | 30 min                  | One heart refills every 30 minutes |
| XP per correct answer  | 10                      | Base XP for answering correctly    |
| XP for lesson complete | 20                      | Bonus XP for completing a lesson   |
| XP for daily goal      | 50                      | Bonus XP when daily goal is met    |
| XP for 7-day streak    | 100                     | Milestone bonus at 7-day streak    |
| XP for 30-day streak   | 300                     | Milestone bonus at 30-day streak   |
| Streak Milestones      | 7, 14, 30, 60, 100, 365 | Days at which streak bonuses fire  |
| League Group Size      | 30                      | Users per league group             |
| Promotion Spots        | 10                      | Top 10 get promoted each week      |
| Relegation Spots       | 5                       | Bottom 5 get relegated each week   |

### League Tiers

| Order | Name     | Description   |
| ----- | -------- | ------------- |
| 1     | Bronze   | Starting tier |
| 2     | Silver   | Second tier   |
| 3     | Gold     | Third tier    |
| 4     | Platinum | Fourth tier   |
| 5     | Diamond  | Highest tier  |

### Token Validity

| Token         | Expiry  |
| ------------- | ------- |
| Access Token  | 15 days |
| Refresh Token | 30 days |

### Daily Goal Options

Users can select 10, 20, or 30 questions as their daily goal via `PUT /user/daily-goal`.

### Exam Type Scoping Note

The following data is **always exam-type scoped** and requires `exam_type_id`:

- Subjects list
- Lessons list
- Subject mastery (rings)
- Daily progress
- League standings
- Exam countdown
- Gamification dashboard

The following data is **global** (not exam-type scoped):

- XP total and level
- Streak count
- Hearts
- Coins
- Achievements

---

_Quizlo API Documentation — Flutter Mobile App · v2.0 · May 2026_
_Backend: Laravel 13 · PHP 8.3 · MySQL 8 · Redis · Laravel Passport (OAuth2)_
