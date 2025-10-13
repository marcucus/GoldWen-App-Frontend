# Chat Expiration Feature - Visual Flow Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GoldWen Chat System                      │
│                    24-Hour Expiration                        │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│              │      │              │      │              │
│  Chat Match  │─────▶│ Active Chat  │─────▶│ Expired Chat │
│   Created    │      │  (0-24h)     │      │  (Archived)  │
│              │      │              │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
     T=0                  T=0-24h              T=24h+
```

## Detailed User Journey

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TIMELINE: 24 Hours                            │
└─────────────────────────────────────────────────────────────────────┘

T=0h                 T=22h               T=24h                T=24h+
 │                    │                   │                     │
 ├─ Match Created    ├─ Notification     ├─ Chat Expires     ├─ Archived
 │  - Timer starts   │  "2h remaining"   │  - Input disabled │  - Read-only
 │  - 24:00:00       │  - Local notif    │  - System msg     │  - Accessible
 │  - Full access    │  - Can still chat │  - Auto-archive   │  - Filterable
 │                   │                   │                    │
 ▼                   ▼                   ▼                    ▼

[  Full Chat Access  ][ Warning Period  ][ Expired ][ Archive Only ]
```

## Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User Interface Layer                         │
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
         ┌──────────▼──────────┐ ┌─────────▼──────────┐
         │   ChatListPage      │ │ ArchivedChatsPage  │
         │  (Active Chats)     │ │  (Expired Chats)   │
         └──────────┬──────────┘ └─────────┬──────────┘
                    │                       │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │     ChatPage          │
                    │  (Read/Write or RO)   │
                    └───────────┬───────────┘
                                │
┌───────────────────────────────▼───────────────────────────────┐
│                        ChatProvider                            │
│  • isChatExpired()                                            │
│  • getRemainingTime()                                         │
│  • activeConversations                                        │
│  • archivedConversations                                      │
│  • scheduleAllExpirationNotifications()                       │
└───────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
    ┌───────────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐
    │ WebSocketService │ │ ApiService │ │ LocalNotif  │
    │  (Real-time)     │ │  (REST)    │ │  Service    │
    └──────────────────┘ └────────────┘ └─────────────┘
```

## State Machine

```
                                ┌─────────────┐
                                │   CREATED   │
                                │  (Match)    │
                                └──────┬──────┘
                                       │
                                       ▼
                                ┌─────────────┐
                         ┌─────▶│   ACTIVE    │
                         │      │  (0-22h)    │
                         │      └──────┬──────┘
                         │             │
                         │             │ T=22h
                         │             ▼
                         │      ┌─────────────┐
                         │      │  EXPIRING   │
                         │      │  (22-24h)   │───┐ Notification
                         │      └──────┬──────┘   │ Sent
                         │             │          ▼
                         │             │ T=24h
                         │             ▼
                         │      ┌─────────────┐
                         │      │   EXPIRED   │
                         │      │  (Read-Only)│
                         │      └──────┬──────┘
                         │             │
                         │             ▼
                         │      ┌─────────────┐
                         └──────│  ARCHIVED   │
                                │  (Permanent)│
                                └─────────────┘

States:
• CREATED   → Timer initialized, full access
• ACTIVE    → Normal operation, can send messages
• EXPIRING  → Warning notification sent, still active
• EXPIRED   → Read-only, system message added
• ARCHIVED  → Moved to archive list, accessible for viewing
```

## Notification Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   Notification Lifecycle                     │
└─────────────────────────────────────────────────────────────┘

Chat Load                    2h Before Exp.            Expiration
    │                              │                        │
    ▼                              ▼                        ▼
┌───────┐                     ┌────────┐              ┌──────────┐
│Schedule│────Timer Delay────▶│ Show   │──Chat Exp──▶│ Cancel   │
│ Timer  │    (T-2h - now)    │ Notif  │              │ Timer    │
└───────┘                     └────────┘              └──────────┘
    │                              │                        │
    │                              ▼                        │
    │                         ┌────────┐                   │
    │                         │ User   │                   │
    │                         │ Sees   │                   │
    │                         │ Alert  │                   │
    │                         └────────┘                   │
    │                                                      │
    └──────────────── Cleanup on Dispose ─────────────────┘
```

## UI State Transitions

