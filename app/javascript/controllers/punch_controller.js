import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Active punches are encoded in the URL as
//   ?selected=userSlug:day,day;userSlug:day,...
// and restored on load. History is not pushed.
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn']

  connect () {
    const selected = new URLSearchParams(window.location.search).get('selected')
    const active = new Set()
    if (selected) {
      selected.split(';').forEach(group => {
        const [slug, daysStr] = group.split(':')
        if (!slug || !daysStr) return
        daysStr.split(',').forEach(day => active.add(`${slug}:${parseInt(day, 10)}`))
      })
    }
    this.punchTargets.forEach(el => {
      if (active.has(this.punchKey(el))) {
        el.setAttribute('aria-pressed', 'true')
      }
    })
    this.sync()
  }

  toggle (event) {
    const clicked = event.currentTarget
    const wasActive = clicked.getAttribute('aria-pressed') === 'true'
    clicked.setAttribute('aria-pressed', wasActive ? 'false' : 'true')
    this.afterToggle()
  }

  toggleDay (event) {
    const date = event.currentTarget.dataset.date
    const dayPunches = this.punchTargets.filter(el => el.dataset.date === date)
    if (dayPunches.length === 0) return
    const allActive = dayPunches.every(el => el.getAttribute('aria-pressed') === 'true')
    dayPunches.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  toggleUser (event) {
    const slug = event.currentTarget.dataset.userSlug
    const userPunches = this.punchTargets.filter(el => el.dataset.userSlug === slug)
    if (userPunches.length === 0) return
    const allActive = userPunches.every(el => el.getAttribute('aria-pressed') === 'true')
    userPunches.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  showAll () {
    this.punchTargets.forEach(el => el.setAttribute('aria-pressed', 'true'))
    this.afterToggle()
  }

  hideAll () {
    this.punchTargets.forEach(el => el.setAttribute('aria-pressed', 'false'))
    this.afterToggle()
  }

  afterToggle () {
    this.sync()
    this.updateUrl()
  }

  sync () {
    this.syncRidgeBars()
    this.syncUserButtons()
    this.syncActivities()
    this.syncHideAllButton()
  }

  syncRidgeBars () {
    this.ridgeBarTargets.forEach(bar => {
      const dayPunches = this.punchTargets.filter(el => el.dataset.date === bar.dataset.date)
      const allActive = dayPunches.length > 0 && dayPunches.every(el => el.getAttribute('aria-pressed') === 'true')
      bar.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncUserButtons () {
    this.userButtonTargets.forEach(btn => {
      const userPunches = this.punchTargets.filter(el => el.dataset.userSlug === btn.dataset.userSlug)
      const allActive = userPunches.length > 0 && userPunches.every(el => el.getAttribute('aria-pressed') === 'true')
      btn.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncActivities () {
    const activeIds = new Set(
      this.punchTargets
        .filter(el => el.getAttribute('aria-pressed') === 'true')
        .map(el => el.dataset.punchId)
    )
    this.element.querySelectorAll('[data-punch-activities-for]').forEach(el => {
      el.classList.toggle('hidden!', !activeIds.has(el.dataset.punchActivitiesFor))
    })
  }

  syncHideAllButton () {
    const anyActive = this.punchTargets.some(el => el.getAttribute('aria-pressed') === 'true')
    this.hideAllBtnTargets.forEach(btn => btn.classList.toggle('hidden', !anyActive))
  }

  updateUrl () {
    const byUser = new Map()
    this.punchTargets
      .filter(el => el.getAttribute('aria-pressed') === 'true')
      .forEach(el => {
        const slug = el.dataset.userSlug
        const day = this.dayOf(el)
        if (!byUser.has(slug)) byUser.set(slug, [])
        byUser.get(slug).push(day)
      })
    const encoded = Array.from(byUser, ([slug, days]) =>
      `${slug}:${days.sort((a, b) => a - b).join(',')}`
    ).join(';')
    const url = new URL(window.location.href)
    if (encoded) {
      url.searchParams.set('selected', encoded)
    } else {
      url.searchParams.delete('selected')
    }
    window.history.replaceState(null, '', url)
  }

  punchKey (el) {
    return `${el.dataset.userSlug}:${this.dayOf(el)}`
  }

  dayOf (el) {
    return parseInt(el.dataset.date.slice(-2), 10)
  }
}
