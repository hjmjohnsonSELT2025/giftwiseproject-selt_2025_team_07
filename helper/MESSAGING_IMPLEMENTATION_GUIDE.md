# 💬 Direct Messaging Feature - Complete Implementation Guide

## Overview
This implementation adds a complete friend system and real-time direct messaging to GiftWise.

## Features
✅ Friend requests (send, accept, reject)
✅ Friends list management
✅ Real-time chat with Action Cable
✅ Online/offline status indicators
✅ Unread message counters
✅ Chat icon in bottom-left corner
✅ Instagram-style message notifications
✅ Message read receipts

---

## 📂 Files to Install

### 1. Migration (1 file)
**File:** `create_friendships_migration.rb`
**Location:** `db/migrate/YYYYMMDDHHMMSS_create_friendships.rb`
**Action:** Run: `rails generate migration CreateFriendships` then replace content

### 2. Models (3 files)
- `friendship.rb` → `app/models/friendship.rb`
- `message.rb` → `app/models/message.rb` (REPLACE existing)
- `user_with_friendships.rb` → `app/models/user.rb` (MERGE with existing)

### 3. Controllers (2 files)
- `friendships_controller.rb` → `app/controllers/friendships_controller.rb` (NEW)
- `messages_controller.rb` → `app/controllers/messages_controller.rb` (NEW)

### 4. Routes (1 file)
- `routes_with_messaging.rb` → `config/routes.rb` (REPLACE)

### 5. Action Cable (3 files)
- `chat_channel.rb` → `app/channels/chat_channel.rb` (NEW)
- `connection.rb` → `app/channels/application_cable/connection.rb` (NEW)
- `consumer.js` → `app/javascript/channels/consumer.js` (NEW or verify exists)

### 6. Views (5 files)
Create these directories first:
```bash
mkdir -p app/views/friendships
mkdir -p app/views/messages
mkdir -p app/views/shared
```

Files:
- `friendships_index.html.erb` → `app/views/friendships/index.html.erb`
- `messages_index.html.erb` → `app/views/messages/index.html.erb`
- `messages_message_partial.html.erb` → `app/views/messages/_message.html.erb`
- `messages_create_turbo_stream.erb` → `app/views/messages/create.turbo_stream.erb`
- `friendships_create_turbo_stream.erb` → `app/views/friendships/create.turbo_stream.erb`
- `chat_icon_partial.html.erb` → `app/views/shared/_chat_icon.html.erb`

### 7. JavaScript (2 files)
- `chat_controller.js` → `app/javascript/controllers/chat_controller.js`
- `chat_icon_controller.js` → `app/javascript/controllers/chat_icon_controller.js`

---

## 🔧 Installation Steps

### Step 1: Run Migration
```bash
# Create migration file
rails generate migration CreateFriendships

# Replace the generated file content with create_friendships_migration.rb

# Run migration
rails db:migrate
```

### Step 2: Install Models
```bash
# Copy new models
cp friendship.rb app/models/
cp message.rb app/models/

# Update user.rb by MERGING content from user_with_friendships.rb
# Add these lines to your existing User model:
```

```ruby
# Add to app/models/user.rb
has_many :friendships, dependent: :destroy
has_many :friends, through: :friendships, source: :friend, 
         -> { where(friendships: { status: 'accepted' }) }

has_many :pending_friend_requests, -> { pending }, 
         class_name: 'Friendship', foreign_key: 'friend_id'
has_many :sent_friend_requests, -> { pending }, 
         class_name: 'Friendship', foreign_key: 'user_id'

has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
has_many :received_messages, class_name: 'Message', foreign_key: 'receiver_id', dependent: :destroy

def friend?(other_user)
  friends.include?(other_user)
end

def friend_request_pending_with?(other_user)
  Friendship.exists?(
    user_id: id, friend_id: other_user.id, status: 'pending'
  ) || Friendship.exists?(
    user_id: other_user.id, friend_id: id, status: 'pending'
  )
end

def unread_messages_from(user)
  received_messages.where(sender: user, read: false).count
end

def online?
  updated_at > 5.minutes.ago
end
```

### Step 3: Install Controllers
```bash
cp friendships_controller.rb app/controllers/
cp messages_controller.rb app/controllers/
```

### Step 4: Update Routes
```bash
cp routes_with_messaging.rb config/routes.rb
```

### Step 5: Install Action Cable
```bash
# Create directories
mkdir -p app/channels/application_cable
mkdir -p app/javascript/channels

# Copy files
cp chat_channel.rb app/channels/
cp connection.rb app/channels/application_cable/
cp consumer.js app/javascript/channels/
```

### Step 6: Install Views
```bash
# Create directories
mkdir -p app/views/friendships
mkdir -p app/views/messages
mkdir -p app/views/shared

# Copy files
cp friendships_index.html.erb app/views/friendships/index.html.erb
cp messages_index.html.erb app/views/messages/index.html.erb
cp messages_message_partial.html.erb app/views/messages/_message.html.erb
cp messages_create_turbo_stream.erb app/views/messages/create.turbo_stream.erb
cp friendships_create_turbo_stream.erb app/views/friendships/create.turbo_stream.erb
cp chat_icon_partial.html.erb app/views/shared/_chat_icon.html.erb
```

