# UI Mockup: Password Confirmation Field

## Before (Without Confirmation Field)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                      ┃
┃                  Créer un compte                     ┃
┃                                                      ┃
┃     Rejoignez GoldWen pour des rencontres           ┃
┃              authentiques                            ┃
┃                                                      ┃
┃  ┌────────────────────┐  ┌────────────────────┐     ┃
┃  │ Prénom             │  │ Nom                │     ┃
┃  │ Votre prénom       │  │ Votre nom          │     ┃
┃  └────────────────────┘  └────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 📧 Email                                   │     ┃
┃  │    votre@email.com                         │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    Min 6 caractères, 1 majuscule...        │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │         Créer mon compte                   │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃      Déjà un compte ? Se connecter                   ┃
┃                                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## After (With Confirmation Field)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                      ┃
┃                  Créer un compte                     ┃
┃                                                      ┃
┃     Rejoignez GoldWen pour des rencontres           ┃
┃              authentiques                            ┃
┃                                                      ┃
┃  ┌────────────────────┐  ┌────────────────────┐     ┃
┃  │ Prénom             │  │ Nom                │     ┃
┃  │ Votre prénom       │  │ Votre nom          │     ┃
┃  └────────────────────┘  └────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 📧 Email                                   │     ┃
┃  │    votre@email.com                         │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    Min 6 caractères, 1 majuscule...        │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐ ◄── NEW!
┃  │ 🔒 Confirmer le mot de passe          👁️   │     ┃
┃  │    Confirmez votre mot de passe            │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │         Créer mon compte                   │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃      Déjà un compte ? Se connecter                   ┃
┃                                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Validation Error States

### Error: Empty Confirmation
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    ••••••••                                 │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Confirmer le mot de passe          👁️   │     ┃
┃  │                                             │     ┃  <- Empty
┃  └────────────────────────────────────────────┘     ┃
┃  ⚠️  Veuillez confirmer votre mot de passe          ┃  <- Error
┃                                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Error: Passwords Don't Match
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    ••••••••                                 │     ┃  <- Test123!
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Confirmer le mot de passe          👁️   │     ┃
┃  │    ••••••••                                 │     ┃  <- Test124! (different)
┃  └────────────────────────────────────────────┘     ┃
┃  ⚠️  Les mots de passe ne correspondent pas         ┃  <- Error
┃                                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Success: Matching Passwords
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    ••••••••                                 │     ┃  <- Test123!
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Confirmer le mot de passe          👁️   │     ┃
┃  │    ••••••••                                 │     ┃  <- Test123! (matching)
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃  <- No error
┃  ┌────────────────────────────────────────────┐     ┃
┃  │         Créer mon compte                   │     ┃
┃  └────────────────────────────────────────────┘     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Login Screen (Unchanged)

The login screen remains unchanged - no confirmation field appears:

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                      ┃
┃                  Se connecter                        ┃
┃                                                      ┃
┃        Retrouvez votre compte GoldWen               ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 📧 Email                                   │     ┃
┃  │    votre@email.com                         │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃  ┌────────────────────────────────────────────┐     ┃
┃  │ 🔒 Mot de passe                       👁️   │     ┃
┃  │    Votre mot de passe                      │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃  <- No confirmation field
┃  ┌────────────────────────────────────────────┐     ┃
┃  │            Se connecter                    │     ┃
┃  └────────────────────────────────────────────┘     ┃
┃                                                      ┃
┃      Pas encore de compte ? S'inscrire               ┃
┃                                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Key UI Features

1. **Conditional Display**: The confirmation field only appears when user is in signup mode
2. **Consistent Styling**: Same visual style as the password field above it
3. **Visibility Toggle**: Each field has its own eye icon to show/hide password
4. **Clear Labels**: "Confirmer le mot de passe" label in French
5. **Helpful Hint**: "Confirmez votre mot de passe" placeholder text
6. **Validation Feedback**: Clear error messages in red below the field
7. **Proper Spacing**: AppSpacing.lg (16px) between fields for readability

## Interactive Behavior

### Password Visibility Toggle
```
Before click:  🔒 ••••••••  👁️
After click:   🔒 Test123!  👁️
```

Both fields can be toggled independently, allowing users to:
- Verify they typed the password correctly
- Compare both fields visually when visible
- Maintain security by default (obscured)

## Validation Sequence

When user clicks "Créer mon compte":
```
1. Email validation      → ✓ Valid email format
2. Password validation   → ✓ Meets requirements (6+ chars, uppercase, special)
3. Confirmation validation → ✓ Not empty AND matches password
4. If all pass          → Submit to backend
5. If any fail          → Show error under relevant field
```
