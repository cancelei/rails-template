import { Controller } from '@hotwired/stimulus';

export default class LoadingStateController extends Controller {
  static targets = ['button', 'form'];
  static values = {
    loadingText: String,
    loadingClass: { type: String, default: 'btn-loading' },
    disableOtherButtons: { type: Boolean, default: true }
  };

  connect() {
    // Find the form and attach submit listener
    const form = this.hasFormTarget
      ? this.formTarget
      : this.element.closest('form');

    if (form) {
      form.addEventListener('submit', e => this.handleFormSubmit(e));
    }
  }

  handleFormSubmit(event) {
    // Only proceed if the submit button that was clicked is in our controller's element
    const submitButton =
      event.submitter || this.element.querySelector('button[type="submit"]');

    if (!submitButton) {
      return;
    }

    // Don't disable if there are validation errors
    if (
      !submitButton.form.checkValidity &&
      !submitButton.form.checkValidity()
    ) {
      return;
    }

    this.disableButtons(submitButton);
  }

  disableButtons(submitButton) {
    // Disable the submit button
    this.setButtonLoading(submitButton);

    // Optionally disable other buttons on the page
    if (this.disableOtherButtonsValue) {
      const otherButtons = document.querySelectorAll('button[type="submit"]');

      otherButtons.forEach(button => {
        if (
          button !== submitButton &&
          !button.closest('[data-controller~="loading_state"]')
        ) {
          button.disabled = true;
          button.style.opacity = '0.5';
        }
      });
    }
  }

  setButtonLoading(button) {
    // Store original content
    button.dataset.originalContent = button.innerHTML;
    button.dataset.originalText = button.textContent;

    // Update button state
    button.disabled = true;
    button.classList.add(this.loadingClassValue);

    // Set loading text if provided
    if (this.loadingTextValue) {
      button.textContent = this.loadingTextValue;
    }

    // Add loading spinner
    this.addSpinner(button);
  }

  addSpinner(button) {
    const spinner = document.createElement('span');

    spinner.className =
      'inline-block animate-spin mr-2 w-4 h-4 border-2 border-current border-r-transparent rounded-full';
    spinner.innerHTML = '<svg class="hidden"></svg>';

    // Insert spinner at the beginning
    button.prepend(spinner);
  }

  reset() {
    const buttons = document.querySelectorAll('button[type="submit"]');

    buttons.forEach(button => {
      if (button.dataset.originalContent) {
        button.innerHTML = button.dataset.originalContent;
        button.disabled = false;
        button.classList.remove(this.loadingClassValue);
        button.style.opacity = '1';
        delete button.dataset.originalContent;
        delete button.dataset.originalText;
      }
    });
  }
}
