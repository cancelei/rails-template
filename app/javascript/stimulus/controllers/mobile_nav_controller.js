import { Controller } from '@hotwired/stimulus';

// Mobile navigation controller for hamburger menu functionality
export default class extends Controller {
  static targets = ['menu', 'panel', 'backdrop', 'toggle'];
  static values = {
    transitionDuration: Number
  };

  connect() {
    this.handleEscape = this.handleEscape.bind(this);
    document.addEventListener('keydown', this.handleEscape);

    this._applyClosedState({ immediate: true, restoreFocus: false });
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleEscape);
    this._enableBodyScroll();
  }

  toggle() {
    if (this._isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (!this.hasMenuTarget || this._isOpen()) {
      return;
    }

    this.previousActiveElement =
      document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null;

    this.menuTarget.dataset.state = 'open';
    this.menuTarget.setAttribute('aria-hidden', 'false');
    this.menuTarget.classList.remove('pointer-events-none', 'opacity-0');
    this.menuTarget.classList.add('pointer-events-auto', 'opacity-100');

    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('opacity-0');
      this.backdropTarget.classList.add('opacity-100');
    }

    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove('translate-x-full');
    }

    this._disableBodyScroll();
    this._updateToggleAria(true);

    requestAnimationFrame(() => {
      const focusable = this.panelTarget?.querySelector(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
      );

      focusable?.focus();
    });
  }

  close(event) {
    const clickedLink =
      event?.target instanceof Element && event.target.closest('a[href]');

    this._applyClosedState({ restoreFocus: !clickedLink });
  }

  handleEscape(event) {
    if (event.key === 'Escape' && this._isOpen()) {
      this._applyClosedState();
    }
  }

  _applyClosedState({ immediate = false, restoreFocus = true } = {}) {
    if (!this.hasMenuTarget) {
      return;
    }

    this.menuTarget.dataset.state = 'closed';
    this.menuTarget.setAttribute('aria-hidden', 'true');
    this.menuTarget.classList.remove('pointer-events-auto', 'opacity-100');
    this.menuTarget.classList.add('pointer-events-none', 'opacity-0');

    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('opacity-100');
      this.backdropTarget.classList.add('opacity-0');
    }

    if (this.hasPanelTarget) {
      this.panelTarget.classList.add('translate-x-full');
    }

    this._updateToggleAria(false);

    const finalize = () => {
      this._enableBodyScroll();

      if (!restoreFocus) {
        this.previousActiveElement = null;

        return;
      }

      let focusTarget = null;

      if (this.hasToggleTarget) {
        focusTarget = this.toggleTarget;
      } else if (
        this.previousActiveElement instanceof HTMLElement &&
        document.contains(this.previousActiveElement)
      ) {
        focusTarget = this.previousActiveElement;
      }

      if (focusTarget) {
        const focus =
          typeof requestAnimationFrame === 'function'
            ? requestAnimationFrame
            : callback => setTimeout(callback, 0);

        focus(() => focusTarget.focus());
      }

      this.previousActiveElement = null;
    };

    const delay = this.transitionDuration;

    if (immediate || delay <= 0) {
      finalize();
    } else {
      window.setTimeout(finalize, delay);
    }
  }

  _isOpen() {
    return this.hasMenuTarget && this.menuTarget.dataset.state === 'open';
  }

  _updateToggleAria(isOpen) {
    if (!this.hasToggleTarget) {
      return;
    }

    this.toggleTarget.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    this.toggleTarget.setAttribute(
      'aria-label',
      isOpen ? 'Close navigation menu' : 'Open navigation menu'
    );
  }

  _disableBodyScroll() {
    if (this.bodyOverflow !== undefined) {
      return;
    }

    this.bodyOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
  }

  _enableBodyScroll() {
    if (this.bodyOverflow === undefined) {
      return;
    }

    if (this.bodyOverflow) {
      document.body.style.overflow = this.bodyOverflow;
    } else {
      document.body.style.removeProperty('overflow');
    }

    this.bodyOverflow = undefined;
  }

  get transitionDuration() {
    return this.hasTransitionDurationValue ? this.transitionDurationValue : 300;
  }
}
