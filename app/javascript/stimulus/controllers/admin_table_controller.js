import { Controller } from '@hotwired/stimulus';

export default class AdminTableController extends Controller {
  static targets = ['checkbox', 'selectAll', 'bulkBar', 'count'];

  connect() {
    this.updateSelection();
  }

  toggleAll(event) {
    const isChecked = event.target.checked;

    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked;
    });
    this.updateSelection();
  }

  toggle() {
    this.updateSelection();
  }

  updateSelection() {
    const selected = this.selectedCheckboxes;
    const total = this.checkboxTargets.length;

    // Update select all checkbox state
    if (this.hasSelectAllTarget) {
      if (selected.length === 0) {
        this.selectAllTarget.checked = false;
        this.selectAllTarget.indeterminate = false;
      } else if (selected.length === total) {
        this.selectAllTarget.checked = true;
        this.selectAllTarget.indeterminate = false;
      } else {
        this.selectAllTarget.checked = false;
        this.selectAllTarget.indeterminate = true;
      }
    }

    // Update count and show/hide bulk actions bar
    if (this.hasCountTarget) {
      this.countTarget.textContent = selected.length;
    }

    if (this.hasBulkBarTarget) {
      if (selected.length > 0) {
        this.bulkBarTarget.classList.remove('hidden');
      } else {
        this.bulkBarTarget.classList.add('hidden');
      }
    }
  }

  get selectedCheckboxes() {
    return this.checkboxTargets.filter(cb => cb.checked);
  }

  get selectedIds() {
    return this.selectedCheckboxes.map(cb => cb.value);
  }
}
