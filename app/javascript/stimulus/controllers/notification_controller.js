import { Controller } from '@hotwired/stimulus';

export default class NotificationController extends Controller {
  static targets = ['toast'];

  connect() {
    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, 5000);

    // Listen for animation end to remove element
    this.element.addEventListener(
      'animationend',
      this.handleAnimationEnd.bind(this)
    );
  }

  dismiss() {
    clearTimeout(this.timeout);

    // Add fade-out animation
    this.element.style.animation = 'slideOut 0.3s ease-out forwards';
  }

  handleAnimationEnd(event) {
    if (event.animationName === 'slideOut') {
      this.element.remove();
    }
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
