import { Controller } from '@hotwired/stimulus';

export default class ErrorHandlerController extends Controller {
  connect() {
    document.addEventListener(
      'turbo:frame-missing',
      this.handleFrameMissing.bind(this)
    );
    document.addEventListener(
      'turbo:fetch-request-error',
      this.handleFetchError.bind(this)
    );
  }

  disconnect() {
    document.removeEventListener(
      'turbo:frame-missing',
      this.handleFrameMissing.bind(this)
    );
    document.removeEventListener(
      'turbo:fetch-request-error',
      this.handleFetchError.bind(this)
    );
  }

  handleFrameMissing(event) {
    // When a Turbo Frame is missing, visit the URL directly
    event.preventDefault();
    event.detail.visit(event.detail.response.url);
  }

  handleFetchError(event) {
    console.error('Turbo fetch error:', event.detail);
    this.showNotification('Something went wrong. Please try again.', 'error');
  }

  showNotification(message, _type = 'info') {
    const container = document.getElementById('notifications');

    if (!container) {
      return;
    }

    const notification = document.createElement('div');

    notification.innerHTML = `
      <div class="bg-red-500 text-white px-6 py-4 rounded-lg shadow-lg flex items-center justify-between max-w-md"
           data-controller="notification">
        <div class="flex items-center">
          <svg class="w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
          </svg>
          <span>${message}</span>
        </div>
        <button type="button" class="ml-4 hover:opacity-75" data-action="click->notification#dismiss">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
          </svg>
        </button>
      </div>
    `;

    container.appendChild(notification.firstElementChild);
  }
}
