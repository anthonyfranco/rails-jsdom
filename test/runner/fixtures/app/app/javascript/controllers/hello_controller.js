import { Controller } from "@hotwired/stimulus"
import greeting from "lib/greeting"
import tiny from "tiny"
import { track } from "remote-analytics"

export default class extends Controller {
  connect() {
    track("connected")
    this.element.textContent = `${greeting("Ada")} ${tiny}`
  }
}
