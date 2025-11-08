import { Controller } from '@hotwired/stimulus';

/**
 * Inline Edit Controller
 * Handles inline editing behavior for admin users
 *
 * Usage:
 *   <div data-controller="inline-edit" data-inline-edit-editable-value="true">
 *     <span>Content</span>
 *     <a href="/edit" data-action="click->inline-edit#edit">Edit</a>
 *   </div>
 */
export default class extends Controller {
  static values = {
    editable: Boolean,
    loading: Boolean
  };

  connect() {
    // Add keyboard shortcut for admins: Ctrl/Cmd + E to edit
    if (this.editableValue) {
      this.boundKeyHandler = this.handleKeyPress.bind(this);
      document.addEventListener('keydown', this.boundKeyHandler);
    }
  }

  disconnect() {
    if (this.boundKeyHandler) {
      document.removeEventListener('keydown', this.boundKeyHandler);
    }
  }

  /**
   * Handle edit button click
   * Shows loading state and adds visual feedback
   */
  edit(event) {
    if (!this.editableValue) {
      event.preventDefault();

      return;
    }

    // Add loading state
    this.loadingValue = true;
    this.element.classList.add('inline-edit-loading');

    // Remove loading state after a brief moment (Turbo will replace the content)
    setTimeout(() => {
      this.loadingValue = false;
      this.element.classList.remove('inline-edit-loading');
    }, 300);
  }

  /**
   * Handle keyboard shortcuts
   * Ctrl/Cmd + E: Toggle edit mode
   */
  handleKeyPress(event) {
    const isModifierPressed = event.ctrlKey || event.metaKey;

    if (isModifierPressed && event.key === 'e') {
      // Only activate if the element is in viewport and focused or hovered
      const rect = this.element.getBoundingClientRect();
      const isInViewport =
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight &&
        rect.right <= window.innerWidth;

      if (isInViewport && this.element.matches(':hover')) {
        event.preventDefault();
        const editButton = this.element.querySelector(
          '[data-action*="inline-edit#edit"]'
        );

        if (editButton) {
          editButton.click();
        }
      }
    }

    // ESC: Cancel editing (triggers cancel button if present)
    if (event.key === 'Escape') {
      const cancelButton = this.element.querySelector(
        '[data-action*="inline-edit#cancel"]'
      );

      if (cancelButton) {
        event.preventDefault();
        cancelButton.click();
      }
    }
  }

  /**
   * Handle successful save
   * Adds success flash animation
   */
  success() {
    this.element.classList.add('inline-edit-success');
    setTimeout(() => {
      this.element.classList.remove('inline-edit-success');
    }, 500);
  }

  /**
   * Handle cancel action
   * Reloads the original content via Turbo
   */
  cancel(event) {
    event.preventDefault();
    const link = event.currentTarget;

    if (link && link.href) {
      // Turbo will handle the navigation and content replacement
      // Just add visual feedback
      this.element.classList.add('inline-edit-loading');
    }
  }

  /**
   * Show visual indicator on hover (for accessibility)
   */
  mouseenter() {
    if (this.editableValue) {
      this.element.setAttribute(
        'aria-label',
        'Editable content - Click edit or press Ctrl+E'
      );
    }
  }

  mouseleave() {
    if (this.editableValue) {
      this.element.removeAttribute('aria-label');
    }
  }
}
