// app/javascript/controllers/chatbot_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel", "messages", "input", "form", "quickReplies", "toggleButton"]
    static values = { open: { type: Boolean, default: false } }

    connect() {
        this.csrfToken = document.querySelector("meta[name='csrf-token']")?.content || ""
        this.closePanelHard()

        document.addEventListener("click", this.handleOutsideClick)
    }

    disconnect() {
        document.removeEventListener("click", this.handleOutsideClick)
    }

    // ---------- Open / close ----------

    toggle(event) {
        event?.preventDefault()
        this.openValue ? this.closePanel() : this.openPanel()
    }

    openPanel() {
        const p = this.panelTarget
        p.style.transform = "translateX(0)"
        p.style.opacity = "1"
        p.style.pointerEvents = "auto"
        this.openValue = true
    }

    closePanel() {
        const p = this.panelTarget
        p.style.transform = "translateX(120%)"
        p.style.opacity = "0"
        p.style.pointerEvents = "none"
        this.openValue = false
    }

    closePanelHard() {
        // same as close, but without animation concerns
        this.closePanel()
    }

    handleOutsideClick = (event) => {
        if (!this.openValue) return

        const panel = this.panelTarget
        const button = this.toggleButtonTarget

        if (!panel.contains(event.target) && !button.contains(event.target)) {
            this.closePanel()
        }
    }

    // ---------- Sending & quick replies ----------

    send(event) {
        event.preventDefault()
        const text = this.inputTarget.value.trim()
        if (!text) return

        this.appendMessage("user", text)
        this.inputTarget.value = ""

        this.postToServer({ text })
    }

    quickReply(event) {
        const intent = event.currentTarget.dataset.intent
        const label = event.currentTarget.innerText.trim()

        this.appendMessage("user", label)
        this.postToServer({ text: label, intent })
    }

    resetConversation(event) {
        event.preventDefault()
        this.postToServer({ command: "reset" }, { skipUserAppend: true })
    }

    exitSession(event) {
        event.preventDefault()
        this.postToServer({ command: "exit" }, { skipUserAppend: true, closeAfter: true })
    }

    // ---------- Server communication ----------

    postToServer(payload, opts = {}) {
        fetch("/chatbot/message", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": this.csrfToken
            },
            body: JSON.stringify(payload)
        })
            .then((r) => r.json())
            .then((data) => {
                if (opts.skipUserAppend) {
                    // full refresh of history
                    this.renderHistory(data.messages || [])
                } else {
                    // append only the last bot message
                    const msgs = data.messages || []
                    const last = msgs[msgs.length - 1]
                    if (last && last.role === "bot") {
                        this.appendMessage("bot", last.text)
                    }
                }

                this.renderQuickReplies(data.quick_replies || [])
                if (opts.closeAfter) this.closePanel()
            })
            .catch((e) => console.error("Chatbot error", e))
    }

    // ---------- Render helpers ----------

    renderHistory(messages) {
        this.messagesTarget.innerHTML = ""
        messages.forEach((msg) => this.appendMessage(msg.role, msg.text, { dontScroll: true }))
        this.scrollToBottom()
    }

    appendMessage(role, text, options = {}) {
        const wrapper = document.createElement("div")
        wrapper.style.display = "flex"
        wrapper.style.marginBottom = "6px"
        wrapper.style.justifyContent = role === "user" ? "flex-end" : "flex-start"

        const bubble = document.createElement("div")
        bubble.style.maxWidth = "80%"
        bubble.style.borderRadius = "16px"
        bubble.style.padding = "6px 9px"
        bubble.style.whiteSpace = "pre-wrap"
        bubble.style.fontSize = "13px"

        if (role === "user") {
            bubble.style.background = "#a855f7"
            bubble.style.color = "#ffffff"
        } else {
            bubble.style.background = "#ffffff"
            bubble.style.color = "#111827"
            bubble.style.border = "1px solid #e5e7eb"
        }

        bubble.innerText = text
        wrapper.appendChild(bubble)
        this.messagesTarget.appendChild(wrapper)

        if (!options.dontScroll) this.scrollToBottom()
    }

    scrollToBottom() {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }

    renderQuickReplies(replies) {
        this.quickRepliesTarget.innerHTML = ""

        replies.forEach((reply) => {
            const btn = document.createElement("button")
            btn.type = "button"
            btn.dataset.action = "chatbot#quickReply"
            btn.dataset.intent = reply.intent
            btn.innerText = reply.label
            btn.style.marginRight = "6px"
            btn.style.marginBottom = "6px"
            btn.style.padding = "4px 10px"
            btn.style.borderRadius = "9999px"
            btn.style.border = "1px solid #e5e7eb"
            btn.style.background = "#ffffff"
            btn.style.fontSize = "11px"
            btn.style.cursor = "pointer"
            this.quickRepliesTarget.appendChild(btn)
        })
    }
}
