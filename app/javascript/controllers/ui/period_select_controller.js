import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="ui--period-select"
// Two responsibilities:
// 1. select(): when a preset period link is clicked, merge its query params
//    into the current URL so filters like search_email persist across changes.
// 2. toggleCustom(): show/hide the custom date-range form when "custom" is clicked.
export default class extends Controller {
  static targets = ['customForm']

  select (event) {
    const link = event.currentTarget
    if (!link.href) return
    event.preventDefault()
    const linkUrl = new URL(link.href, window.location.origin)
    const newUrl = new URL(window.location.href)
    linkUrl.searchParams.forEach((value, key) => {
      newUrl.searchParams.set(key, value)
    })
    window.location.href = newUrl.pathname + newUrl.search
  }

  toggleCustom (event) {
    event.preventDefault()
    if (this.hasCustomFormTarget) {
      this.customFormTarget.classList.toggle('hidden')
    }
  }
}
