import { Controller } from '@hotwired/stimulus'
import { computePosition, flip, shift, offset, autoUpdate } from '@floating-ui/dom'

let topZIndex = 50

// Connects to data-controller="ui--tooltip"
export default class extends Controller {
  static targets = ['trigger', 'tooltip']
  static values = {
    placement: { type: String, default: 'top' }
  }

  connect () {
    this.clickOutside = this.clickOutside.bind(this)
  }

  disconnect () {
    this.hide()
  }

  showOnHover () {
    if (this.shownBy === 'focus') return
    this.shownBy = 'hover'
    this.open()
  }

  hideOnHover () {
    if (this.shownBy === 'hover') this.hide()
  }

  showOnFocus () {
    this.shownBy = 'focus'
    this.open()
    document.addEventListener('click', this.clickOutside)
  }

  hideOnFocusout () {
    if (this.shownBy === 'focus') this.hide()
  }

  open () {
    topZIndex += 1
    this.tooltipTarget.style.zIndex = topZIndex
    this.tooltipTarget.classList.remove('hidden')
    this.cleanup = autoUpdate(this.triggerTarget, this.tooltipTarget, () => this.updatePosition())
  }

  hide () {
    this.tooltipTarget.classList.add('hidden')
    this.shownBy = null
    document.removeEventListener('click', this.clickOutside)
    if (this.cleanup) {
      this.cleanup()
      this.cleanup = null
    }
  }

  clickOutside (event) {
    if (!this.element.contains(event.target)) this.hide()
  }

  async updatePosition () {
    const { x, y } = await computePosition(this.triggerTarget, this.tooltipTarget, {
      placement: this.placementValue,
      middleware: [offset(6), flip(), shift({ padding: 4 })]
    })
    Object.assign(this.tooltipTarget.style, {
      left: `${x}px`,
      top: `${y}px`,
      position: 'absolute'
    })
  }
}
