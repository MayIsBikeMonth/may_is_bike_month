import { Controller } from '@hotwired/stimulus'

// Connects to data-controller='competition-table--user-row--component'
export default class extends Controller {
  connect () {
    console.log('app/components/competition_table/user_row/component_controller.js - connected to:')
    console.log(this.element)
  }
}
