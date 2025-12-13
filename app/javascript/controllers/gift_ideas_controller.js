// app/javascript/controllers/gift_ideas_controller.js
import { Controller } from "@hotwired/stimulus"

// Controller identifier: "gift-ideas" (from file name gift_ideas_controller.js)
export default class extends Controller {
    static targets = ["button"]

    submit(event) {
        // Prevent double-submit if already in progress
        if (this.element.dataset.submitting === "true") {
            event.preventDefault()
            return
        }

        this.element.dataset.submitting = "true"

        this.buttonTargets.forEach((button) => {
            button.disabled = true
            button.dataset.originalText = button.innerText
            button.innerText = "Generating..."
        })
    }

    reset() {
        this.element.dataset.submitting = "false"

        this.buttonTargets.forEach((button) => {
            button.disabled = false
            if (button.dataset.originalText) {
                button.innerText = button.dataset.originalText
            }
        })
    }
}
