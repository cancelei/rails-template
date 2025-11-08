import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="image-cropper"
// Basic image cropping functionality - can be enhanced with libraries like Cropper.js
export default class extends Controller {
  static targets = ['input', 'preview', 'canvas', 'cropButton', 'cancelButton'];
  static values = {
    aspectRatio: { type: Number, default: 1 }, // 1:1 for avatars, 16:9 for covers, etc.
    maxWidth: { type: Number, default: 800 },
    maxHeight: { type: Number, default: 800 }
  };

  connect() {
    this.image = null;
    this.croppedBlob = null;
  }

  // Handle file selection
  handleFileSelect(event) {
    const [file] = event.target.files;

    if (!file) {
      return;
    }

    if (!file.type.match(/image.*/u)) {
      // eslint-disable-next-line no-alert
      alert('Please select an image file');

      return;
    }

    this.loadImage(file);
  }

  loadImage(file) {
    const reader = new FileReader();

    reader.onload = e => {
      this.image = new Image();
      this.image.onload = () => {
        this.showPreview();
      };
      this.image.src = e.target.result;
    };

    reader.readAsDataURL(file);
  }

  showPreview() {
    if (!this.hasPreviewTarget || !this.image) {
      return;
    }

    // Calculate dimensions maintaining aspect ratio
    let width = this.image.width;
    let height = this.image.height;

    if (width > this.maxWidthValue) {
      height = (height * this.maxWidthValue) / width;
      width = this.maxWidthValue;
    }

    if (height > this.maxHeightValue) {
      width = (width * this.maxHeightValue) / height;
      height = this.maxHeightValue;
    }

    // Create canvas
    const canvas = document.createElement('canvas');

    canvas.width = width;
    canvas.height = height;

    const ctx = canvas.getContext('2d');

    ctx.drawImage(this.image, 0, 0, width, height);

    // Show preview
    this.previewTarget.innerHTML = '';
    this.previewTarget.appendChild(canvas);

    // Show crop controls
    if (this.hasCropButtonTarget) {
      this.cropButtonTarget.classList.remove('hidden');
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.remove('hidden');
    }
  }

  // Crop image to aspect ratio
  crop() {
    if (!this.image || !this.hasPreviewTarget) {
      return;
    }

    const canvas = this.previewTarget.querySelector('canvas');

    if (!canvas) {
      return;
    }

    const sourceWidth = this.image.width;
    const sourceHeight = this.image.height;
    const sourceAspect = sourceWidth / sourceHeight;

    let cropHeight = 0;
    let cropWidth = 0;
    let cropX = 0;
    let cropY = 0;

    if (sourceAspect > this.aspectRatioValue) {
      // Image is wider than target aspect ratio
      cropHeight = sourceHeight;
      cropWidth = cropHeight * this.aspectRatioValue;
      cropX = (sourceWidth - cropWidth) / 2;
      cropY = 0;
    } else {
      // Image is taller than target aspect ratio
      cropWidth = sourceWidth;
      cropHeight = cropWidth / this.aspectRatioValue;
      cropX = 0;
      cropY = (sourceHeight - cropHeight) / 2;
    }

    // Calculate output dimensions
    let outputWidth = Math.min(cropWidth, this.maxWidthValue);
    let outputHeight = outputWidth / this.aspectRatioValue;

    if (outputHeight > this.maxHeightValue) {
      outputHeight = this.maxHeightValue;
      outputWidth = outputHeight * this.aspectRatioValue;
    }

    // Create cropped canvas
    const croppedCanvas = document.createElement('canvas');

    croppedCanvas.width = outputWidth;
    croppedCanvas.height = outputHeight;

    const ctx = croppedCanvas.getContext('2d');

    ctx.drawImage(
      this.image,
      cropX,
      cropY,
      cropWidth,
      cropHeight,
      0,
      0,
      outputWidth,
      outputHeight
    );

    // Convert to blob
    croppedCanvas.toBlob(
      blob => {
        this.croppedBlob = blob;

        // Update preview
        this.previewTarget.innerHTML = '';
        this.previewTarget.appendChild(croppedCanvas);

        // Dispatch event with cropped image
        this.element.dispatchEvent(
          new CustomEvent('image-cropped', {
            detail: { blob, canvas: croppedCanvas },
            bubbles: true
          })
        );

        // Create a new File object from the blob
        const croppedFile = new File([blob], 'cropped-image.jpg', {
          type: 'image/jpeg'
        });

        // Update the input with the cropped file
        this.updateFileInput(croppedFile);
      },
      'image/jpeg',
      0.9
    );
  }

  updateFileInput(file) {
    if (!this.hasInputTarget) {
      return;
    }

    // Create a new DataTransfer to hold the file
    const dataTransfer = new DataTransfer();

    dataTransfer.items.add(file);
    this.inputTarget.files = dataTransfer.files;
  }

  cancel() {
    // Reset everything
    this.image = null;
    this.croppedBlob = null;

    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = '';
    }

    if (this.hasInputTarget) {
      this.inputTarget.value = '';
    }

    if (this.hasCropButtonTarget) {
      this.cropButtonTarget.classList.add('hidden');
    }

    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.add('hidden');
    }
  }

  // Rotate image 90 degrees
  rotate() {
    if (!this.image) {
      return;
    }

    const canvas = document.createElement('canvas');

    canvas.width = this.image.height;
    canvas.height = this.image.width;

    const ctx = canvas.getContext('2d');

    ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.rotate((90 * Math.PI) / 180);
    ctx.drawImage(this.image, -this.image.width / 2, -this.image.height / 2);

    // Convert back to image
    canvas.toBlob(blob => {
      const url = URL.createObjectURL(blob);

      this.image = new Image();
      this.image.onload = () => {
        URL.revokeObjectURL(url);
        this.showPreview();
      };
      this.image.src = url;
    });
  }

  // Flip horizontally
  flipHorizontal() {
    if (!this.image) {
      return;
    }

    const canvas = document.createElement('canvas');

    canvas.width = this.image.width;
    canvas.height = this.image.height;

    const ctx = canvas.getContext('2d');

    ctx.translate(canvas.width, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(this.image, 0, 0);

    // Convert back to image
    canvas.toBlob(blob => {
      const url = URL.createObjectURL(blob);

      this.image = new Image();
      this.image.onload = () => {
        URL.revokeObjectURL(url);
        this.showPreview();
      };
      this.image.src = url;
    });
  }
}
