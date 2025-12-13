// app/javascript/controllers/collapsible_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
    static targets = ["content", "icon", "label"]

    connect() {
        this.open = true
    }

    toggle() {
        this.open = !this.open
        this.contentTarget.classList.toggle("hidden", !this.open)
        this.iconTarget.classList.toggle("rotate-180", !this.open)

        if (this.hasLabelTarget) {
            this.labelTarget.textContent = this.open ? "Hide details" : "Show details"
        }
    }
}
