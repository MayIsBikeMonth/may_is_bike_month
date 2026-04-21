import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Active punches are encoded in the URL as
//   ?selected=userSlug:day,day;userSlug:day,...
// and restored on load. History is not pushed.
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
//
// Across turbo morphs we also preserve *group intent*: if a user row, a
// specific day, or all activities were fully selected before the morph,
// any newly-rendered punches in that group are re-activated so new
// activities appear without the user having to re-click.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn', 'showAllBtn']

  connect () {
    this.activeUsers = new Set()
    this.activeDays = new Set()
    this.allActive = false
    this.beforeMorphHandler = (event) => {
      if (event.target === this.element) this.captureActiveGroups()
    }
    // idiomorph bubbles turbo:morph-element for every descendant during the
    // morph; debounce into one rebuild per morph cycle.
    this.morphHandler = () => this.scheduleRebuild()
    this.element.addEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.addEventListener('turbo:morph-element', this.morphHandler)
    this.rebuild()
  }

  scheduleRebuild () {
    if (this.rebuildScheduled) return
    this.rebuildScheduled = true
    queueMicrotask(() => {
      this.rebuildScheduled = false
      this.rebuild()
    })
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.removeEventListener('turbo:morph-element', this.morphHandler)
  }

  rebuild () {
    this.indexPunches()
    this.applySelectionFromUrl()
    this.applyCapturedGroups()
    this.sync()
    this.updateUrl()
  }

  applySelectionFromUrl () {
    const selected = new URLSearchParams(window.location.search).get('selected')
    if (!selected) return
    selected.split(';').forEach(group => {
      const [slug, daysStr] = group.split(':')
      if (!slug || !daysStr) return
      daysStr.split(',').forEach(day => {
        this.punchesByKey.get(`${slug}:${parseInt(day, 10)}`)?.setAttribute('aria-pressed', 'true')
      })
    })
  }

  // Query the DOM directly (rather than via Stimulus target getters) so that
  // newly-morphed-in elements are picked up inside a synchronous
  // turbo:morph-element handler, before Stimulus's MutationObserver runs.
  indexPunches () {
    this.punches = Array.from(this.element.querySelectorAll('[data-punch-target="punch"]'))
    this.ridgeBars = Array.from(this.element.querySelectorAll('[data-punch-target="ridgeBar"]'))
    this.userButtons = Array.from(this.element.querySelectorAll('[data-punch-target="userButton"]'))
    this.hideAllBtns = Array.from(this.element.querySelectorAll('[data-punch-target="hideAllBtn"]'))
    this.showAllBtns = Array.from(this.element.querySelectorAll('[data-punch-target="showAllBtn"]'))
    this.activityEls = Array.from(this.element.querySelectorAll('[data-punch-activities-for]'))

    this.punchesByDate = new Map()
    this.punchesByUser = new Map()
    this.punchesByKey = new Map()
    this.punches.forEach(el => {
      const date = el.dataset.date
      const slug = el.dataset.userSlug
      const day = parseInt(date.slice(-2), 10)
      el._punchDay = day
      if (!this.punchesByDate.has(date)) this.punchesByDate.set(date, [])
      this.punchesByDate.get(date).push(el)
      if (!this.punchesByUser.has(slug)) this.punchesByUser.set(slug, [])
      this.punchesByUser.get(slug).push(el)
      this.punchesByKey.set(`${slug}:${day}`, el)
    })
  }

  captureActiveGroups () {
    this.activeUsers = new Set()
    this.activeDays = new Set()
    this.allActive = this.punches?.length > 0 && this.punches.every(isPressed)
    if (this.allActive) return
    this.punchesByUser?.forEach((els, slug) => {
      if (els.length > 0 && els.every(isPressed)) this.activeUsers.add(slug)
    })
    this.punchesByDate?.forEach((els, date) => {
      if (els.length > 0 && els.every(isPressed)) this.activeDays.add(date)
    })
  }

  applyCapturedGroups () {
    if (this.allActive) {
      this.punches.forEach(press)
      return
    }
    this.activeUsers.forEach(slug => (this.punchesByUser.get(slug) || []).forEach(press))
    this.activeDays.forEach(date => (this.punchesByDate.get(date) || []).forEach(press))
  }

  toggle (event) {
    const clicked = event.currentTarget
    clicked.setAttribute('aria-pressed', isPressed(clicked) ? 'false' : 'true')
    this.afterToggle()
  }

  toggleDay (event) {
    this.toggleGroup(this.punchesByDate.get(event.currentTarget.dataset.date))
  }

  toggleUser (event) {
    this.toggleGroup(this.punchesByUser.get(event.currentTarget.dataset.userSlug))
  }

  toggleGroup (targets) {
    if (!targets || targets.length === 0) return
    const allActive = targets.every(isPressed)
    targets.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  showAll () {
    this.punches.forEach(press)
    this.afterToggle()
  }

  hideAll () {
    this.punches.forEach(unpress)
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
    this.syncAllButtons()
  }

  syncRidgeBars () {
    this.ridgeBars.forEach(bar => {
      const targets = this.punchesByDate.get(bar.dataset.date) || []
      bar.setAttribute('aria-pressed', groupAllActive(targets) ? 'true' : 'false')
    })
  }

  syncUserButtons () {
    this.userButtons.forEach(btn => {
      const targets = this.punchesByUser.get(btn.dataset.userSlug) || []
      btn.setAttribute('aria-pressed', groupAllActive(targets) ? 'true' : 'false')
    })
  }

  syncActivities () {
    const activeIds = new Set(
      this.punches.filter(isPressed).map(el => el.dataset.punchId)
    )
    this.activityEls.forEach(el => {
      el.classList.toggle('hidden!', !activeIds.has(el.dataset.punchActivitiesFor))
    })
    const containers = new Set(this.activityEls.map(el => el.parentElement))
    containers.forEach(container => {
      const anyVisible = Array.from(container.children).some(child => !child.classList.contains('hidden!'))
      container.classList.toggle('hidden!', !anyVisible)
    })
  }

  syncAllButtons () {
    const anyActive = this.punches.some(isPressed)
    const allActive = this.punches.length > 0 && this.punches.every(isPressed)
    this.hideAllBtns.forEach(btn => btn.classList.toggle('hidden', !anyActive))
    this.showAllBtns.forEach(btn => btn.setAttribute('aria-pressed', allActive ? 'true' : 'false'))
  }

  updateUrl () {
    const byUser = new Map()
    this.punches.filter(isPressed).forEach(el => {
      const slug = el.dataset.userSlug
      if (!byUser.has(slug)) byUser.set(slug, [])
      byUser.get(slug).push(el._punchDay)
    })
    const encoded = Array.from(byUser, ([slug, days]) =>
      `${slug}:${days.sort((a, b) => a - b).join(',')}`
    ).join(';')
    const url = new URL(window.location.href)
    const current = url.searchParams.get('selected') ?? ''
    if (encoded === current) return
    if (encoded) {
      url.searchParams.set('selected', encoded)
    } else {
      url.searchParams.delete('selected')
    }
    window.history.replaceState(null, '', url)
  }
}

const isPressed = (el) => el.getAttribute('aria-pressed') === 'true'
const press = (el) => el.setAttribute('aria-pressed', 'true')
const unpress = (el) => el.setAttribute('aria-pressed', 'false')
const groupAllActive = (els) => els.length > 0 && els.every(isPressed)
