// app/javascript/controllers/chat_controller.js
// Stimulus controller for real-time chat functionality

import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
    static values = { userId: Number, friendId: Number }
    static targets = ["form"]

    connect() {
        console.log("🟢 Chat controller connected!")
        console.log("👤 Current User ID:", this.userIdValue)
        console.log("👥 Friend ID:", this.friendIdValue)

        this.scrollToBottom()
        this.setupActionCable()
    }

    disconnect() {
        console.log("🔴 Chat controller disconnecting...")
        if (this.subscription) {
            this.subscription.unsubscribe()
        }
    }

    setupActionCable() {
        console.log("📡 Setting up ActionCable subscription...")

        // Subscribe to the chat channel for real-time messages
        this.subscription = consumer.subscriptions.create(
            { channel: "ChatChannel" },
            {
                connected: () => {
                    console.log("✅ Connected to ChatChannel!")
                    console.log("🎧 Listening for messages...")
                },

                disconnected: () => {
                    console.log("❌ Disconnected from ChatChannel")
                },

                received: (data) => {
                    console.log("📨 RAW MESSAGE RECEIVED:", data)
                    console.log("📨 Sender ID:", data.sender_id)
                    console.log("📨 Current Friend ID:", this.friendIdValue)

                    // Only append message if it's from the friend we're chatting with
                    if (data.sender_id === this.friendIdValue) {
                        console.log("✅ Message is from current friend, appending to chat...")
                        this.appendMessage(data.message)
                        this.scrollToBottom()
                    } else {
                        console.log("⏭️ Message is from someone else (sender: " + data.sender_id + "), ignoring")
                    }
                }
            }
        )
    }

    appendMessage(message) {
        console.log("➕ Appending message to DOM:", message)

        const messagesContainer = document.getElementById("messages")
        if (!messagesContainer) {
            console.error("❌ Messages container not found!")
            return
        }

        const messageHtml = this.createMessageElement(message)
        messagesContainer.insertAdjacentHTML('beforeend', messageHtml)
        console.log("✅ Message appended successfully!")
    }

    createMessageElement(message) {
        const isCurrentUser = message.sender_id === this.userIdValue
        const alignment = isCurrentUser ? 'justify-end' : 'justify-start'
        const bgColor = isCurrentUser ? 'bg-[#a855f7] text-white' : 'bg-white text-gray-900'
        const timeAlignment = isCurrentUser ? 'justify-end' : 'justify-start'

        return `
      <div class="flex ${alignment}" id="message_${message.id}">
        <div class="max-w-[70%]">
          <div class="${bgColor} rounded-2xl px-4 py-2 shadow-sm">
            <p class="text-sm">${this.escapeHtml(message.body)}</p>
          </div>
          <div class="flex items-center gap-2 mt-1 ${timeAlignment}">
            <p class="text-xs text-gray-400">${message.created_at}</p>
            ${isCurrentUser ? '<span class="text-xs text-gray-400">✓</span>' : ''}
          </div>
        </div>
      </div>
    `
    }

    escapeHtml(text) {
        const div = document.createElement('div')
        div.textContent = text
        return div.innerHTML
    }

    submitOnEnter(event) {
        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault()
            this.formTarget.requestSubmit()
        }
    }

    scrollToBottom() {
        const messagesContainer = document.getElementById("messages")
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight
        }
    }
}