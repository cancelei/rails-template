import { Controller } from '@hotwired/stimulus';
import { DirectUpload } from '@rails/activestorage';

// Connects to data-controller="upload-progress"
export default class extends Controller {
  static targets = [
    'input',
    'progressBar',
    'progressText',
    'progressContainer'
  ];

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener(
        'change',
        this.handleFileSelect.bind(this)
      );
    }
  }

  handleFileSelect(event) {
    const files = Array.from(event.target.files);

    if (files.length === 0) {
      return;
    }

    this.showProgressBar();
    this.uploadFiles(files);
  }

  uploadFiles(files) {
    const uploads = files.map(file => this.uploadFile(file));

    Promise.all(uploads)
      .then(signedIds => {
        this.onUploadComplete(signedIds);
      })
      .catch(error => {
        this.onUploadError(error);
      });
  }

  uploadFile(file) {
    return new Promise((resolve, reject) => {
      const upload = new DirectUpload(file, this.directUploadUrl, this);

      upload.create((error, blob) => {
        if (error) {
          reject(error);
        } else {
          resolve(blob.signed_id);
        }
      });
    });
  }

  get directUploadUrl() {
    return (
      this.inputTarget.dataset.directUploadUrl ||
      '/rails/active_storage/direct_uploads'
    );
  }

  // DirectUpload delegate methods
  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener('progress', event =>
      this.directUploadDidProgress(event)
    );
  }

  directUploadDidProgress(event) {
    const progress = (event.loaded / event.total) * 100;

    this.updateProgressBar(progress);
  }

  showProgressBar() {
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.classList.remove('hidden');
    }
    this.updateProgressBar(0);
  }

  hideProgressBar() {
    if (this.hasProgressContainerTarget) {
      setTimeout(() => {
        this.progressContainerTarget.classList.add('hidden');
      }, 1000); // Hide after 1 second
    }
  }

  updateProgressBar(percentage) {
    const rounded = Math.round(percentage);

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${rounded}%`;
      this.progressBarTarget.setAttribute('aria-valuenow', rounded);
    }

    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${rounded}%`;
    }
  }

  onUploadComplete(signedIds) {
    this.updateProgressBar(100);

    // Dispatch event with signed IDs
    this.element.dispatchEvent(
      new CustomEvent('upload-complete', {
        detail: { signedIds },
        bubbles: true
      })
    );

    // Hide progress bar after a delay
    this.hideProgressBar();

    // Show success message
    this.showMessage('Upload complete!', 'success');
  }

  onUploadError(error) {
    console.error('Upload error:', error);

    // Show error message
    this.showMessage('Upload failed. Please try again.', 'error');

    // Reset progress bar
    this.updateProgressBar(0);
    this.hideProgressBar();

    // Dispatch error event
    this.element.dispatchEvent(
      new CustomEvent('upload-error', {
        detail: { error },
        bubbles: true
      })
    );
  }

  showMessage(message, type = 'info') {
    // Dispatch notification event
    this.element.dispatchEvent(
      new CustomEvent('show-notification', {
        detail: { message, type },
        bubbles: true
      })
    );
  }
}
