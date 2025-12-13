// app/javascript/controllers/auto_dismiss_controller.js
// Stimulus controller to auto-dismiss flash messages

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        delay: { type: Number, default: 3000 }
    }

    connect() {
        this.timeout = setTimeout(() => {
            this.dismiss()
        }, this.delayValue)
    }

    disconnect() {
        if (this.timeout) {
            clearTimeout(this.timeout)
        }
    }

    dismiss() {
        this.element.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
        this.element.style.opacity = "0"
        this.element.style.transform = "translateX(100%)"

        setTimeout(() => {
            this.element.remove()
        }, 300)
    }
}