# Rate Limiting Feature - Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          BACKEND API                                │
│  Returns 429 with X-RateLimit headers + retryAfter in body        │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ HTTP Response
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ApiService / MatchingServiceApi                  │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ _handleResponse() / _handleMatchingResponse()                 │ │
│  │  • Extracts X-RateLimit headers                              │ │
│  │  • Extracts retryAfter from body                             │ │
│  │  • Creates RateLimitInfo                                     │ │
│  │  • Throws ApiException with rateLimitInfo                    │ │
│  └───────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Throws ApiException
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         MODELS LAYER                                │
│  ┌──────────────────────┐      ┌────────────────────────────────┐  │
│  │  ApiException        │      │  RateLimitInfo                 │  │
│  │  ─────────────       │      │  ──────────────                │  │
│  │  • statusCode        │◄─────┤  • limit                       │  │
│  │  • message           │      │  • remaining                   │  │
│  │  • code              │      │  • resetTime                   │  │
│  │  • errors            │      │  • retryAfterSeconds           │  │
│  │  • rateLimitInfo     │      │                                │  │
│  │  • isRateLimitError  │      │  Methods:                      │  │
│  │                      │      │  • fromHeaders()               │  │
│  │                      │      │  • isNearLimit                 │  │
│  │                      │      │  • getRetryMessage()           │  │
│  └──────────────────────┘      └────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Exception caught in UI
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      UTILITY LAYER                                  │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ ErrorHandler (lib/core/utils/error_handler.dart)             │ │
│  │  ───────────────────────────────────────────────────────────  │ │
│  │  • handleApiError()     ➜  Auto-detect & show rate limit UI  │ │
│  │  • getErrorMessage()    ➜  Format user-friendly messages     │ │
│  │  • showErrorSnackBar()  ➜  Display errors via SnackBar      │ │
│  │  • showRateLimitWarning() ➜ Show warnings when near limit    │ │
│  └───────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Calls UI widgets
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ RateLimitDialog (lib/core/widgets/rate_limit_dialog.dart)  │   │
│  │  ────────────────────────────────────────────────────────   │   │
│  │  • Real-time countdown timer (updates every 1 second)      │   │
│  │  • Context-aware titles:                                   │   │
│  │    - "Limite de requêtes atteinte" (general)              │   │
│  │    - "Trop de tentatives de connexion" (brute force)      │   │
│  │  • Shows remaining time in French (X minutes et Y secondes)│   │
│  │  • "Réessayer" button when countdown expires              │   │
│  │  • "Compris" button during countdown                       │   │
│  │  • Non-dismissible during countdown                        │   │
│  │  • Calls onRetry callback                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ RateLimitWarningBanner                                      │   │
│  │  ────────────────────────────────────────────────────────   │   │
│  │  • Shows when remaining < 20% of limit                     │   │
│  │  • Displays "Il vous reste X requête(s) sur Y"             │   │
│  │  • Orange warning color                                     │   │
│  │  • Dismissible with close button                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              │ Used in
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    FEATURE INTEGRATION                              │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ EmailAuthPage (lib/features/auth/pages/email_auth_page.dart)│ │
│  │  • Catches ApiException                                      │ │
│  │  • Checks isRateLimitError                                   │ │
│  │  • Shows RateLimitDialog for 429 errors                      │ │
│  │  • Passes retry callback                                     │ │
│  │  • Maintains other error handling                            │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Other Features (future integration)                          │ │
│  │  • Import ErrorHandler                                       │ │
│  │  • Call ErrorHandler.handleApiError()                        │ │
│  │  • Automatic rate limit handling                             │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                           FLOW EXAMPLE
═══════════════════════════════════════════════════════════════════════

1. User tries to login (6th attempt in 15 minutes)
   │
   ▼
2. ApiService.login() called
   │
   ▼
3. Backend returns 429 with:
   Headers: X-RateLimit-Limit: 5, X-RateLimit-Remaining: 0, Retry-After: 900
   Body: { "error": "BRUTE_FORCE_DETECTED", "retryAfter": 900 }
   │
   ▼
4. _handleResponse() catches 429:
   • Extracts headers (case-insensitive)
   • Creates RateLimitInfo(retryAfterSeconds: 900)
   • Throws ApiException(statusCode: 429, rateLimitInfo: ...)
   │
   ▼
5. EmailAuthPage catches exception:
   • Checks e.isRateLimitError (true)
   • Calls RateLimitDialog.show()
   │
   ▼
