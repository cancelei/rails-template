import { Controller } from '@hotwired/stimulus';

export default class ModalController extends Controller {
  connect() {
    this.element.showModal?.();
    this.element.classList.remove('hidden');
    document.body.style.overflow = 'hidden';

    // Close on backdrop click
    this.element.addEventListener('click', this.backdropClick.bind(this));
  }

  disconnect() {
    this.element.classList.add('hidden');
    document.body.style.overflow = '';
  }

  close(event) {
    event?.preventDefault();

    // Remove the turbo frame content
    this.element.innerHTML = '';

    // Hide the modal
    this.disconnect();
  }

  backdropClick(event) {
    if (event.target === this.element) {
      this.close();
    }
  }

  // Handle escape key
  handleKeyup(event) {
    if (event.key === 'Escape') {
      this.close();
    }
  }
}
