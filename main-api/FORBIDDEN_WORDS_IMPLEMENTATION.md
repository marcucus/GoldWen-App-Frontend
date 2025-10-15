# Forbidden Words Moderation Implementation Summary

## Overview

This implementation adds comprehensive forbidden words moderation to all user-submitted text fields in the GoldWen backend, addressing the requirements specified in the issue.

## What Was Implemented

### 1. ForbiddenWordsService (`src/modules/moderation/services/forbidden-words.service.ts`)

A new service that provides:
- **Configurable forbidden words list** via environment variables
- **Case-insensitive whole-word matching** using regex with word boundaries
- **Batch checking** for multiple texts at once
- **Clear error messages** indicating which forbidden words were found
- **Security event logging** when forbidden words are detected

### 2. Configuration Changes

**Config Interface** (`src/config/config.interface.ts`):
```typescript
forbiddenWords: {
  enabled: boolean;
  words: string[];
}
```

**Configuration** (`src/config/configuration.ts`):
```typescript
forbiddenWords: {
  enabled: process.env.FORBIDDEN_WORDS_ENABLED === 'true',
  words: process.env.FORBIDDEN_WORDS
    ? process.env.FORBIDDEN_WORDS.split(',').map((word) => word.trim())
    : [],
}
```

**Environment Variables** (`.env.example`):
```bash
FORBIDDEN_WORDS_ENABLED=false
FORBIDDEN_WORDS=spam,scam,badword,offensive phrase
```

### 3. Integration with Existing Moderation

Updated `ModerationService` to check forbidden words **before** AI moderation:
- Forbidden words check runs first for faster rejection
- If forbidden words found, returns immediately with clear error
- Otherwise, proceeds with OpenAI AI moderation
- Both individual and batch moderation supported

### 4. Text Fields Now Moderated

All the following fields are now checked for forbidden words AND AI-moderated content:

**Profile Fields** (`updateProfile`):
- Bio
- Pseudo (username)
- Job Title
- Company
- Education
- Favorite Song

**Questionnaire Answers** (`submitPersonalityAnswers`):
- Text answers (`textAnswer`)
- Multiple choice answers (`multipleChoiceAnswer`)

**Prompt Answers** (already implemented):
- All prompt response texts

### 5. API Error Responses

When forbidden words are detected, the API returns clear error messages:

**Single field rejection:**
```json
{
  "statusCode": 400,
  "message": "Content contains forbidden words: badword, offensive",
  "error": "Bad Request"
}
```

**Multiple fields rejection:**
```json
{
  "statusCode": 400,
  "message": "Profile fields rejected: bio: Content contains forbidden words: spam; pseudo: Content contains forbidden words: scam",
  "error": "Bad Request"
}
```

**Questionnaire answers:**
```json
{
  "statusCode": 400,
  "message": "Some questionnaire answers contain inappropriate content: Answer 2: Content contains forbidden words: badword",
  "error": "Bad Request"
}
```

### 6. Comprehensive Testing

Created 17 new tests for `ForbiddenWordsService`:
- Basic word detection (case-insensitive)
- Multi-word phrase detection
- Word boundary validation (no partial matches)
- Batch checking
- Disabled state behavior
- Security event logging
- Empty/whitespace handling

All moderation tests pass: **43 tests total**

### 7. Documentation Updates

**MODERATION_GUIDE.md** updated with:
- Forbidden words configuration section
- List of all moderated text fields
- Error response examples
- Logging events documentation
- Integration examples

**API Documentation** updated:
- `POST /personality-answers` - Added moderation description
- `PUT /me` - Added moderation description for all text fields

## Technical Decisions

### Why Check Forbidden Words First?

1. **Performance**: Simple regex matching is faster than AI API calls
2. **Cost**: Avoids unnecessary OpenAI API calls for obvious violations
3. **Reliability**: Works even if AI moderation is down or misconfigured

### Word Boundary Matching

Using `\b` regex boundaries ensures:
- "badword" matches in "This has badword here"
- "badword" does NOT match in "badwordish" or "notbadword"
- Proper word separation respected

### Fail-Safe Design

- If forbidden words service is disabled → passes through to AI moderation
- If AI moderation fails → content approved (safe default)
- Forbidden words check always runs when enabled (no dependencies)

## Configuration Example

To enable forbidden words moderation:

```bash
# Enable the feature
FORBIDDEN_WORDS_ENABLED=true

# Configure forbidden words (comma-separated, case-insensitive)
FORBIDDEN_WORDS=spam,scam,phishing,offensive phrase,inappropriate

# Existing AI moderation still works
MODERATION_AUTO_BLOCK=true
OPENAI_API_KEY=your-key
```

## Acceptance Criteria Met

✅ **Forbidden words list is configurable** - Via `FORBIDDEN_WORDS` environment variable
✅ **API returns clear error if forbidden word detected** - Specific error messages with found words
✅ **Documentation updated to reflect the validation** - MODERATION_GUIDE.md and API docs updated

## Files Changed

- `main-api/src/config/config.interface.ts` - Added forbiddenWords config
- `main-api/src/config/configuration.ts` - Added forbiddenWords configuration
- `main-api/src/modules/moderation/services/forbidden-words.service.ts` - New service
- `main-api/src/modules/moderation/services/moderation.service.ts` - Integrated forbidden words
- `main-api/src/modules/moderation/moderation.module.ts` - Added ForbiddenWordsService provider
- `main-api/src/modules/moderation/tests/forbidden-words.service.spec.ts` - New tests
- `main-api/src/modules/moderation/tests/moderation.service.spec.ts` - Updated tests
- `main-api/src/modules/profiles/profiles.service.ts` - Added moderation to all text fields
- `main-api/src/modules/profiles/profiles.controller.ts` - Updated API docs
- `main-api/src/modules/profiles/personality.controller.ts` - Updated API docs
- `main-api/.env.example` - Added forbidden words config
- `main-api/MODERATION_GUIDE.md` - Comprehensive documentation update

## Testing

All tests pass:
```bash
npm run test -- --testPathPatterns=moderation
# Test Suites: 4 passed, 4 total
# Tests:       43 passed, 43 total
```

Build succeeds:
```bash
npm run build
# Success
```

## Future Enhancements

Potential improvements for future versions:
- Admin UI to manage forbidden words list
- Per-category forbidden words (profile vs messages)
- Regex pattern support for advanced matching
- Whitelist/exception handling for certain contexts
- Multi-language support