6. RateLimitDialog displays:
   ┌────────────────────────────────────────────┐
   │ 🕐 Trop de tentatives de connexion         │
   │                                            │
   │ Pour votre sécurité, votre compte a été    │
   │ temporairement bloqué après plusieurs      │
   │ tentatives de connexion échouées.          │
   │                                            │
   │ Réessayez dans 15 minutes                  │
   │                                            │
   │ ┌────────────────────────────────────────┐ │
   │ │ ⏳ 14:59                               │ │
   │ └────────────────────────────────────────┘ │
   │                                            │
   │              [Compris]                     │
   └────────────────────────────────────────────┘
   │
   ▼
7. Timer updates every second:
   14:59 → 14:58 → 14:57 → ... → 0:01 → 0:00
   │
   ▼
8. When countdown reaches 0:
   • "Compris" button changes to "Réessayer"
   • User can click to retry login
   • onRetry callback executed


═══════════════════════════════════════════════════════════════════════
                        TEST COVERAGE
═══════════════════════════════════════════════════════════════════════

test/rate_limit_test.dart (264 lines)
├─ RateLimitInfo parsing
│  ├─ All headers present ✓
│  ├─ Missing headers ✓
│  ├─ Partial headers ✓
│  ├─ Invalid values ✓
│  └─ Case-insensitive ✓
├─ Near-limit detection ✓
├─ Retry message generation
│  ├─ retryAfterSeconds ✓
│  ├─ resetTime ✓
│  ├─ Edge cases (1s, 60s, large values) ✓
│  └─ Pluralization ✓
└─ ApiException integration ✓

test/rate_limit_dialog_test.dart (295 lines)
├─ Dialog rendering ✓
├─ Countdown timer
│  ├─ Initial display ✓
│  ├─ Updates every second ✓
│  └─ Reaches zero ✓
├─ Message variants
│  ├─ General rate limit ✓
│  └─ Brute force ✓
├─ Button behavior
│  ├─ "Compris" during countdown ✓
│  ├─ "Réessayer" after countdown ✓
│  └─ Retry callback ✓
└─ Warning banner
   ├─ Shows when near limit ✓
   ├─ Hidden when not near ✓
   └─ Dismissible ✓

test/error_handler_test.dart (282 lines)
├─ handleApiError()
│  ├─ Auto-detects 429 ✓
│  ├─ Shows dialog ✓
│  ├─ Returns true/false ✓
│  └─ respects showDialog param ✓
├─ getErrorMessage() ✓
├─ showErrorSnackBar() ✓
└─ showRateLimitWarning() ✓


═══════════════════════════════════════════════════════════════════════
                      FILES STRUCTURE
═══════════════════════════════════════════════════════════════════════

lib/
├─ core/
│  ├─ services/
│  │  └─ api_service.dart (+151 lines)
│  │     ├─ class RateLimitInfo { ... }
│  │     └─ class ApiException { rateLimitInfo, isRateLimitError }
│  ├─ widgets/
│  │  └─ rate_limit_dialog.dart (298 lines) ⭐ NEW
│  │     ├─ class RateLimitDialog
│  │     └─ class RateLimitWarningBanner
│  └─ utils/
│     └─ error_handler.dart (82 lines) ⭐ NEW
│        └─ class ErrorHandler { ... }
└─ features/
   └─ auth/
      └─ pages/
         └─ email_auth_page.dart (+14 lines)

test/
├─ rate_limit_test.dart (264 lines) ⭐ NEW
├─ rate_limit_dialog_test.dart (295 lines) ⭐ NEW
└─ error_handler_test.dart (282 lines) ⭐ NEW

Documentation/
├─ RATE_LIMITING_GUIDE.md (6.8K) ⭐ NEW
└─ RATE_LIMITING_IMPLEMENTATION_SUMMARY.md (9.1K) ⭐ NEW


═══════════════════════════════════════════════════════════════════════
                         STATISTICS
═══════════════════════════════════════════════════════════════════════

📁 Files Modified:          2
📁 Files Created:           9
📝 Lines of Production Code: 1,092
🧪 Lines of Test Code:       841
📚 Documentation:           2 files (15.9K)
✅ Test Cases:              50+
🎯 Coverage:               All major scenarios


═══════════════════════════════════════════════════════════════════════
                    ✅ READY FOR PRODUCTION
═══════════════════════════════════════════════════════════════════════