```
┌──────────────────────────────────────────────────────────────┐
│                    Chat UI States                             │
└──────────────────────────────────────────────────────────────┘

┌─────────────────┐        ┌─────────────────┐        ┌──────────────────┐
│  Active Chat    │        │  Expiring Soon  │        │  Expired Chat    │
│  ───────────    │        │  ─────────────  │        │  ────────────    │
│                 │        │                 │        │                  │
│  🟢 Timer       │───────▶│  🟡 Timer       │───────▶│  🔴 Timer        │
│  ⌨️  Input ON   │  T>2h  │  ⌨️  Input ON   │  T=0h  │  🚫 Input OFF    │
│  📤 Send ON     │        │  📤 Send ON     │        │  📦 Archived     │
│  💬 Full Chat   │        │  🔔 Notif Sent  │        │  👁️  Read-Only   │
│                 │        │  ⚠️  Warning    │        │  💬 View History │
└─────────────────┘        └─────────────────┘        └──────────────────┘
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Data Sources                             │
└─────────────────────────────────────────────────────────────┘
           │                        │
    ┌──────▼─────┐           ┌─────▼──────┐
    │  Backend   │           │   Local    │
    │  (REST)    │           │  (State)   │
    └──────┬─────┘           └─────┬──────┘
           │                        │
           └────────┬───────────────┘
                    │
           ┌────────▼────────┐
           │  ChatProvider   │
           │  • conversations│
           │  • messages     │
           │  • timers       │
           └────────┬────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
   ┌────▼───┐  ┌───▼────┐  ┌──▼─────┐
   │ Active │  │Expired │  │ Timer  │
   │ Filter │  │ Filter │  │ Logic  │
   └────┬───┘  └───┬────┘  └──┬─────┘
        │          │           │
        └──────────┼───────────┘
                   │
           ┌───────▼────────┐
           │   UI Render    │
           │  • Chat List   │
           │  • Chat View   │
           │  • Archives    │
           └────────────────┘
```

## Archive Access Pattern

```
┌─────────────────────────────────────────────────────────────┐
│               Archive Navigation Flow                        │
└─────────────────────────────────────────────────────────────┘

      ┌──────────────┐
      │  Chat List   │ ◀── Shows only ACTIVE chats
      │   Page       │
      └──────┬───────┘
             │
             │ Click Archive Button
             │ (Shows badge: 3)
             ▼
      ┌──────────────┐
      │  Archived    │ ◀── Shows only EXPIRED chats
      │  Chats Page  │
      └──────┬───────┘
             │
             │ Click Conversation
             │ (Passes archived=true)
             ▼
      ┌──────────────┐
      │  Chat Page   │ ◀── Read-only mode
      │  (Archived)  │     • Archive banner
      └──────────────┘     • No input field
                           • Full history
```

## Timer Update Mechanism

```
┌─────────────────────────────────────────────────────────────┐
│                    Timer Update Loop                         │
└─────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────┐
    │         Timer.periodic(1 second)         │
    └──────────────┬───────────────────────────┘
                   │
                   ▼
          ┌────────────────┐
          │ getRemainingTime│
          │   (chatId)      │
          └────────┬────────┘
                   │
       ┌───────────┴───────────┐
       │                       │
       ▼                       ▼
  ┌─────────┐           ┌───────────┐
  │ > 0 sec │           │ = 0 sec   │
  └────┬────┘           └─────┬─────┘
       │                      │
       ▼                      ▼
  ┌─────────┐           ┌───────────┐
  │setState │           │ Cancel    │
  │Update UI│           │ Timer     │
  └────┬────┘           └─────┬─────┘
       │                      │
       │                      ▼
       │              ┌───────────────┐
       │              │ Show Expired  │
       │              │   Message     │
       │              └───────────────┘
       │
       └──────────────┐
                      │
                      ▼
             ┌────────────────┐
             │  Loop Continues│
             └────────────────┘
```

## Legend

```
Symbols:
  🟢 Active/Good State
  🟡 Warning State
  🔴 Error/Expired State
  ⌨️  Input Enabled
  🚫 Input Disabled
  📤 Send Action
  📦 Archived
  👁️  View-Only
  💬 Messages
  🔔 Notification
  ⚠️  Warning
  
States:
  [ ] Component
  ( ) Process
  │ │ Flow Direction
  ─ ─ Connection
  ▼   Next Step
  ─▶  Transition
```

## Quick Summary

**3 Main States:**
1. **Active** (0-22h) - Full functionality, timer running
2. **Expiring** (22-24h) - Warning notification, still active
3. **Expired** (24h+) - Read-only, archived, accessible

**Key Features:**
- ⏱️  Real-time countdown timer
- 🔔 2-hour advance notification
- 📦 Automatic archiving
- 👁️  Read-only access to archives
- 🎯 Clean UI state transitions

**User Benefits:**
- Clear time awareness
- No surprise expirations
- Access to conversation history
- Encourages authentic connections
