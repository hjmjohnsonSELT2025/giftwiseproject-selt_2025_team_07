// app/javascript/controllers/chat_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = { userId: Number, friendId: Number }
  static targets = ["form"]

  connect() {
    this.scrollToBottom()
    this.setupChatSubscription()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  setupChatSubscription() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ChatChannel" },
      {
        connected: () => {
          console.log("Connected to chat channel")
        },

        disconnected: () => {
          console.log("Disconnected from chat channel")
        },

        received: (data) => {
          // Only append if message is from the current conversation
          if (data.sender_id === this.friendIdValue) {
            const messagesContainer = document.getElementById("messages")
            messagesContainer.insertAdjacentHTML('beforeend', data.message.html)
            this.scrollToBottom()
            this.playNotificationSound()
          }
        }
      }
    )
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

  playNotificationSound() {
    // Optional: Add notification sound
    // const audio = new Audio('/sounds/notification.mp3')
    // audio.play()
  }
}
