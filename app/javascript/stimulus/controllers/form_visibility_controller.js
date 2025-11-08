import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="form-visibility"
export default class FormVisibilityController extends Controller {
  static values = {
    watch: String,
    showOn: String
  };

  connect() {
    this.updateVisibility();
  }

  watchValueChanged() {
    this.updateVisibility();
  }

  updateVisibility() {
    const watchField = document.getElementById(this.watchValue);

    if (!watchField) {
      return;
    }

    const shouldShow = watchField.value === this.showOnValue;

    if (shouldShow) {
      this.element.style.display = 'block';
      // Restore required attribute if it was stored
      const inputs = this.element.querySelectorAll('input, select, textarea');
      inputs.forEach(input => {
        if (input.dataset.wasRequired === 'true') {
          input.required = true;
        }
      });
    } else {
      this.element.style.display = 'none';
      // Clear the field value when hidden and remove required attribute
      const inputs = this.element.querySelectorAll('input, select, textarea');

      inputs.forEach(input => {
        if (input.type !== 'hidden') {
          input.value = '';
          // Store the required state and remove it
          if (input.required) {
            input.dataset.wasRequired = 'true';
            input.required = false;
          }
        }
      });
    }

    // Listen for changes
    watchField.addEventListener('change', () => this.updateVisibility());
  }
}
