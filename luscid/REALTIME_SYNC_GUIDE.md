# Real-Time Synchronization Guide

## Overview
This document explains how real-time card synchronization works in the multiplayer matching game. When one player flips a card, the other player sees it immediately through Firebase Realtime Database integration.

## Architecture

### Core Components

#### 1. **GameProvider** (`lib/providers/game_provider.dart`)
Central state management hub for all game logic and Firebase synchronization.

**Key Methods:**
- `onCardTap(int index)`: Called when player taps a card
  - Flips card locally
  - Immediately syncs to Firebase: `await _firebaseService.updateCards(...)`
  - Logs: `[GameProvider] Card[$index] synced: symbol=..., isFlipped=true`

- `_subscribeToRoom(String roomCode)`: Real-time listener
  - Watches Firebase for changes
  - Updates local `_cards` state
  - Calls `notifyListeners()` to trigger UI rebuild
  - Logs: `[GameProvider] 🔄 Real-time sync: cards updated`

- `_checkForMatch()`: Validates card matches
  - Detects if two cards match
  - Updates scores
  - Switches turns
  - Syncs turn change to Firebase

#### 2. **FirebaseService** (`lib/services/firebase_service.dart`)
Low-level Firebase database operations.

**Sync Methods:**
```dart
// Sync card state
Future<void> updateCards(String roomCode, List<GameCard> cards)
  → Writes to: `game_rooms/{roomCode}/cards`

// Sync turn state
Future<void> updateTurn(String roomCode, String playerId)
  → Writes to: `game_rooms/{roomCode}/currentTurn`

// Sync score state
Future<void> updateScore(String roomCode, String playerId, int score)
  → Writes to: `game_rooms/{roomCode}/scores/{playerId}`

// Real-time listener
Stream<GameRoom> watchRoom(String roomCode)
  → Subscribes to: `game_rooms/{roomCode}`
  → Fires on ANY change
```

#### 3. **GameCardWidget** (`lib/widgets/game_card_widget.dart`)
Individual card UI with flip animation.

**Key Feature:**
- `didUpdateWidget()`: Detects card state changes
  - When `isFlipped` changes → animate flip
  - When `isMatched` changes → show matched state
  - 500ms animation duration

#### 4. **GameRoom Model** (`lib/models/game_room_model.dart`)
Data model with Firebase serialization.

**Type Casting Fix:**
```dart
// Before: Type error when Firebase returns Map<Object?, Object?>
cards.map((c) => GameCard.fromJson(c as Map<String, dynamic>))

// After: Wrapper prevents type casting issues
cards.map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
```

## Real-Time Sync Flow

### Step-by-Step Process

```
Player A (Host)                          Firebase                         Player B (Guest)
─────────────────────────────────────────────────────────────────────────────────────

User taps Card 0
│
├─ onCardTap(0)
│  ├─ cards[0].flip()
│  │  [Local animation]
│  │
│  └─ updateCards(...)
│     │
│     └─ Write to Firebase ────────────────────────────────────────────────────────────┐
│                                                                                       │
└─ Log: "[GameProvider] Card[0] synced"                                               │
                                                                                       │
                                        Firebase detects write
                                        │
                                        └─ Triggers onValue stream
                                           │
                                           └─────────────────────────────────────────► Subscribe listener
                                                                                       │
                                                                                      └─ notifyListeners()
                                                                                         │
                                                                                        └─ Consumer widget rebuilds
                                                                                           │
                                                                                           ├─ GridView updates
                                                                                           │
                                                                                           ├─ GameCardWidget
                                                                                           │  didUpdateWidget()
                                                                                           │  │
                                                                                           │  └─ Animate flip
                                                                                           │
                                                                                           └─ UI shows flipped card
                                                                                              [Animation complete]
                                                                                              Log: "🔄 Real-time sync"
```

### Timing

- **Local Flip**: 0ms (immediate)
- **Firebase Upload**: 10-100ms (network)
- **Firebase Trigger**: 50-200ms (database processing)
- **Local Update**: 200-300ms (app processing)
- **Animation**: 500ms (visual feedback)
- **Total User Perception**: ~600-700ms from tap to seeing opponent's card

## Player Turn Management

### Turn State Synchronization

```dart
// After player makes a move (non-match)
_checkForMatch() {
  if (!isMatch) {
    // Switch turn
    String nextPlayer = _currentUserId == _room!.hostId 
      ? _room!.guestId! 
      : _room!.hostId;
    
    // Sync to Firebase
    await _firebaseService.updateTurn(_room!.roomCode, nextPlayer);
    
    // Log: "[GameProvider] No match, switching turn from X to Y"
  }
}
```

### UI Feedback

