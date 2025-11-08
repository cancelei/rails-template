import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="image-upload"
export default class extends Controller {
  static targets = ['input', 'preview', 'dropzone', 'error', 'fileInfo'];
  static values = {
    maxSize: { type: Number, default: 5 * 1024 * 1024 }, // 5MB default
    acceptedTypes: {
      type: Array,
      default: ['image/png', 'image/jpeg', 'image/jpg', 'image/webp']
    },
    multiple: { type: Boolean, default: false }
  };

  connect() {
    console.log('✅ Image upload controller connected!');
    console.log(
      'Dropzone target:',
      this.hasDropzoneTarget ? 'FOUND' : 'NOT FOUND'
    );
    console.log('Input target:', this.hasInputTarget ? 'FOUND' : 'NOT FOUND');
    console.log(
      'Preview target:',
      this.hasPreviewTarget ? 'FOUND' : 'NOT FOUND'
    );
    console.log('Max size:', this.maxSizeValue);
    this.setupDragAndDrop();
  }

  setupDragAndDrop() {
    if (!this.hasDropzoneTarget) {
      return; // Prevent default drag behaviors
    }
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(
        eventName,
        this.preventDefaults.bind(this),
        false
      );
      document.body.addEventListener(
        eventName,
        this.preventDefaults.bind(this),
        false
      );
    });

    // Highlight drop zone when item is dragged over it
    ['dragenter', 'dragover'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(
        eventName,
        this.highlight.bind(this),
        false
      );
    });
    ['dragleave', 'drop'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(
        eventName,
        this.unhighlight.bind(this),
        false
      );
    });

    // Handle dropped files
    this.dropzoneTarget.addEventListener(
      'drop',
      this.handleDrop.bind(this),
      false
    );
  }

  preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  highlight() {
    this.dropzoneTarget.classList.add('dragover');
  }

  unhighlight() {
    this.dropzoneTarget.classList.remove('dragover');
  }

  handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;

    this.handleFiles(files);
  }

  // Triggered when file input changes
  handleFileSelect(event) {
    console.log('📂 handleFileSelect called, files:', event.target.files);
    const files = event.target.files;

    this.handleFiles(files);
  }

  handleFiles(files) {
    // Clear previous errors
    this.clearError();

    // Validate files
    const validFiles = Array.from(files).filter(file =>
      this.validateFile(file)
    );

    if (validFiles.length === 0) {
      return;
    }

    // Show previews for valid files
    validFiles.forEach(file => this.previewFile(file));

    // Update file info
    this.updateFileInfo(validFiles);
  }

  validateFile(file) {
    // Check file type
    if (!this.acceptedTypesValue.includes(file.type)) {
      this.showError(
        `Invalid file type: ${file.name}. Please upload PNG, JPEG, or WEBP images.`
      );

      return false;
    }

    // Check file size
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = (this.maxSizeValue / (1024 * 1024)).toFixed(1);

      this.showError(
        `File too large: ${file.name}. Maximum size is ${maxSizeMB}MB.`
      );

      return false;
    }

    return true;
  }

  previewFile(file) {
    if (!this.hasPreviewTarget) {
      return;
    }

    const reader = new FileReader();

    reader.readAsDataURL(file);
    reader.onloadend = () => {
      const img = document.createElement('img');

      img.src = reader.result;
      img.classList.add('image-preview-thumbnail');
      img.alt = file.name;

      // Create preview container
      const previewContainer = document.createElement('div');

      previewContainer.classList.add('image-preview-container');

      // Add remove button
      const removeBtn = document.createElement('button');

      removeBtn.innerHTML = '×';
      removeBtn.classList.add('image-preview-remove');
      removeBtn.type = 'button';
      removeBtn.addEventListener('click', () => {
        previewContainer.remove();
        this.updateFileCount();
      });

      // Add file name
      const fileName = document.createElement('span');

      fileName.textContent = file.name;
      fileName.classList.add('image-preview-filename');

      previewContainer.appendChild(img);
      previewContainer.appendChild(fileName);
      previewContainer.appendChild(removeBtn);

      this.previewTarget.appendChild(previewContainer);
    };
  }

  updateFileInfo(files) {
    if (!this.hasFileInfoTarget) {
      return;
    }

    const count = files.length;
    const totalSize = files.reduce((sum, file) => sum + file.size, 0);
    const totalSizeMB = (totalSize / (1024 * 1024)).toFixed(2);

    this.fileInfoTarget.textContent = `${count} file(s) selected (${totalSizeMB} MB total)`;
  }

  updateFileCount() {
    if (!this.hasPreviewTarget || !this.hasFileInfoTarget) {
      return;
    }

    const count = this.previewTarget.querySelectorAll(
      '.image-preview-container'
    ).length;

    if (count === 0) {
      this.fileInfoTarget.textContent = '';
      // Reset input
      if (this.hasInputTarget) {
        this.inputTarget.value = '';
      }
    }
  }

  showError(message) {
    if (!this.hasErrorTarget) {
      return;
    }

    this.errorTarget.textContent = message;
    this.errorTarget.classList.remove('hidden');

    // Auto-hide error after 5 seconds
    setTimeout(() => {
      this.clearError();
    }, 5000);
  }

  clearError() {
    if (!this.hasErrorTarget) {
      return;
    }

    this.errorTarget.textContent = '';
    this.errorTarget.classList.add('hidden');
  }

  // Clear all previews
  clearPreviews() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = '';
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = '';
    }
    this.clearError();
    this.updateFileCount();
  }

  // Open file picker
  triggerFileSelect(event) {
    console.log('triggerFileSelect called');
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (this.hasInputTarget) {
      console.log('Clicking input target');
      this.inputTarget.click();
    } else {
      console.log('No input target found!');
    }
  }
}
