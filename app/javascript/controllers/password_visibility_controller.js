import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "iconOn", "iconOff"]

    connect() {
        this.showHiddenState()
    }

    toggle() {
        const field = this.inputTarget
        field.type = field.type === "password" ? "text" : "password"
        this.showHiddenState()
    }

    showHiddenState() {
        const isPassword = this.inputTarget.type === "password"
        if (this.hasIconOnTarget && this.hasIconOffTarget) {
            this.iconOnTarget.classList.toggle("hidden", !isPassword)
            this.iconOffTarget.classList.toggle("hidden", isPassword)
        }
    }
}