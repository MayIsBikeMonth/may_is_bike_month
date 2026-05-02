import { Controller } from '@hotwired/stimulus'
import { isPressed, press, unpress, setPressed, allPressed } from 'utils/aria_pressed'
import { readUrlSelection, writeUrlSelection } from 'utils/punchcard_url'

// data-controller="punch". Selection state is aria-pressed on the DOM
// itself; selectedDays records explicit day-group intent (ridge-bar clicks
// and Show all activities). Day intent is what differentiates ?days= from
// ?selected=user:day in the URL: clicking individual punches never adds to
// selectedDays, even if every punch on that day happens to be pressed.
//
// Across a turbo morph: capture group intent on turbo:before-morph-element,
// rebuild + re-apply on turbo:morph-element. Indexing uses querySelectorAll
// because Stimulus target getters are stale inside the synchronous morph
// handler (target tracking updates on a later MutationObserver microtask).

// ---- small utilities ---------------------------------------------------

const appendToMapKey = (map, key, value) => {
  if (!map.has(key)) map.set(key, [])
  map.get(key).push(value)
}

const emptyIntent = () => ({ allActive: false, users: new Set() })

// ---- Stimulus controller ----------------------------------------------

export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn', 'showAllBtn']

  // === Lifecycle =========================================================

  connect () {
    this.selectedDays = new Set()
    this.capturedIntent = emptyIntent()
    this.beforeMorphHandler = (event) => {
      if (event.target === this.element) this.captureActiveGroups()
    }
    // idiomorph bubbles turbo:morph-element for every descendant during one
    // morph cycle — debounce into a single rebuild.
    this.morphHandler = () => this.scheduleRebuild()
    this.element.addEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.addEventListener('turbo:morph-element', this.morphHandler)
    this.rebuild()
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.removeEventListener('turbo:morph-element', this.morphHandler)
  }

  // === Rebuild orchestration =============================================

  scheduleRebuild () {
    if (this.rebuildScheduled) return
    this.rebuildScheduled = true
    queueMicrotask(() => {
      this.rebuildScheduled = false
      this.rebuild()
    })
  }

  rebuild () {
    this.indexDom()
    this.selectedDays = new Set()
    this.applyUrlSelection()
    this.applyCapturedGroups()
    this.sync()
    this.syncUrl()
  }

  // === DOM indexing ======================================================

  // Read the DOM directly; see file-header note on morph timing / stale
  // Stimulus targets.
  indexDom () {
    const q = (selector) => Array.from(this.element.querySelectorAll(selector))
    this.punches = q('[data-punch-target="punch"]')
    this.ridgeBars = q('[data-punch-target="ridgeBar"]')
    this.userButtons = q('[data-punch-target="userButton"]')
    this.hideAllBtns = q('[data-punch-target="hideAllBtn"]')
    this.showAllBtns = q('[data-punch-target="showAllBtn"]')
    this.activityEls = q('[data-punch-activities-for]')

    this.punchesByDate = new Map()
    this.punchesByUser = new Map()
    this.punchesByKey = new Map()
    for (const el of this.punches) {
      const { date, userSlug: slug } = el.dataset
      const day = parseInt(date.slice(-2), 10)
      el._punchDay = day
      appendToMapKey(this.punchesByDate, date, el)
      appendToMapKey(this.punchesByUser, slug, el)
      this.punchesByKey.set(`${slug}:${day}`, el)
    }
  }

  dateStringForDay (day) {
    const bar = this.ridgeBars.find(b => parseInt(b.dataset.date.slice(-2), 10) === day)
    return bar?.dataset.date
  }

  // === URL state =========================================================

  applyUrlSelection () {
    const { byUser, days } = readUrlSelection()
    byUser.forEach((dayList, slug) => {
      dayList.forEach(day => {
        const punch = this.punchesByKey.get(`${slug}:${day}`)
        if (punch) press(punch)
      })
    })
    days.forEach(day => {
      const date = this.dateStringForDay(day)
      if (!date) return
      this.selectedDays.add(date)
      ;(this.punchesByDate.get(date) || []).forEach(press)
    })
  }

  syncUrl () {
    const byUser = new Map()
    this.punches.filter(isPressed).forEach(el => {
      if (this.selectedDays.has(el.dataset.date)) return
      appendToMapKey(byUser, el.dataset.userSlug, el._punchDay)
    })
    const days = Array.from(this.selectedDays).map(d => parseInt(d.slice(-2), 10))
    writeUrlSelection({ byUser, days })
  }

  // === Group intent captured / replayed across morph =====================

  captureActiveGroups () {
    if (allPressed(this.punches)) {
      this.capturedIntent = { allActive: true, users: new Set() }
      return
    }
    const users = new Set()
    this.punchesByUser.forEach((els, slug) => { if (allPressed(els)) users.add(slug) })
    this.capturedIntent = { allActive: false, users }
  }

  applyCapturedGroups () {
    const { allActive, users } = this.capturedIntent
    if (allActive) {
      this.punches.forEach(press)
      return
    }
    users.forEach(slug => (this.punchesByUser.get(slug) || []).forEach(press))
    this.selectedDays.forEach(date => (this.punchesByDate.get(date) || []).forEach(press))
  }

  // === User actions ======================================================

  toggle (event) {
    const el = event.currentTarget
    setPressed(el, !isPressed(el))
    this.afterToggle()
  }

  toggleDay (event) {
    const date = event.currentTarget.dataset.date
    if (this.selectedDays.has(date)) {
      this.selectedDays.delete(date)
      ;(this.punchesByDate.get(date) || []).forEach(unpress)
    } else {
      this.selectedDays.add(date)
      ;(this.punchesByDate.get(date) || []).forEach(press)
    }
    this.afterToggle()
  }

  toggleUser (event) {
    this.toggleGroup(this.punchesByUser.get(event.currentTarget.dataset.userSlug))
  }

  toggleGroup (targets) {
    if (!targets || targets.length === 0) return
    const on = !targets.every(isPressed)
    targets.forEach(el => setPressed(el, on))
    this.afterToggle()
  }

  showAll () {
    this.punches.forEach(press)
    this.ridgeBars.forEach(bar => this.selectedDays.add(bar.dataset.date))
    this.afterToggle()
  }

  hideAll () {
    this.punches.forEach(unpress)
    this.selectedDays.clear()
    this.afterToggle()
  }

  // Drop selectedDays entries whose punches are no longer all pressed —
  // unpressing any individual punch on a day breaks the day-group intent
  // and the URL switches from days= back to selected=.
  pruneSelectedDays () {
    for (const date of [...this.selectedDays]) {
      const punches = this.punchesByDate.get(date) || []
      if (punches.length > 0 && punches.some(el => !isPressed(el))) {
        this.selectedDays.delete(date)
      }
    }
  }

  afterToggle () {
    this.pruneSelectedDays()
    this.sync()
    this.syncUrl()
  }

  // === Sync rendered UI ==================================================

  sync () {
    this.syncRidgeBars()
    this.syncUserButtons()
    this.syncActivities()
    this.syncAllButtons()
  }

  syncRidgeBars () {
    this.ridgeBars.forEach(bar => {
      const date = bar.dataset.date
      const punches = this.punchesByDate.get(date) || []
      const on = punches.length > 0 ? allPressed(punches) : this.selectedDays.has(date)
      setPressed(bar, on)
    })
  }

  syncUserButtons () {
    this.userButtons.forEach(btn => {
      setPressed(btn, allPressed(this.punchesByUser.get(btn.dataset.userSlug) || []))
    })
  }

  syncActivities () {
    const activeIds = new Set(this.punches.filter(isPressed).map(el => el.dataset.punchId))
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
    this.hideAllBtns.forEach(btn => btn.classList.toggle('hidden', !anyActive))
    this.showAllBtns.forEach(btn => setPressed(btn, allPressed(this.punches)))
  }
}
