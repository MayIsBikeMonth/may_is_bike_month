import { Controller } from '@hotwired/stimulus'
import { isPressed, press, unpress, setPressed, allPressed } from 'utils/aria_pressed'
import { readUrlSelection, writeUrlSelection } from 'utils/punchcard_url'

/*
Connects to data-controller="punch"

Selection model
---------------
Every clickable cell — individual punches, per-user rows, per-day ridge bars,
and the "Show all activities" button — drives off aria-pressed on the DOM
elements themselves. Punch state lives on <button data-punch-target="punch">
elements; group buttons reflect whether every punch in their group is pressed.
A ridge bar for a day that has no punches yet has nothing to derive from, so
its state lives in the `selectedEmptyDays` Set.

Elements with `data-punch-activities-for="<id>"` are revealed when the
matching punch is pressed.

URL persistence and serialization live in `utils/punchcard_url.js`.
aria-pressed read/write helpers live in `utils/aria_pressed.js`.

Turbo morph coordination
------------------------
Broadcasts morph the wrapper in place. We:
  1. capture group intent on turbo:before-morph-element (which users / days /
     all-punches were fully selected, plus the empty-day set);
  2. rebuild indexes + re-apply URL + re-apply captured intent on
     turbo:morph-element (debounced into one rebuild per morph cycle);
  3. read the DOM directly via querySelectorAll — Stimulus target getters are
     stale during the synchronous morph event handler because target tracking
     updates on a MutationObserver microtask that hasn't run yet.
*/

// ---- small utilities ---------------------------------------------------

const appendToMapKey = (map, key, value) => {
  if (!map.has(key)) map.set(key, [])
  map.get(key).push(value)
}

const toggleSetMember = (set, value) => {
  if (set.has(value)) set.delete(value); else set.add(value)
}

const emptyIntent = () => ({ allActive: false, users: new Set(), days: new Set() })

// ---- Stimulus controller ----------------------------------------------

export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn', 'showAllBtn']

  // === Lifecycle =========================================================

  connect () {
    this.selectedEmptyDays = new Set()
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
    this.selectedEmptyDays = new Set()
    this.applyUrlSelection()
    this.pruneSelectedEmptyDays()
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
      if (date) this.selectedEmptyDays.add(date)
    })
  }

  syncUrl () {
    const byUser = new Map()
    this.punches.filter(isPressed).forEach(el => {
      appendToMapKey(byUser, el.dataset.userSlug, el._punchDay)
    })
    const days = Array.from(this.selectedEmptyDays).map(d => parseInt(d.slice(-2), 10))
    writeUrlSelection({ byUser, days })
  }

  // Dates with punches now have their state derived from those punches, so
  // drop them from selectedEmptyDays (which is only meaningful for dates
  // that have zero punches).
  pruneSelectedEmptyDays () {
    for (const date of [...this.selectedEmptyDays]) {
      if (this.punchesByDate.has(date)) this.selectedEmptyDays.delete(date)
    }
  }

  // === Group intent captured / replayed across morph =====================

  captureActiveGroups () {
    if (allPressed(this.punches)) {
      this.capturedIntent = { allActive: true, users: new Set(), days: new Set() }
      return
    }
    const users = new Set()
    const days = new Set()
    this.punchesByUser.forEach((els, slug) => { if (allPressed(els)) users.add(slug) })
    this.punchesByDate.forEach((els, date) => { if (allPressed(els)) days.add(date) })
    this.selectedEmptyDays.forEach(date => days.add(date))
    this.capturedIntent = { allActive: false, users, days }
  }

  applyCapturedGroups () {
    const { allActive, users, days } = this.capturedIntent
    if (allActive) {
      this.punches.forEach(press)
      return
    }
    users.forEach(slug => (this.punchesByUser.get(slug) || []).forEach(press))
    days.forEach(date => (this.punchesByDate.get(date) || []).forEach(press))
  }

  // === User actions ======================================================

  toggle (event) {
    const el = event.currentTarget
    setPressed(el, !isPressed(el))
    this.afterToggle()
  }

  toggleDay (event) {
    const date = event.currentTarget.dataset.date
    const punches = this.punchesByDate.get(date)
    if (punches && punches.length > 0) {
      this.toggleGroup(punches)
    } else {
      toggleSetMember(this.selectedEmptyDays, date)
      this.afterToggle()
    }
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

  showAll () { this.punches.forEach(press); this.afterToggle() }
  hideAll () { this.punches.forEach(unpress); this.afterToggle() }

  afterToggle () {
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
      const on = punches.length > 0 ? allPressed(punches) : this.selectedEmptyDays.has(date)
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
