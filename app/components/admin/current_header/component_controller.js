import { Controller } from '@hotwired/stimulus'

// Connects to data-controller='admin--current-header--component'
export default class extends Controller {
  connect () {
    console.log("current header")
    const updatePage = this.updatePage // eslint-disable-line
    document.querySelectorAll('.updateOnChange')
      .forEach(el => el.addEventListener('change', updatePage))
  }

  updatePage (event) {
    const updateUrl = event.target.getAttribute('data-updateUrl')
      .replace('UpdateThis', event.target.value)
    location.href = updateUrl // eslint-disable-line
  }
}
