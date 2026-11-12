export class Controller {
  constructor(element) {
    this.element = element
  }
}

export class Application {
  static start() {
    return new Application()
  }

  register(identifier, Klass) {
    for (const element of document.querySelectorAll(`[data-controller~="${identifier}"]`)) {
      try {
        new Klass(element).connect()
      } catch (error) {
        this.handleError(error, `Error connecting ${identifier}`)
      }
    }
  }
}
