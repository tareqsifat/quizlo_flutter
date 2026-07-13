# Flutter Screen Mapping & Reusable Architecture

This document maps the user-facing screens in the **Quizlo** Flutter application to their corresponding Dart implementation files. It also details the reusable layouts (like Laravel layouts) and components (like Laravel components) used in the application.

---

## 1. Screen File Mapping

Here is the exact mapping of every screen in Quizlo to its implementation file:

| Screen Name | Route Path | Implementation File | Purpose / Description |
|---|---|---|---|
| **Splash Screen** | `/` | [splash_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/splash_screen.dart) | Initial loading page that displays the branding logo and verifies user authentication status to determine navigation. |
| **Onboarding Screen** | `/onboarding` | [onboarding_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/onboarding_screen.dart) | Displays introductory walkthrough slides with a continue button for first-time installations. |
| **Auth Landing Screen** | `/auth` | [auth_landing_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/auth_landing_screen.dart) | Features Google/Facebook social sign-in shortcuts and manual registration options. |
| **Sign In Screen** | `/auth/sign-in` | [sign_in_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/sign_in_screen.dart) | Custom email and password login page. Includes form validation and submission. |
| **Forgot Password Screen** | `/auth/forgot-password` | [forgot_password_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/forgot_password_screen.dart) | Form to request password recovery. Sends a verification OTP to the user's email. |
| **OTP Verification Screen** | `/auth/otp` | [otp_verification_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/otp_verification_screen.dart) | Numeric verification screen where users input the received 6-digit OTP code. |
| **Create Password Screen** | `/auth/create-password` | [create_new_password_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/auth/presentation/pages/create_new_password_screen.dart) | Form to set up and confirm a new password after a successful password recovery flow. |
| **Stack Selection Screen** | `/exam-type-selection` | [stack_selection_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/exam_type/presentation/pages/stack_selection_screen.dart) | First-time choice screen showing preparation paths (e.g., BCS, SSC, HSC, IELTS) fetched dynamically from the API. |
| **Subject Selection Screen** | `/home` | [subject_selection_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/dashboard/presentation/pages/subject_selection_screen.dart) | Displays available topics and chapters categorized by subjects. Serves as the primary Dashboard. |
| **Discover Screen** | `/discover` | [discover_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/dashboard/presentation/pages/discover_screen.dart) | Lets users search, explore, and find specific courses or model tests. |
| **Quiz Loading Screen** | `/quiz/loading` | [quiz_loading_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/quiz_engine/presentation/pages/quiz_loading_screen.dart) | Intermediate spinner fetching lessons, questions, and parameters before starting a session. |
| **Quiz Session Screen** | `/quiz/session` | [quiz_session_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/quiz_engine/presentation/pages/quiz_session_screen.dart) | The core quiz taking screen. Displays questions, handles answers, options, and timer. |
| **Quiz Completed Screen (Result)** | `/quiz/completed` | [quiz_completed_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/quiz_engine/presentation/pages/quiz_completed_screen.dart) | Results page summarizing user performance (accuracy, time taken, score). |
| **Profile Screen** | `/profile` | [profile_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/profile/presentation/pages/profile_screen.dart) | Displays user details, stats, app preferences, and contains the logout button. |

---

## 2. Reusable Layouts (Equivalent to Laravel Layouts)

In Laravel, layouts wrap sub-views using `@yield('content')` or `<slot />`. In Flutter + GoRouter, this is achieved using **`ShellRoute`** and custom shell layouts.

### The Layout: `MainShell`
*   **File:** [main_shell.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/dashboard/presentation/pages/main_shell.dart)
*   **Laravel Layout Equivalent:** `layouts/app.blade.php`

How it works:
`MainShell` defines a `Scaffold` with a persistent bottom navigation bar and accepts a `Widget child` as a constructor parameter. The `child` acts exactly like Laravel's `@yield('content')`.

```dart
class MainShell extends StatelessWidget {
  final Widget child; // Acts as @yield('content') or {{ $slot }}

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // Sub-views (Home, Profile, Discover) are injected here dynamically
      bottomNavigationBar: CustomBottomBar(),
    );
  }
}
```

This layout injection is managed inside [app_router.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/core/router/app_router.dart):
```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: AppRoutes.home, builder: (context, state) => const SubjectSelectionScreen()),
    GoRoute(path: AppRoutes.discover, builder: (context, state) => const DiscoverScreen()),
    // ...
  ],
)
```

---

## 3. Reusable Components (Equivalent to Laravel Blade Components)

In Laravel, reusable UI widgets are written as Blade components:
```html
<!-- button.blade.php -->
<button class="btn btn-{{ $variant }}">{{ $label }}</button>

<!-- Usage -->
<x-button variant="primary" label="Continue" />
```

In Flutter, these are classes that extend `StatelessWidget` or `StatefulWidget`, taking inputs through their constructor parameters.

### Reusable UI Widgets in Quizlo:
All global, reusable components reside in `lib/core/widgets/`.

#### 1. Custom Button: `AppButton`
*   **File:** [app_button.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/core/widgets/app_button.dart)
*   **Blade Component equivalent:** `<x-app-button>`
*   Provides pressable 3D shadows (Duolingo style) with built-in loading spinners and variants (primary, outlined, danger, cta, disabled).
*   **Flutter Usage Example:**
    ```dart
    AppButton(
      label: 'Continue',
      variant: AppButtonVariant.primary,
      isLoading: _loading,
      onTap: _selected.isNotEmpty ? _proceed : null,
    )
    ```

#### 2. Option Selection Tile: `AnswerOptionTile`
*   **File:** [answer_option_tile.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/core/widgets/answer_option_tile.dart)
*   Used inside [quiz_session_screen.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/features/quiz_engine/presentation/pages/quiz_session_screen.dart) for showing multiple-choice answers, providing feedback highlight (correct/wrong animation).

#### 3. Quiz Progress Bar: `QuizProgressBar`
*   **File:** [quiz_progress_bar.dart](file:///home/tareqsifat/workDirectory/Quizlo/quizlo_flutter/lib/core/widgets/quiz_progress_bar.dart)
*   An animated bar showing progression through the quiz items.
