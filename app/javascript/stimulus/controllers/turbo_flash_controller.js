import { Controller } from '@hotwired/stimulus';

/**
 * Controller to add visual flash effect when Turbo Frame content updates
 * Provides visual feedback for real-time updates
 *
 * Usage:
 *   Add to the turbo-frame element:
 *   <%= turbo_frame_tag dom_id(object), data: { controller: "turbo-flash" } do %>
 */
export default class TurboFlashController extends Controller {
  connect() {
    // Listen for turbo:before-frame-render event
    this.element.addEventListener(
      'turbo:before-frame-render',
      this.handleBeforeRender.bind(this)
    );
  }

  handleBeforeRender(event) {
    // Add flash animation class
    const newFrame = event.detail.newFrame;

    if (newFrame) {
      // Add animation class to the new content
      newFrame.classList.add('animate-flash-update');

      // Remove animation class after it completes
      setTimeout(() => {
        newFrame.classList.remove('animate-flash-update');
      }, 1000);
    }
  }

  disconnect() {
    this.element.removeEventListener(
      'turbo:before-frame-render',
      this.handleBeforeRender
    );
  }
}
