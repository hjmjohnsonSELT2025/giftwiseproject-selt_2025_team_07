// app/javascript/controllers/chatbot_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel", "messages", "input", "form", "quickReplies", "toggleButton"]
    static values = { open: { type: Boolean, default: false } }

    connect() {
        this.csrfToken =
            document.querySelector("meta[name='csrf-token']")?.content || ""

        // panel starts closed
        this.closePanelHard()

        // bind once so we can remove correctly
        this.boundOutsideClick = this.handleOutsideClick.bind(this)
        document.addEventListener("click", this.boundOutsideClick)

        // event delegation for ALL quick-reply buttons
        if (this.hasQuickRepliesTarget) {
            this.boundQuickReplyClick = this.handleQuickReplyClick.bind(this)
            this.quickRepliesTarget.addEventListener("click", this.boundQuickReplyClick)
        }
    }

    disconnect() {
        document.removeEventListener("click", this.boundOutsideClick)
        if (this.boundQuickReplyClick && this.hasQuickRepliesTarget) {
            this.quickRepliesTarget.removeEventListener(
                "click",
                this.boundQuickReplyClick
            )
        }
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
        this.closePanel()
    }

    handleOutsideClick(event) {
        if (!this.openValue) return

        const panel  = this.panelTarget
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

    // central handler for ALL quick-reply buttons
    handleQuickReplyClick(event) {
        const btn = event.target.closest("button[data-intent]")
        if (!btn) return

        const intent = btn.dataset.intent
        const label  = btn.innerText.trim()
        if (!intent) return

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
                "X-CSRF-Token": this.csrfToken,
            },
            body: JSON.stringify(payload),
        })
            .then((r) => r.json())
            .then((data) => {
                const messages     = data.messages || []
                const quickReplies = data.quick_replies || []

                if (opts.skipUserAppend) {
                    // full refresh (used for reset/exit)
                    this.renderHistory(messages)
                } else {
                    // just add the last bot message
                    const last = messages[messages.length - 1]
                    if (last && last.role === "bot") {
                        this.appendMessage("bot", last.text)
                    }
                }

                this.renderQuickReplies(quickReplies)
                if (opts.closeAfter) this.closePanel()
            })
            .catch((e) => console.error("Chatbot error", e))
    }

    // ---------- Render helpers ----------

    renderHistory(messages) {
        this.messagesTarget.innerHTML = ""
        messages.forEach((msg) =>
            this.appendMessage(msg.role, msg.text, { dontScroll: true })
        )
        this.scrollToBottom()
    }

    appendMessage(role, text, options = {}) {
        const wrapper = document.createElement("div")
        wrapper.style.display = "flex"
        wrapper.style.marginBottom = "6px"
        wrapper.style.justifyContent =
            role === "user" ? "flex-end" : "flex-start"

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
