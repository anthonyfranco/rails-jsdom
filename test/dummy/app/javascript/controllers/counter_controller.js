import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]
  static values = { start: Number }

  connect() {
    this.count = this.startValue
    this.render()
  }

  increment() {
    this.count += 1
    this.render()
  }

  render() {
    this.countTarget.textContent = String(this.count)
  }
}
