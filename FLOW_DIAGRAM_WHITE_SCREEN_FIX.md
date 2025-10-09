# Flow Diagram - Registration to Questionnaire

## Before Fix (White Screen Issue) ❌

```
┌─────────────────┐
│   User Signs Up │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Navigate to    │
│  /questionnaire │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Page loads with │
│  _isLoading=true│
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Load questions from API │
└────────┬────────────────┘
         │
         ▼
    ┌────┴────┐
    │         │
    ▼         ▼
SUCCESS?    FAIL / EMPTY
    │         │
    │         ▼
    │    ┌─────────────────┐
    │    │ _isLoading=false│
    │    │ _error=null     │
    │    │ _questions=[]   │
    │    └────────┬────────┘
    │             │
    │             ▼
    │    ┌──────────────────┐
    │    │ Build PageView   │
    │    │ itemCount: 0     │
    │    └────────┬─────────┘
    │             │
    │             ▼
    │    ┌──────────────────┐
    │    │  WHITE SCREEN ❌  │
    │    │  User is stuck   │
    │    └──────────────────┘
    │
    ▼
┌─────────────────┐
│ Show questions  │
│ (if no ListView │
│  render issue)  │
└─────────────────┘
```

## After Fix (No White Screen) ✅

```
┌─────────────────┐
│   User Signs Up │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Navigate to    │
│  /questionnaire │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Page loads with │
│  _isLoading=true│
└────────┬────────┘
         │
         ▼
┌──────────────────┐
│ Show Loading UI ✅│
│  (Spinner)        │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────┐
│ Load questions from API │
└────────┬────────────────┘
         │
         ▼
    ┌────┴─────┬──────────┬──────────┐
    │          │          │          │
    ▼          ▼          ▼          ▼
 SUCCESS     ERROR     EMPTY      TIMEOUT
    │          │          │          │
    │          │          │          │
    │          ▼          ▼          ▼
    │    ┌─────────────────────────────┐
    │    │ _isLoading=false            │
    │    │ _error=<message>            │
    │    │ OR _questions=[]            │
    │    └────────┬────────────────────┘
    │             │
    │             ▼
    │    ┌───────┴────────┐
    │    │                │
    │    ▼                ▼
    │ ERROR?          EMPTY?
    │    │                │
    │    ▼                ▼
    │ ┌────────────┐  ┌────────────┐
    │ │ Show Error │  │ Show Empty │
    │ │ Message UI │  │ State UI   │
    │ │ + Retry    │  │ + Retry    │
    │ └────────────┘  └────────────┘
    │       ✅              ✅
    │
    ▼
┌─────────────────┐
│ Check if empty? │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  NOT EMPTY  EMPTY
    │         │
    │         ▼
    │    ┌────────────┐
    │    │ Show Empty │
    │    │ State UI   │
    │    │ + Retry    │
    │    └────────────┘
    │         ✅
    │
    ▼
┌─────────────────────┐
│ Build PageView with │
│ questions.length    │
│ items               │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Build each question │
│ with fixed ListView │
│ (shrinkWrap+physics)│
└────────┬────────────┘
         │
         ▼
    ┌────┴─────┬───────────┐
    │          │           │
    ▼          ▼           ▼
MULTIPLE    SCALE      BOOLEAN
 CHOICE    (1-10)
    │          │           │
    │          ▼           │
    │    ┌─────────────┐  │
    │    │ Dynamic Min │  │
    │    │ Dynamic Max │  │
    │    │ Wrap Layout │  │
    │    └─────────────┘  │
    │          ✅          │
    │                     │
    └──────────┬──────────┘
               │
               ▼
        ┌─────────────┐
        │   QUESTIONS │
        │  DISPLAYED  │
        │      ✅      │
        └─────────────┘
```

## UI States Comparison

### Loading State
**Before:** ✅ Spinner (OK)
**After:** ✅ Spinner (OK)

### Error State
**Before:** ❌ White Screen
**After:** ✅ Error Message + Icon + Retry Button

```
┌──────────────────────────────┐
│   Questionnaire de           │
│   personnalité               │
└──────────────────────────────┘
┌──────────────────────────────┐
│                              │
│          ⚠️                  │
│      (Red Icon)              │
│                              │
│    Erreur lors du            │
│    chargement des            │
│    questions: ...            │
│                              │
│    ┌──────────────┐         │
│    │  Réessayer   │         │
│    └──────────────┘         │
│                              │
└──────────────────────────────┘
```

