import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  async load() {
    const response = await fetch("/greeting")
    this.outputTarget.textContent = response.redirected ? "Please sign in" : (await response.json()).greeting
  }
}
