// app/javascript/controllers/collaborations_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collaborations-toggle"
export default class extends Controller {
    static targets = ["body", "chevron"]
    static values = { open: { type: Boolean, default: true } }

    connect() {
        this.update()
    }

    toggle() {
        this.openValue = !this.openValue
        this.update()
    }

    update() {
        if (!this.hasBodyTarget || !this.hasChevronTarget) return
        this.bodyTarget.classList.toggle("hidden", !this.openValue)
        this.chevronTarget.classList.toggle("rotate-180", this.openValue)
    }
}
