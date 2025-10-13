# Integration Guide - Report Feature

This guide shows how to integrate the report feature into existing pages like profile details and chat.

## Option 1: Using ReportDialog (existing - quick modal)

The `ReportDialog` is already integrated in some places. It's a modal dialog that's good for quick, in-context reporting.

### Example from ProfileDetailPage

```dart
import '../widgets/report_dialog.dart';

void _showReportDialog(BuildContext context, MatchProfile profile) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      targetUserId: profile.id,
      targetUserName: profile.name,
    ),
  );
}
```

### Usage in AppBar

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.flag),
    onPressed: () => _showReportDialog(context, profile),
  ),
],
```

## Option 2: Using ReportPage (new - full screen)

The new `ReportPage` provides a full-screen experience with better space for descriptions and explanations.

### Basic Integration

```dart
import '../../reports/pages/report_page.dart';

void _navigateToReportPage(BuildContext context, MatchProfile profile) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReportPage(
        targetUserId: profile.id,
        targetUserName: profile.name,
      ),
    ),
  );
}
```

### Usage in Menu

```dart
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'report') {
      _navigateToReportPage(context, profile);
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'report',
      child: Row(
        children: [
          Icon(Icons.report, color: Colors.red),
          SizedBox(width: 8),
          Text('Signaler ce profil'),
        ],
      ),
    ),
  ],
)
```

## Option 3: Reporting Messages in Chat

For reporting messages in a chat context, include the messageId and chatId:

### Using ReportDialog

```dart
import '../../matching/widgets/report_dialog.dart';

void _reportMessage(BuildContext context, Message message, User sender) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      targetUserId: sender.id,
      targetUserName: sender.name,
      messageId: message.id,
      chatId: message.chatId,
    ),
  );
}
```

### Using ReportPage

```dart
import '../../reports/pages/report_page.dart';

void _reportMessage(BuildContext context, Message message, User sender) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReportPage(
        targetUserId: sender.id,
        targetUserName: sender.name,
        messageId: message.id,
        chatId: message.chatId,
      ),
    ),
  );
}
```

### In Chat Message Menu

```dart
GestureDetector(
  onLongPress: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Signaler ce message'),
              onTap: () {
                Navigator.pop(context);
                _reportMessage(context, message, sender);
              },
            ),
            // Other menu items...
          ],
        ),
      ),
    );
  },
  child: MessageBubble(message: message),
)
```

## When to Use Which?

### Use ReportDialog when:
- ✅ Space is limited (mobile, small screens)
- ✅ Quick action is preferred
- ✅ User is already in the flow (viewing profile, chatting)
- ✅ Minimal context switching desired

### Use ReportPage when:
- ✅ More space for detailed description is needed
- ✅ User is specifically seeking the report function
- ✅ Better accessibility is required
- ✅ User might need time to gather thoughts/details

## Adding to Navigation Routes

If using go_router, add the report page to your routes:

```dart
GoRoute(
  path: '/report',
  name: 'report',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return ReportPage(
      targetUserId: extra['targetUserId'] as String,
      targetUserName: extra['targetUserName'] as String?,
      messageId: extra['messageId'] as String?,
      chatId: extra['chatId'] as String?,
    );
  },
),
```

Usage:
```dart
context.pushNamed('report', extra: {
  'targetUserId': profile.id,
  'targetUserName': profile.name,
});
```

## Testing Checklist

When integrating the report feature, verify:

- [ ] Report button is visible and accessible
- [ ] Correct userId is passed
- [ ] For messages: messageId and chatId are passed
- [ ] User sees success message after reporting
- [ ] Duplicate reports are prevented
- [ ] Error handling works (network errors, etc.)
- [ ] Navigation back works correctly
- [ ] UI remains accessible during submission

## Provider Setup

Ensure ReportProvider is available in your widget tree:

```dart
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(create: (_) => ReportProvider()),
  ],
  child: MyApp(),
)
```

## Accessibility Considerations

- Ensure report buttons have semantic labels
- Provide keyboard navigation support
- Use appropriate color contrast for report indicators
- Test with screen readers

Example with semantics:
```dart
Semantics(
  label: 'Signaler ce profil',
  hint: 'Ouvre le formulaire de signalement',
  child: IconButton(
    icon: const Icon(Icons.flag),
    onPressed: () => _navigateToReportPage(context, profile),
  ),
)
```