### Empty State
**Before:** ❌ White Screen
**After:** ✅ Empty State Message + Icon + Retry Button

```
┌──────────────────────────────┐
│   Questionnaire de           │
│   personnalité               │
└──────────────────────────────┘
┌──────────────────────────────┐
│                              │
│          📝                  │
│    (Orange Icon)             │
│                              │
│    Aucune question           │
│    disponible                │
│                              │
│    Les questions du          │
│    questionnaire n'ont       │
│    pas pu être chargées.     │
│                              │
│    ┌──────────────┐         │
│    │  Réessayer   │         │
│    └──────────────┘         │
│                              │
└──────────────────────────────┘
```

### Success State - Multiple Choice
**Before:** ✅ Works (if no ListView issue)
**After:** ✅ Works (ListView fixed)

```
┌──────────────────────────────┐
│   Question 1/10        ←     │
└──────────────────────────────┘
│████████░░░░░░░░░░░░░░│ 10%  │
└──────────────────────────────┘
┌──────────────────────────────┐
│                              │
│   Quel type d'activité       │
│   préférez-vous pour un      │
│   premier rendez-vous ?      │
│                              │
│   ┌────────────────────┐    │
│   │ Un café tranquille │ ○  │
│   └────────────────────┘    │
│                              │
│   ┌────────────────────┐    │
│   │ Activité sportive  │ ✓  │
│   └────────────────────┘    │
│   (Selected - Gold)          │
│                              │
│   ┌────────────────────┐    │
│   │ Musée/exposition   │ ○  │
│   └────────────────────┘    │
│                              │
│   (More options...)          │
│                              │
│   ┌──────────────┐           │
│   │   Suivant    │           │
│   └──────────────┘           │
└──────────────────────────────┘
```

### Success State - Scale Question
**Before:** ❌ Only 1-5 displayed
**After:** ✅ Full 1-10 scale displayed

```
┌──────────────────────────────┐
│   Question 3/10        ←     │
└──────────────────────────────┘
│█████████░░░░░░░░░░░░│ 30%   │
└──────────────────────────────┘
┌──────────────────────────────┐
│                              │
│   Sur une échelle de 1 à 10, │
│   à quel point êtes-vous     │
│   spontané(e) ?              │
│                              │
│   Évaluez de 1 à 10          │
│                              │
│   ①  ②  ③  ④  ⑤             │
│                              │
│   ⑥  ⑦  ⑧  ⑨  ⑩             │
│      (Gold if selected)      │
│                              │
│   ┌──────────────┐           │
│   │   Suivant    │           │
│   └──────────────┘           │
└──────────────────────────────┘
```

## Code Flow Comparison

### Loading Questions

**Before:**
```
loadQuestions() {
  try {
    questions = await api.get()
    if (questions.isEmpty) {
      throw Exception() // Might not be caught
    }
    setState(questions, loading=false)
  } catch {
    setState(error, loading=false)
  }
}

build() {
  if (loading) return Spinner
  if (error) return ErrorUI
  return PageView(items: questions) // ❌ Could be empty!
}
```

**After:**
```
loadQuestions() {
  try {
    questions = await api.get()
    if (questions.isEmpty) {
      print('WARNING: Empty questions')
      setState(error='No questions', loading=false)
      return // ✅ Explicit handling
    }
    print('Loaded ${questions.length} questions')
    setState(questions, loading=false)
  } catch {
    print('Error: $e')
    setState(error, loading=false)
  }
}

build() {
  if (loading) return Spinner
  if (error) return ErrorUI
  if (questions.isEmpty) return EmptyUI // ✅ New check!
  return PageView(items: questions) // ✅ Always has items
}
```

## Summary

| Scenario | Before | After |
|----------|--------|-------|
| Loading | ✅ Spinner | ✅ Spinner |
| API Error | ❌ White Screen | ✅ Error UI + Retry |
| Empty Data | ❌ White Screen | ✅ Empty UI + Retry |
| Success + ListView Issue | ❌ White Screen | ✅ Works (Fixed) |
| Success + Scale 1-10 | ❌ Shows 1-5 | ✅ Shows 1-10 |
| Success Normal | ✅ Works | ✅ Works Better |

**Result: NO MORE WHITE SCREENS! 🎉**
