import { Controller } from '@hotwired/stimulus';

export default class FormValidationController extends Controller {
  static targets = ['input', 'form'];
  static classes = ['error', 'success', 'validating'];

  connect() {
    // Initialize validation state for all inputs
    this.inputs.forEach(input => {
      this.setupInput(input);
    });
  }

  setupInput(input) {
    // Add input event listener for real-time validation
    input.addEventListener('input', () => this.validateInput(input));
    input.addEventListener('blur', () => this.validateInput(input));
    input.addEventListener('change', () => this.validateInput(input));
  }

  validateInput(input) {
    const isValid = this.checkValidity(input);

    // Update UI based on validity
    this.updateInputUI(input, isValid);

    // Create or update error message
    this.updateErrorMessage(input, isValid);

    // Update form submit button state
    this.updateSubmitButtonState();
  }

  checkValidity(input) {
    // HTML5 validation
    if (!input.checkValidity()) {
      return false;
    }

    // Custom validation rules
    if (input.type === 'email') {
      return this.isValidEmail(input.value);
    }

    if (input.type === 'password') {
      const minLength = input.dataset.minLength || 8;

      return input.value.length >= minLength;
    }

    if (input.dataset.type === 'url') {
      return this.isValidUrl(input.value);
    }

    return true;
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/u;

    return emailRegex.test(email);
  }

  isValidUrl(url) {
    try {
      const urlObject = new URL(url);

      return Boolean(urlObject);
    } catch {
      return false;
    }
  }

  updateInputUI(input, isValid) {
    const formGroup = input.closest('.form-group');

    if (!formGroup) {
      return;
    }

    // Remove all status classes
    formGroup.classList.remove(this.errorClass, this.successClass);

    // Add appropriate status class
    if (input.value) {
      if (isValid) {
        formGroup.classList.add(this.successClass);
      } else {
        formGroup.classList.add(this.errorClass);
      }
    }
  }

  updateErrorMessage(input, isValid) {
    const formGroup = input.closest('.form-group');

    if (!formGroup) {
      return;
    }

    let errorDiv = formGroup.querySelector('.form-error');

    if (!isValid && input.value) {
      if (!errorDiv) {
        errorDiv = document.createElement('p');
        errorDiv.classList.add('form-error');
        formGroup.appendChild(errorDiv);
      }
      errorDiv.textContent = this.getErrorMessage(input);
      errorDiv.style.display = 'block';
    } else if (errorDiv) {
      errorDiv.style.display = 'none';
    }
  }

  getErrorMessage(input) {
    if (input.validity.valueMissing) {
      return `${input.placeholder || 'This field'} is required`;
    }

    if (input.validity.typeMismatch) {
      if (input.type === 'email') {
        return 'Please enter a valid email address';
      }
      if (input.type === 'url') {
        return 'Please enter a valid URL';
      }
    }

    if (input.validity.tooShort) {
      return `Must be at least ${input.minLength} characters`;
    }

    if (input.validity.tooLong) {
      return `Must not exceed ${input.maxLength} characters`;
    }

    if (input.dataset.type === 'password' && input.value) {
      const minLength = input.dataset.minLength || 8;

      if (input.value.length < minLength) {
        return `Password must be at least ${minLength} characters`;
      }
    }

    return 'This field is invalid';
  }

  updateSubmitButtonState() {
    const form = this.formTarget || this.element.closest('form');

    if (!form) {
      return;
    }

    const submitButton = form.querySelector('button[type="submit"]');

    if (!submitButton) {
      return;
    }

    // Check if all required inputs are valid
    const allValid = Array.from(this.inputs).every(input => {
      if (input.required) {
        return input.checkValidity() && this.checkValidity(input);
      }

      return true;
    });

    submitButton.disabled = !allValid;
  }

  get inputs() {
    return (
      this.inputTargets ||
      Array.from(this.element.querySelectorAll('input, textarea, select'))
    );
  }

  get errorClass() {
    return this.classes.has('error')
      ? this.classes.get('error')
      : 'form-field-error';
  }

  get successClass() {
    return this.classes.has('success')
      ? this.classes.get('success')
      : 'form-field-success';
  }
}
