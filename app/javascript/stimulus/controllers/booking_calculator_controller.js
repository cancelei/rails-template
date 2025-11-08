import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="booking-calculator"
export default class extends Controller {
  static targets = [
    'spotsInput',
    'addOnCheckbox',
    'tourSubtotal',
    'addOnsSubtotal',
    'addOnsRow',
    'totalPrice'
  ];

  static values = {
    tourPrice: Number,
    currency: String
  };

  connect() {
    this.calculate();
  }

  calculate() {
    const spots = parseInt(this.spotsInputTarget.value) || 1;
    const tourPrice = this.tourPriceValue || 0;

    // Calculate tour subtotal
    const tourSubtotal = tourPrice * spots;

    // Calculate add-ons total
    let addOnsTotal = 0;

    if (this.hasAddOnCheckboxTarget) {
      this.addOnCheckboxTargets.forEach(checkbox => {
        if (checkbox.checked) {
          const price = parseInt(checkbox.dataset.price) || 0;
          const pricingType = checkbox.dataset.pricingType;

          if (pricingType === 'per_person') {
            // Per person pricing: multiply by number of spots
            addOnsTotal += price * spots;
          } else {
            // Flat fee: add once regardless of spots
            addOnsTotal += price;
          }
        }
      });
    }

    // Calculate grand total
    const total = tourSubtotal + addOnsTotal;

    // Update display
    this.updatePriceDisplay(this.tourSubtotalTarget, tourSubtotal);
    this.updatePriceDisplay(this.addOnsSubtotalTarget, addOnsTotal);
    this.updatePriceDisplay(this.totalPriceTarget, total);

    // Show/hide add-ons row
    if (addOnsTotal > 0) {
      this.addOnsRowTarget.style.display = 'flex';
    } else {
      this.addOnsRowTarget.style.display = 'none';
    }
  }

  updatePriceDisplay(element, priceInCents) {
    const priceInCurrency = priceInCents / 100.0;
    const formatted = this.formatCurrency(priceInCurrency);

    element.textContent = formatted;
  }

  formatCurrency(amount) {
    const currency = this.currencyValue || 'BRL';
    let symbol = '$';

    switch (currency) {
      case 'BRL':
        symbol = 'R$';
        break;
      case 'USD':
        symbol = '$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      default:
        symbol = currency;
    }

    return `${symbol}${amount.toFixed(2)}`;
  }
}
