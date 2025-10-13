import { Application } from '@hotwired/stimulus';
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers';
// The application.js pack is deferred by default which means that nothing imported
// in this file will begin executing until after the page has loaded. This helps to
// speed up page loading times, especially in apps that have large amounts of js.
//
// If you have javascript that *must* execute before the page has finished loading,
// create a separate 'boot.js' pack in the frontend/packs directory and import any
// required files in that. Also remember to add a separate pack_tag entry with:
// <%= javascript_pack_tag "boot", "data-turbolinks-track": "reload" %>
// to the views/layouts/application.html.erb file above the existing application pack tag.
//
import * as Sentry from '@sentry/browser';
import '@hotwired/turbo-rails';

import '../stylesheets/application.scss';
/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ./images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
const images = require.context('../images', true);
// eslint-disable-next-line no-unused-vars
const imagePath = name => images(name, true);

// Initialize Sentry Error Reporting
//
// Import all your application's JS after this section because we need Sentry
// to be initialized **before** we import any of our actual JS so that Sentry
// can report errors from it.
//
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.SENTRY_ENV || process.env.RAILS_ENV
});

// Uncomment this Sentry by sending an exception every time the page loads.
// Obviously this is a very noisy activity and we do have limits on Sentry so
// you should never do this on a deployed environment.
//
// Sentry.captureException(new Error('Away-team to Enterprise, two to beam directly to sick bay...'));

// Import all your application's JS here
//
// import '../javascript/example-1.js';
// import { someFunc } from '../javascript/funcs.js';

// Set up stimulus.js https://stimulus.hotwired.dev/
const application = Application.start();
const context = require.context('../stimulus/controllers', true, /.(js|ts)$/u);

application.load(definitionsFromContext(context));

// If you don't want to load all Stimulus controllers in this pack, you
// can either use separate folders for each set of controllers you want to
// load or you can remove the `definitionsFromContext` stuff here and
// instead import each controller explicitly e.g.
//
//   import HelloController from "../stimulus/controllers/hello_controller"
//   application.register("hello", HelloController)
//   import OtherController from "../stimulus/controllers/other_controller"
//   application.register("other", OtherController)

// Configure stimulus development experience
application.debug = false;
// window.Stimulus = application;
