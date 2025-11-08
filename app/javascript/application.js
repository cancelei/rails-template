// Import external libraries
import { Application } from '@hotwired/stimulus';
import * as Turbo from '@hotwired/turbo-rails';
import * as Sentry from '@sentry/browser';
// Import Stimulus controllers
import AddClassController from './stimulus/controllers/add_class_controller.js';
import AdminTableController from './stimulus/controllers/admin_table_controller.js';
import BookingCalculatorController from './stimulus/controllers/booking_calculator_controller.js';
import ErrorHandlerController from './stimulus/controllers/error_handler_controller.js';
import FormValidationController from './stimulus/controllers/form_validation_controller.js';
import FormVisibilityController from './stimulus/controllers/form_visibility_controller.js';
import HelloController from './stimulus/controllers/hello_controller.js';
import ImageCropperController from './stimulus/controllers/image_cropper_controller.js';
import ImageGalleryController from './stimulus/controllers/image_gallery_controller.js';
import ImageUploadController from './stimulus/controllers/image_upload_controller.js';
import LoadingStateController from './stimulus/controllers/loading_state_controller.js';
import MobileNavController from './stimulus/controllers/mobile_nav_controller.js';
import ModalController from './stimulus/controllers/modal_controller.js';
import NotificationController from './stimulus/controllers/notification_controller.js';
import SearchController from './stimulus/controllers/search_controller.js';
import SearchFilterController from './stimulus/controllers/search_filter_controller.js';
import TurboFlashController from './stimulus/controllers/turbo_flash_controller.js';
import UploadProgressController from './stimulus/controllers/upload_progress_controller.js';

// Make Turbo available globally
window.Turbo = Turbo;

// Get Sentry config from meta tags (set in layout)
const sentryDsn = document.querySelector('meta[name="sentry-dsn"]')?.content;
const sentryEnv = document.querySelector(
  'meta[name="sentry-environment"]'
)?.content;

if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
    environment: sentryEnv || 'development'
  });
}

// Set up Stimulus
const application = Application.start();

// Register Stimulus controllers
application.register('add-class', AddClassController);
application.register('admin-table', AdminTableController);
application.register('booking-calculator', BookingCalculatorController);
application.register('error-handler', ErrorHandlerController);
application.register('form-validation', FormValidationController);
application.register('form-visibility', FormVisibilityController);
application.register('hello', HelloController);
application.register('image-cropper', ImageCropperController);
application.register('image-gallery', ImageGalleryController);
application.register('image-upload', ImageUploadController);
application.register('loading-state', LoadingStateController);
application.register('mobile-nav', MobileNavController);
application.register('modal', ModalController);
application.register('notification', NotificationController);
application.register('search', SearchController);
application.register('search-filter', SearchFilterController);
application.register('turbo-flash', TurboFlashController);
application.register('upload-progress', UploadProgressController);

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;
