import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="ui--period-select"
// When a preset period link is clicked, merge its query params into the
// current URL so filters like search_email persist across period changes.
// Custom-form show/hide is delegated to the shared `collapse` controller.
export default class extends Controller {
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
}