### Step 7: Install JavaScript
```bash
cp chat_controller.js app/javascript/controllers/
cp chat_icon_controller.js app/javascript/controllers/
```

### Step 8: Add Chat Icon to Layout
Add this to your `app/views/layouts/application.html.erb` before the closing `</body>` tag:

```erb
<%= render 'shared/chat_icon' %>
```

### Step 9: Add Friends Icon to Navigation
In your dashboard header navigation, add:

```erb
<%= link_to friendships_path, class: "text-gray-700 hover:text-[#a855f7] transition" do %>
  <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
    <circle cx="9" cy="7" r="4"></circle>
    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
  </svg>
<% end %>
```

### Step 10: Configure Action Cable (if not already)
In `config/cable.yml`, ensure development is configured:

```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: giftwise_production
```

### Step 11: Mount Action Cable in routes
Verify this line exists in `config/routes.rb`:

```ruby
mount ActionCable.server => '/cable'
```

### Step 12: Restart Server
```bash
rails server
```

---

## 🧪 Testing Checklist

### Friend System
- [ ] Navigate to `/friendships`
- [ ] See list of other users
- [ ] Click "Add Friend" button
- [ ] Friend request sent successfully
- [ ] Log in as second user
- [ ] See pending friend request
- [ ] Accept friend request
- [ ] Both users see each other in "My Friends"
- [ ] Can remove friend

### Messaging
- [ ] See chat icon in bottom-left corner (only if have friends)
- [ ] Click chat icon
- [ ] See list of friends
- [ ] Click on a friend
- [ ] Opens chat interface
- [ ] Send a message
- [ ] Message appears immediately
- [ ] Other user (in separate browser/incognito) sees message in real-time
- [ ] Unread count updates
- [ ] Messages marked as read when viewing conversation
- [ ] Online/offline status shows correctly

### Real-Time Features
- [ ] Open chat in two different browsers
- [ ] Send message from one
- [ ] Appears instantly in the other
- [ ] Unread badge updates automatically
- [ ] Online status indicator works

---

## 🎨 UI Features

### Friends Page
- Purple theme (#a855f7)
- Three sections:
  1. Pending Requests (with Accept/Reject buttons)
  2. My Friends (with Message/Remove buttons)
  3. Add Friends (with green Add Friend buttons)
- Online status indicators (green dot)
- User avatars with initials

### Chat Interface
- Clean message bubbles
- Sender messages: Purple background, right-aligned
- Receiver messages: Gray background, left-aligned
- Timestamps
- Read receipts (✓ = sent, ✓✓ = read)
- Online/offline status in header
- Smooth scrolling
- Enter to send

### Chat Icon
- Fixed bottom-left corner
- Purple button
- Unread count badge
- Popup with friends list
- Quick access to all conversations

---

## 📡 Real-Time Architecture

### Action Cable Flow
```
User A sends message
     ↓
Message created in database
     ↓
after_create_commit triggered
     ↓
Broadcast to User B's channel
     ↓
User B's JavaScript receives data
     ↓
Message appended to chat
     ↓
Notification sound (optional)
```

### Channels
- Each user subscribes to `chat_#{user.id}`
- Messages broadcast to receiver's channel
- Real-time updates without polling

---

## 🔒 Security Notes

- Friend requests required before messaging
- Can only message accepted friends
- Read receipts only for sender
- Online status based on last activity (5 min threshold)
- Action Cable authenticated via session

---

## 🚀 Optional Enhancements

### Typing Indicators
Add to ChatChannel:
```ruby
def typing(data)
  ActionCable.server.broadcast(
    "chat_#{data['receiver_id']}",
    { typing: true, user_id: current_user.id }
  )
end
```

### Notification Sounds
Uncomment in chat_controller.js:
```javascript
playNotificationSound() {
  const audio = new Audio('/sounds/notification.mp3')
  audio.play()
}
```

### Message Deletion
Add destroy action to MessagesController

### File/Image Sharing
Add Active Storage attachment to Message model

### Group Chats
Create Conversation model with many-to-many users

---

## 🐛 Troubleshooting

### Action Cable not working
- Check Redis is running (production)
- Verify cable.yml configuration
- Check browser console for WebSocket errors
- Ensure mount ActionCable.server in routes

### Messages not appearing
- Check ChatChannel is subscribed
- Verify broadcast_to_receiver is called
- Check browser console for errors
- Verify user_id values match

### Friends not showing
- Run migration: `rails db:migrate`
- Check Friendship model associations
- Verify status is 'accepted'

### Online status always offline
- Check User#online? method
- Verify updated_at timestamp
- Consider implementing Redis-based presence

---

## 📞 Need Help?

1. Check Rails logs: `tail -f log/development.log`
2. Check browser console for JavaScript errors
3. Verify all files are in correct locations
4. Ensure migrations ran successfully
5. Restart server after major changes

---

## ✅ Completion Checklist

- [ ] Migration created and run
- [ ] All models installed
- [ ] All controllers installed
- [ ] Routes updated
- [ ] Action Cable configured
- [ ] All views installed
- [ ] JavaScript controllers installed
- [ ] Chat icon added to layout
- [ ] Friends icon added to navigation
- [ ] Server restarted
- [ ] Tested with two users
- [ ] Real-time messaging works
- [ ] Friend requests work
- [ ] UI looks good

🎉 **Your messaging system is complete!**
