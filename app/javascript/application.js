import '@hotwired/turbo-rails'
import '@honeybadger-io/js'
import 'controllers'
import 'chartkick'
import 'Chart.bundle'
import TimeLocalizer from '@bikeindex/time-localizer'

/* global Honeybadger */
const honeybadgerApiKey = document.querySelector('meta[name="honeybadger-api-key"]')?.content
if (honeybadgerApiKey) {
  Honeybadger.configure({
    apiKey: honeybadgerApiKey,
    environment: document.querySelector('meta[name="honeybadger-environment"]')?.content
  })
}

function localizeTime () {
  if (!window.timeLocalizer) window.timeLocalizer = new TimeLocalizer()
  window.timeLocalizer.localize()
}

document.addEventListener('DOMContentLoaded', localizeTime)
document.addEventListener('turbo:load', localizeTime)
document.addEventListener('turbo:render', localizeTime)
document.addEventListener('turbo:frame-render', localizeTime)

// MIBM SPECIFIC Functions

window.currentUnitPreference = () => {
  let unitPreference = localStorage.getItem('unitPreference')
  if (unitPreference === null || unitPreference !== 'metric') {
    unitPreference = 'imperial'
  } else {
    unitPreference = 'metric'
  }
  localStorage.setItem('unitPreference', unitPreference)
  return unitPreference
}

window.toggleUnitPreference = (event = false) => {
  event && event.preventDefault()
  const newUnit = window.currentUnitPreference() === 'metric' ? 'imperial' : 'metric'
  localStorage.setItem('unitPreference', newUnit)
  window.showPreferredUnit()
}

window.showPreferredUnit = () => {
  const unit = window.currentUnitPreference()
  document.querySelectorAll(`.unit-${unit}`).forEach(el => el.classList.remove('hidden'))
  const hiddenUnit = unit === 'metric' ? 'imperial' : 'metric'
  document.querySelectorAll(`.unit-${hiddenUnit}`).forEach(el => el.classList.add('hidden'))
}

const currentActivityVisibility = () => {
  let activityVisibility = localStorage.getItem('activityVisibility')
  if (activityVisibility === null || activityVisibility !== 'show-all') {
    activityVisibility = 'hidden'
  } else {
    activityVisibility = 'show-all'
  }
  localStorage.setItem('activityVisibility', activityVisibility)
  return activityVisibility
}

const showActivityVisibility = () => {
  if (currentActivityVisibility() === 'hidden') {
    document.querySelectorAll('.activityList').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-shown').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-hidden').forEach(el => el.classList.remove('hidden'))
  } else {
    document.querySelectorAll('.activityList, .toggleActivities-shown').forEach(el => el.classList.remove('hidden'))
    document.querySelectorAll('.toggleActivities-hidden').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-shown').forEach(el => el.classList.remove('hidden'))
  }
}

const toggleActivities = () => {
  document.querySelectorAll('.activityList').forEach(el => el.classList.toggle('hidden'))
  const newVisibility = currentActivityVisibility() === 'hidden' ? 'show-all' : 'hidden'
  localStorage.setItem('activityVisibility', newVisibility)
  showActivityVisibility()
}

// Make a request to internal endpoint that updates Strava
window.updateStravaInBackground = async function () {
  const response = await fetch('/update_strava')
  const updateResponse = await response.json()
  console.log(updateResponse)
  setInterval(function () {
    window.updateStravaInBackground()
    // Manual page reload
    window.location.reload()
  }, 600000) // ~ 10 minutes
}

document.addEventListener('turbo:load', () => {
  if (window.shouldUpdateStravaInBackground) {
    window.updateStravaInBackground()
  }

  // This is set on the window on the view pages (but not the lookbook pages)
  if (window.enableToggles) {
    // Add the click selector to the toggle button
    document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
    window.showPreferredUnit()

    // Toggle activities
    showActivityVisibility()
    document.querySelector('#toggleIndividualActivities')?.addEventListener('click', toggleActivities)

    // Add the click selector to the toggle button
    document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
    window.showPreferredUnit()
  }
})
