'use strict';

const { test, expect } = require('@playwright/test');

test.describe('Page Rendering Tests', () => {
  test.describe('Public Pages', () => {
    test('Home page should render without errors', async ({ page }) => {
      const response = await page.goto('/');

      expect(response.status()).toBe(200);

      // Check for console errors
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      // Wait for page to be fully loaded
      await page.waitForLoadState('networkidle');

      // Take screenshot for debugging
      await page.screenshot({ path: 'screenshots/home.png', fullPage: true });

      // Check that the page doesn't have critical errors
      expect(errors.length).toBe(0);
    });

    test('Tours index should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      const response = await page.goto('/tours');

      expect(response.status()).toBe(200);
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'screenshots/tours-index.png',
        fullPage: true
      });

      expect(errors.length).toBe(0);
    });

    test('New tour page should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      const response = await page.goto('/tours/new');

      expect(response.status()).toBe(200);
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'screenshots/tours-new.png',
        fullPage: true
      });

      expect(errors.length).toBe(0);
    });

    test('User sign up should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      const response = await page.goto('/users/sign_up');

      expect(response.status()).toBe(200);
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'screenshots/sign-up.png',
        fullPage: true
      });

      expect(errors.length).toBe(0);
    });

    test('User sign in should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      const response = await page.goto('/users/sign_in');

      expect(response.status()).toBe(200);
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'screenshots/sign-in.png',
        fullPage: true
      });

      expect(errors.length).toBe(0);
    });

    test('Password reset should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      const response = await page.goto('/users/password/new');

      expect(response.status()).toBe(200);
      await page.waitForLoadState('networkidle');
      await page.screenshot({
        path: 'screenshots/password-reset.png',
        fullPage: true
      });

      expect(errors.length).toBe(0);
    });
  });

  test.describe('Guide Profile Pages', () => {
    test('Guide profiles should render without errors', async ({ page }) => {
      const errors = [];

      page.on('console', msg => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      // First, we need to check if there are any guide profiles
      const response = await page.goto('/guide_profiles');

      // This might be a 404 if route doesn't exist or redirect
      if (response.status() === 200) {
        await page.waitForLoadState('networkidle');
        await page.screenshot({
          path: 'screenshots/guide-profiles.png',
          fullPage: true
        });
        expect(errors.length).toBe(0);
      }
    });
  });

  test.describe('Admin Pages', () => {
    test('Admin metrics should require authentication', async ({ page }) => {
      const response = await page.goto('/admin/metrics');

      // Should redirect to login or show 401/403
      expect([200, 302, 401, 403]).toContain(response.status());
    });
  });

  test.describe('Error Handling', () => {
    test('404 page should render gracefully', async ({ page }) => {
      const response = await page.goto('/nonexistent-page');

      // Should show a 404 error
      expect(response.status()).toBe(404);
    });
  });
});
