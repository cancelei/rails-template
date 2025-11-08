import { Application } from '@hotwired/stimulus';
import { screen, waitFor, within } from '@testing-library/dom';
import userEvent from '@testing-library/user-event';
import MobileNavController from '../../../stimulus/controllers/mobile_nav_controller';

const mobileNavHTML = `
  <div data-controller="mobile-nav" data-mobile-nav-transition-duration-value="0">
    <button type="button"
            aria-label="Open navigation menu"
            aria-controls="mobile-nav-menu"
            aria-expanded="false"
            data-mobile-nav-target="toggle"
            data-action="mobile-nav#toggle">
      Toggle
    </button>

    <div id="mobile-nav-menu"
         class="mobile-nav-menu pointer-events-none opacity-0"
         data-mobile-nav-target="menu"
         role="dialog"
         aria-modal="true"
         aria-hidden="true"
         aria-label="Mobile navigation">

      <div class="mobile-nav-backdrop opacity-0"
           data-mobile-nav-target="backdrop"
           data-action="click->mobile-nav#close"></div>

      <div class="mobile-nav-panel translate-x-full"
           data-mobile-nav-target="panel">
        <header>
          <button type="button"
                  data-action="mobile-nav#close"
                  aria-label="Close navigation menu">
            Close
          </button>
        </header>
        <nav>
          <a href="/home" data-action="click->mobile-nav#close">Home</a>
          <button type="button" data-action="mobile-nav#close">Sign Out</button>
        </nav>
      </div>
    </div>
  </div>
`;

describe('MobileNavController', () => {
  let application;

  beforeEach(() => {
    document.body.style.overflow = '';
    document.body.innerHTML = mobileNavHTML;

    application = Application.start();
    application.register('mobile-nav', MobileNavController);
  });

  afterEach(() => {
    application?.stop();
    document.body.style.overflow = '';
    document.body.innerHTML = '';
    jest.useRealTimers();
  });

  it('initializes in a closed state', () => {
    const toggleButton = screen.getByRole('button', {
      name: /open navigation menu/i
    });
    const menu = document.getElementById('mobile-nav-menu');
    const backdrop = document.querySelector('.mobile-nav-backdrop');

    expect(menu.dataset.state).toBe('closed');
    expect(menu).toHaveAttribute('aria-hidden', 'true');
    expect(menu).toHaveClass('pointer-events-none', 'opacity-0');
    expect(toggleButton).toHaveAttribute('aria-expanded', 'false');
    expect(toggleButton).toHaveAttribute('aria-label', 'Open navigation menu');
    expect(backdrop).toHaveClass('opacity-0');
    expect(document.body).toHaveStyle({ overflow: '' });
  });

  it('opens the menu and focuses the first interactive element when toggled', async () => {
    const user = userEvent.setup();
    const toggleButton = screen.getByRole('button', {
      name: /open navigation menu/i
    });

    await user.click(toggleButton);

    const menu = document.getElementById('mobile-nav-menu');
    const backdrop = document.querySelector('.mobile-nav-backdrop');
    const panel = document.querySelector('.mobile-nav-panel');
    const closeButton = within(panel).getByRole('button', {
      name: /close navigation menu/i
    });

    expect(menu.dataset.state).toBe('open');
    expect(menu).toHaveAttribute('aria-hidden', 'false');
    expect(menu).toHaveClass('pointer-events-auto', 'opacity-100');
    expect(backdrop).toHaveClass('opacity-100');
    expect(panel).not.toHaveClass('translate-x-full');
    expect(toggleButton).toHaveAttribute('aria-expanded', 'true');
    expect(toggleButton).toHaveAttribute('aria-label', 'Close navigation menu');
    expect(document.body).toHaveStyle({ overflow: 'hidden' });

    await waitFor(() => {
      expect(closeButton).toHaveFocus();
    });
  });

  it('closes the menu via the close button and restores focus', async () => {
    jest.useFakeTimers();

    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });
    const toggleButton = screen.getByRole('button', {
      name: /open navigation menu/i
    });

    await user.click(toggleButton);

    const panel = document.querySelector('.mobile-nav-panel');
    const closeButton = within(panel).getByRole('button', {
      name: /close navigation menu/i
    });

    await user.click(closeButton);

    const menu = document.getElementById('mobile-nav-menu');
    const backdrop = document.querySelector('.mobile-nav-backdrop');

    expect(menu.dataset.state).toBe('closed');
    expect(menu).toHaveAttribute('aria-hidden', 'true');
    expect(menu).toHaveClass('pointer-events-none', 'opacity-0');
    expect(backdrop).toHaveClass('opacity-0');
    expect(panel).toHaveClass('translate-x-full');

    jest.runAllTimers();

    expect(document.body).toHaveStyle({ overflow: '' });
    await waitFor(() => {
      expect(toggleButton).toHaveFocus();
    });
  });

  it('closes the menu when the backdrop is clicked', async () => {
    jest.useFakeTimers();

    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });
    const toggleButton = screen.getByRole('button', {
      name: /open navigation menu/i
    });
    const menu = document.getElementById('mobile-nav-menu');
    const backdrop = document.querySelector('.mobile-nav-backdrop');

    await user.click(toggleButton);
    backdrop.click();

    expect(menu.dataset.state).toBe('closed');
    expect(menu).toHaveAttribute('aria-hidden', 'true');
    expect(menu).toHaveClass('pointer-events-none', 'opacity-0');

    jest.runAllTimers();

    expect(document.body).toHaveStyle({ overflow: '' });
    await waitFor(() => {
      expect(toggleButton).toHaveFocus();
    });
  });

  it('does not steal focus back to the toggle when a navigation link is clicked', async () => {
    jest.useFakeTimers();

    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });
    const toggleButton = screen.getByRole('button', {
      name: /open navigation menu/i
    });

    await user.click(toggleButton);

    const homeLink = screen.getByRole('link', { name: 'Home' });

    await user.click(homeLink);

    const menu = document.getElementById('mobile-nav-menu');

    expect(menu.dataset.state).toBe('closed');
    expect(menu).toHaveAttribute('aria-hidden', 'true');

    jest.runAllTimers();

    expect(document.body).toHaveStyle({ overflow: '' });
    expect(toggleButton).not.toHaveFocus();
  });
});
