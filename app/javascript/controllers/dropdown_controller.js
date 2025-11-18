import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    connect() {
        this.hideOnClickOutside = this.hideOnClickOutside.bind(this)
        window.addEventListener("click", this.hideOnClickOutside)
    }

    disconnect() {
        window.removeEventListener("click", this.hideOnClickOutside)
    }

    toggle(event) {
        event.stopPropagation()
        this.menuTarget.classList.toggle("hidden")
    }

    hideOnClickOutside(event) {
        if (this.element.contains(event.target)) return
        this.menuTarget.classList.add("hidden")
    }
}