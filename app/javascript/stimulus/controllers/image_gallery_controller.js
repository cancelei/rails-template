import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="image-gallery"
export default class extends Controller {
  static targets = [
    'image',
    'modal',
    'modalImage',
    'modalCaption',
    'deleteConfirm'
  ];

  static values = {
    currentIndex: { type: Number, default: 0 }
  };

  connect() {
    this.setupKeyboardNavigation();
  }

  disconnect() {
    this.teardownKeyboardNavigation();
  }

  setupKeyboardNavigation() {
    this.keyboardHandler = this.handleKeyboard.bind(this);
    document.addEventListener('keydown', this.keyboardHandler);
  }

  teardownKeyboardNavigation() {
    document.removeEventListener('keydown', this.keyboardHandler);
  }

  handleKeyboard(event) {
    if (!this.hasModalTarget || this.modalTarget.classList.contains('hidden')) {
      return;
    }

    switch (event.key) {
      case 'Escape':
        this.closeModal();
        break;
      case 'ArrowLeft':
        this.previousImage();
        break;
      case 'ArrowRight':
        this.nextImage();
        break;
      default:
        // No action for other keys
        break;
    }
  }

  // Open image in lightbox modal
  openImage(event) {
    const imageElement = event.currentTarget;
    const imageUrl = imageElement.dataset.fullUrl || imageElement.src;
    const caption = imageElement.dataset.caption || imageElement.alt || '';
    const index = parseInt(imageElement.dataset.index || '0');

    this.currentIndexValue = index;

    if (this.hasModalImageTarget) {
      this.modalImageTarget.src = imageUrl;
      this.modalImageTarget.alt = caption;
    }

    if (this.hasModalCaptionTarget) {
      this.modalCaptionTarget.textContent = caption;
    }

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('hidden');
      document.body.style.overflow = 'hidden'; // Prevent scrolling
    }
  }

  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add('hidden');
      document.body.style.overflow = ''; // Restore scrolling
    }
  }

  previousImage() {
    if (!this.hasImageTarget) {
      return;
    }

    const totalImages = this.imageTargets.length;

    this.currentIndexValue =
      (this.currentIndexValue - 1 + totalImages) % totalImages;
    this.updateModalImage();
  }

  nextImage() {
    if (!this.hasImageTarget) {
      return;
    }

    const totalImages = this.imageTargets.length;

    this.currentIndexValue = (this.currentIndexValue + 1) % totalImages;
    this.updateModalImage();
  }

  updateModalImage() {
    if (!this.hasImageTarget || !this.imageTargets[this.currentIndexValue]) {
      return;
    }

    const currentImage = this.imageTargets[this.currentIndexValue];
    const imageUrl = currentImage.dataset.fullUrl || currentImage.src;
    const caption = currentImage.dataset.caption || currentImage.alt || '';

    if (this.hasModalImageTarget) {
      // Add fade effect
      this.modalImageTarget.style.opacity = '0';

      setTimeout(() => {
        this.modalImageTarget.src = imageUrl;
        this.modalImageTarget.alt = caption;
        this.modalImageTarget.style.opacity = '1';
      }, 150);
    }

    if (this.hasModalCaptionTarget) {
      this.modalCaptionTarget.textContent = caption;
    }
  }

  // Delete image with confirmation
  deleteImage(event) {
    const imageContainer = event.currentTarget.closest('[data-image-id]');

    if (!imageContainer) {
      return;
    }

    const imageId = imageContainer.dataset.imageId;
    const imageName = imageContainer.dataset.imageName || 'this image';

    // eslint-disable-next-line no-alert
    if (confirm(`Are you sure you want to delete ${imageName}?`)) {
      // Add visual feedback
      imageContainer.style.opacity = '0.5';

      // Here you would typically make an AJAX request to delete the image
      // For now, we'll just remove it from the DOM
      imageContainer.remove();

      // Dispatch event for parent to handle
      this.element.dispatchEvent(
        new CustomEvent('image-deleted', {
          detail: { imageId },
          bubbles: true
        })
      );
    }
  }

  // Drag and drop reordering
  dragStart(event) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/html', event.currentTarget.innerHTML);
    event.currentTarget.classList.add('dragging');
  }

  dragEnd(event) {
    event.currentTarget.classList.remove('dragging');
  }

  dragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';

    const afterElement = this.getDragAfterElement(event.clientY);
    const dragging = document.querySelector('.dragging');

    if (afterElement === null) {
      this.element.appendChild(dragging);
    } else {
      this.element.insertBefore(dragging, afterElement);
    }
  }

  drop(event) {
    event.preventDefault();

    // Dispatch event with new order
    const newOrder = Array.from(this.imageTargets).map((img, index) => ({
      id: img.closest('[data-image-id]')?.dataset.imageId,
      position: index
    }));

    this.element.dispatchEvent(
      new CustomEvent('images-reordered', {
        detail: { order: newOrder },
        bubbles: true
      })
    );
  }

  getDragAfterElement(y) {
    const draggableElements = [
      ...this.element.querySelectorAll("[draggable='true']:not(.dragging)")
    ];

    return draggableElements.reduce(
      (closest, child) => {
        const box = child.getBoundingClientRect();
        const offset = y - box.top - box.height / 2;

        if (offset < 0 && offset > closest.offset) {
          return { offset, element: child };
        }

        return closest;
      },
      { offset: Number.NEGATIVE_INFINITY }
    ).element;
  }

  // Zoom in/out in modal
  zoomIn() {
    if (!this.hasModalImageTarget) {
      return;
    }

    const currentScale = parseFloat(this.modalImageTarget.dataset.scale || '1');
    const newScale = Math.min(currentScale * 1.2, 3); // Max 3x zoom

    this.modalImageTarget.style.transform = `scale(${newScale})`;
    this.modalImageTarget.dataset.scale = newScale.toString();
  }

  zoomOut() {
    if (!this.hasModalImageTarget) {
      return;
    }

    const currentScale = parseFloat(this.modalImageTarget.dataset.scale || '1');
    const newScale = Math.max(currentScale / 1.2, 0.5); // Min 0.5x zoom

    this.modalImageTarget.style.transform = `scale(${newScale})`;
    this.modalImageTarget.dataset.scale = newScale.toString();
  }

  resetZoom() {
    if (!this.hasModalImageTarget) {
      return;
    }

    this.modalImageTarget.style.transform = 'scale(1)';
    this.modalImageTarget.dataset.scale = '1';
  }
}
