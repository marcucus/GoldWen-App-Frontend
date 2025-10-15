# Prompt Management Routes

This document describes the prompt management API routes implemented for the GoldWen app backend.

## Overview

The prompt management system allows users to select and answer prompts that will be displayed on their profiles. Users must provide exactly 3 prompt answers, each with a maximum of 150 characters.

## Routes

### 1. GET /api/v1/profiles/prompts

**Description:** Get all available active prompts

**Authentication:** Required (JWT Bearer Token)

**Response:**
```json
[
  {
    "id": "uuid",
    "text": "What makes you laugh the most?",
    "order": 1,
    "isRequired": true,
    "isActive": true,
    "category": "personality",
    "placeholder": "Share what brings joy to your life...",
    "maxLength": 500
  }
]
```

**Status Codes:**
- 200: Success

---

### 2. POST /api/v1/profiles/me/prompt-answers

**Description:** Submit initial prompt answers (must provide at least 3 answers)

**Authentication:** Required (JWT Bearer Token)

**Request Body:**
```json
{
  "answers": [
    {
      "promptId": "uuid",
      "answer": "I love comedy shows and stand-up"
    },
    {
      "promptId": "uuid",
      "answer": "Hiking in the mountains"
    },
    {
      "promptId": "uuid",
      "answer": "Spending time with family"
    }
  ]
}
```

**Validation:**
- Minimum 3 answers required
- Each answer maximum 150 characters
- All prompts must be valid and active
- Content moderation applied to all answers

**Response:**
```json
{
  "message": "Prompt answers submitted successfully"
}
```

**Status Codes:**
- 201: Created successfully
- 400: Validation error or inappropriate content
- 404: Profile not found

---

### 3. GET /api/v1/profiles/me/prompt-answers

**Description:** Get current user's prompt answers

**Authentication:** Required (JWT Bearer Token)

**Response:**
```json
[
  {
    "id": "uuid",
    "profileId": "uuid",
    "promptId": "uuid",
    "answer": "I love comedy shows and stand-up",
    "order": 1,
    "createdAt": "2025-10-13T12:00:00Z",
    "updatedAt": "2025-10-13T12:00:00Z",
    "prompt": {
      "id": "uuid",
      "text": "What makes you laugh the most?",
      "category": "personality"
    }
  }
]
```

**Status Codes:**
- 200: Success
- 404: Profile not found

---

### 4. PUT /api/v1/profiles/me/prompt-answers

**Description:** Update existing prompt answers (must provide exactly 3 answers)

**Authentication:** Required (JWT Bearer Token)

**Request Body:**
```json
{
  "answers": [
    {
      "id": "uuid",
      "promptId": "uuid",
      "answer": "Updated answer - I love comedy shows"
    },
    {
      "promptId": "uuid",
      "answer": "Hiking and outdoor activities"
    },
    {
      "promptId": "uuid",
      "answer": "Quality time with loved ones"
    }
  ]
}
```

**Validation:**
- Exactly 3 answers required
- Each answer maximum 150 characters
- All prompts must be valid and active
- Content moderation applied to all answers
- The `id` field is optional (for compatibility)

**Response:**
```json
{
  "success": true,
  "promptAnswers": [
    {
      "id": "uuid",
      "profileId": "uuid",
      "promptId": "uuid",
      "answer": "Updated answer - I love comedy shows",
      "order": 1,
      "createdAt": "2025-10-13T12:00:00Z",
      "updatedAt": "2025-10-13T14:00:00Z",
      "prompt": {
        "id": "uuid",
        "text": "What makes you laugh the most?",
        "category": "personality"
      }
    }
  ]
}
```

**Status Codes:**
- 200: Updated successfully
- 400: Validation error, inappropriate content, or incorrect number of answers
- 404: Profile not found

---

### 5. GET /api/v1/profiles/me

**Description:** Get complete user profile including prompt answers

**Authentication:** Required (JWT Bearer Token)

**Response:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "firstName": "John",
  "lastName": "Doe",
  "bio": "...",
  "photos": [...],
  "promptAnswers": [
    {
      "id": "uuid",
      "promptId": "uuid",
      "prompt": {
        "id": "uuid",
        "text": "What makes you laugh the most?",
        "category": "personality"
      },
      "answer": "I love comedy shows and stand-up",
      "order": 1
    }
  ]
}
```

**Status Codes:**
- 200: Success
- 404: Profile not found

---

## Business Rules

1. **Minimum Requirements:**
   - Users must provide at least 3 prompt answers (enforced in POST)
   - Users must provide exactly 3 prompt answers when updating (enforced in PUT)

2. **Character Limit:**
   - Each answer is limited to 150 characters maximum
   - This is validated at both DTO level (class-validator) and service level

3. **Content Moderation:**
   - All prompt answers are automatically moderated
   - Inappropriate content will be rejected with a clear reason

4. **Profile Completion:**
   - Prompt answers are part of the profile completion criteria
   - The system automatically recalculates profile completion status after updates

5. **Prompt Validation:**
   - Only active prompts can be answered
   - All submitted prompt IDs must exist in the database

## Implementation Details

### DTOs

- `PromptAnswerDto`: Used for POST requests (minimum 3 answers)
- `UpdatePromptAnswerDto`: Used for PUT requests (includes optional id field)
- `UpdatePromptAnswersDto`: Wrapper for PUT requests (exactly 3 answers)
- `SubmitPromptAnswersDto`: Wrapper for POST requests (minimum 3 answers)

### Service Methods

- `getPrompts()`: Retrieve all active prompts
- `getUserPromptAnswers(userId)`: Get user's current answers
- `submitPromptAnswers(userId, dto)`: Create initial answers
- `updatePromptAnswers(userId, dto)`: Update existing answers

### Validation Flow

1. DTO validation (class-validator)
2. Count validation (3 answers for PUT, min 3 for POST)
3. Content moderation
4. Prompt existence and active status check
5. Database transaction
6. Profile completion status update

## Testing

Comprehensive tests are available in:
- `main-api/src/modules/profiles/tests/update-prompt-answers.spec.ts`

Test coverage includes:
- Successful updates
- Validation errors (count, length, content)
- Invalid prompts
- Missing profiles
- Content moderation
- Backward compatibility (optional id field)
