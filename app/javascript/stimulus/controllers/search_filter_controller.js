import { Controller } from '@hotwired/stimulus';

export default class SearchFilterController extends Controller {
  static targets = ['input', 'form', 'filters'];
  static values = {
    debounceWait: { type: Number, default: 300 },
    minCharacters: { type: Number, default: 1 }
  };

  connect() {
    // Store the debounce timer
    this.debounceTimer = null;

    // Add event listener to search input
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('input', () => this.debouncedSearch());
      this.inputTarget.addEventListener('keydown', e => this.handleKeydown(e));
    }

    // Add event listeners to filters
    if (this.hasFiltersTarget) {
      const filterInputs = this.filtersTarget.querySelectorAll('input, select');

      filterInputs.forEach(input => {
        input.addEventListener('change', () => this.performSearch());
      });
    }
  }

  debouncedSearch() {
    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }

    // Set new timer
    this.debounceTimer = setTimeout(() => {
      this.performSearch();
    }, this.debounceWaitValue);
  }

  handleKeydown(event) {
    // Allow Enter key to submit immediately
    if (event.key === 'Enter') {
      event.preventDefault();
      if (this.debounceTimer) {
        clearTimeout(this.debounceTimer);
      }
      this.performSearch();
    }

    // Allow Escape to clear
    if (event.key === 'Escape') {
      this.clear();
    }
  }

  performSearch() {
    const query = this.hasInputTarget ? this.inputTarget.value.trim() : '';

    // Don't search if less than minimum characters (unless empty)
    if (query.length > 0 && query.length < this.minCharactersValue) {
      return;
    }

    // Build search URL with query and filters
    const url = new URL(this.formTarget.action, window.location.origin);

    // Add search query
    if (query) {
      url.searchParams.set('q', query);
    }

    // Add filter values
    if (this.hasFiltersTarget) {
      const filterInputs = this.filtersTarget.querySelectorAll('input, select');

      filterInputs.forEach(input => {
        if (input.type === 'checkbox') {
          if (input.checked) {
            url.searchParams.append(input.name, input.value);
          }
        } else if (input.type === 'radio') {
          if (input.checked) {
            url.searchParams.set(input.name, input.value);
          }
        } else if (input.value) {
          url.searchParams.set(input.name, input.value);
        }
      });
    }

    // Navigate to search results
    window.location.href = url.toString();
  }

  clear() {
    if (this.hasInputTarget) {
      this.inputTarget.value = '';
      this.inputTarget.focus();
    }

    // Reset filters
    if (this.hasFiltersTarget) {
      const filterInputs = this.filtersTarget.querySelectorAll('input, select');

      filterInputs.forEach(input => {
        if (input.type === 'checkbox' || input.type === 'radio') {
          input.checked = false;
        } else {
          input.value = '';
        }
      });
    }

    // Navigate back to tours without filters
    window.location.href = this.element.closest('form').getAttribute('action');
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
  }
}