In [game_screen.dart](lib/screens/game_screen.dart):
```dart
// Show current player
Text(
  gameProvider.isMyTurn 
    ? 'Your Turn! 🎯' 
    : 'Waiting for opponent...',
  style: Theme.of(context).textTheme.headlineSmall,
)

// Disable cards for opponent
GridView.builder(
  ...
  itemBuilder: (_, i) => GameCardWidget(
    ...
    disabled: !gameProvider.isMyTurn,
  ),
)
```

## Score Management

### Match Detection and Scoring

When a match is detected:
```dart
_checkForMatch() async {
  final isMatch = _gameService.checkMatch(_firstSelectedCard!, _secondSelectedCard!);
  
  if (isMatch) {
    // Update local cards
    _cards = _gameService.markAsMatched(_cards, _firstSelectedCard!, _secondSelectedCard!);
    
    // Sync cards to Firebase
    await _firebaseService.updateCards(_room!.roomCode, _cards);
    
    // Update and sync score
    _currentScore++;
    await _firebaseService.updateScore(
      _room!.roomCode, 
      _currentUserId, 
      _currentScore
    );
    
    // Sync to Firebase
    await _firebaseService.updateCards(_room!.roomCode, _cards);
  }
}
```

### Score Display

Both players always see:
- **Your Score**: Top left
- **Opponent Score**: Top right
- **Matches Found**: Center badge
- Updates in real-time when scores change

## Testing

### Test Coverage

**Real-Time Sync Tests** (`test/integration/real_time_sync_test.dart`):
- ✅ Card flip visibility (immediate to both players)
- ✅ Multiple card flips maintain state
- ✅ Card match updates both player scores
- ✅ Turn switching reflects in both views
- ✅ Game completion syncs to both players
- ✅ Card serialization preserves flip state
- ✅ Multiple updates serialize correctly
- ✅ Game state persists through sync cycles
- ✅ Sync order: flip → match → score update

**Multiplayer Game Flow Tests** (`test/integration/multiplayer_game_flow_test.dart`):
- ✅ Complete room creation → joining → game start flow
- ✅ Full game from start to finish
- ✅ Match detection and scoring
- ✅ Turn switching
- ✅ Game completion
- ✅ Edge cases (empty cards, invalid moves)
- ✅ Real-time subscription updates

**Total Test Suite**: 27 tests, all passing

## Debugging

### Debug Logging

Enable debug logs to trace real-time sync:

```
[GameProvider] Card[0] synced: symbol=🍎, isFlipped=true
[GameProvider] Match check: 🍎 vs 🍎 = true
[GameProvider] No match, switching turn from host-123 to guest-456
[GameProvider] 🔄 Real-time sync: cards updated, total flipped=2, matched=0
```

### Firebase Console Checks

1. Navigate to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Realtime Database** → **Data**
4. Check `game_rooms/{roomCode}`:
   - `cards`: List of all cards with `isFlipped` and `isMatched` states
   - `currentTurn`: ID of player whose turn it is
   - `scores`: Object with scores for each player
   - `status`: Current game status (waiting/playing/finished)

## Common Issues and Solutions

### Issue: Card doesn't update on opponent's device
**Solution**: 
- Check Firebase database rules allow read/write
- Verify both players are subscribed to same `roomCode`
- Check network connectivity on both devices
- Look for debug logs: `[GameProvider] 🔄 Real-time sync`

### Issue: Opponent can move on other player's turn
**Solution**:
- Verify cards are disabled: `disabled: !gameProvider.isMyTurn`
- Check `currentTurn` is updating in Firebase
- Ensure `_checkForMatch()` correctly switches turns

### Issue: Scores not updating for opponent
**Solution**:
- Verify `updateScore()` is called after match
- Check Firebase rules allow score updates
- Ensure both players have same score format in database

## Performance Considerations

### Optimization Tips

1. **Batch Updates**: Combine multiple updates into single Firebase write
   ```dart
   await _firebaseService.updateRoom(roomCode, {
     'cards': cards,
     'currentTurn': nextPlayer,
     'scores': updatedScores,
   });
   ```

2. **Debounce Animations**: Queue animations instead of playing all at once
   ```dart
   await Future.delayed(Duration(milliseconds: 200));
   _animateCard(index);
   ```

3. **Lazy Load Cards**: Only update cards that changed
   ```dart
   // Only update the one card that was flipped
   cards[index] = cards[index].flip();
   ```

## Future Enhancements

- [ ] Implement optimistic UI updates (show changes immediately)
- [ ] Add connection status indicator
- [ ] Implement offline mode with sync when reconnected
- [ ] Add chat for players during game
- [ ] Implement game replay/replay system
- [ ] Add statistics tracking per player

## References

- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)
- [Flutter ChangeNotifier Pattern](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)
- [Stream Builders in Flutter](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)
