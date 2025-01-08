import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import processCheckouts from "@salesforce/apex/LibraryItemService.processCheckouts";
import processReturn from "@salesforce/apex/LibraryItemService.processReturn";

export default class LibraryCheckout extends LightningElement {
  barcode = "";
  isProcessing = false;
  isReturnMode = false;

  renderedCallback() {
    this.template.querySelector("lightning-input").focus();
  }

  handleBarcodeChange(event) {
    this.barcode = event.target.value;
  }

  handleKeyPress(event) {
    if (event.key === "Enter") {
      if (this.isReturnMode) {
        this.handleReturn();
      } else {
        this.handleCheckout();
      }
    }
  }

  toggleMode() {
    this.isReturnMode = !this.isReturnMode;
    this.barcode = "";
    this.template.querySelector("lightning-input").focus();
  }

  async handleCheckout() {
    if (!this.barcode || this.isProcessing) return;

    this.isProcessing = true;
    try {
      await processCheckouts({
        barcodes: [this.barcode]
      });

      // Dispatch event for status update
      this.dispatchEvent(
        new CustomEvent("statusupdate", {
          detail: {
            barcode: this.barcode,
            newStatus: "Checked Out"
          },
          bubbles: true,
          composed: true
        })
      );

      this.showToast("Success", "Item checked out successfully", "success");
    } catch (error) {
      this.showToast("Error", this.extractErrorMessage(error), "error");
    } finally {
      this.barcode = "";
      this.isProcessing = false;
      this.template.querySelector("lightning-input").focus();
    }
  }

  async handleReturn() {
    if (!this.barcode || this.isProcessing) return;

    this.isProcessing = true;
    try {
      await processReturn({ barcode: this.barcode });

      // Dispatch event for status update
      this.dispatchEvent(
        new CustomEvent("statusupdate", {
          detail: {
            barcode: this.barcode,
            newStatus: "Available"
          },
          bubbles: true,
          composed: true
        })
      );

      this.showToast("Success", "Item returned successfully", "success");
    } catch (error) {
      this.showToast("Error", this.extractErrorMessage(error), "error");
    } finally {
      this.barcode = "";
      this.isProcessing = false;
      this.template.querySelector("lightning-input").focus();
    }
  }

  extractErrorMessage(error) {
    return error.body?.message || error.message || "Unknown error occurred";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  get modeButtonLabel() {
    return this.isReturnMode ? "Switch to Checkout" : "Switch to Return";
  }

  get inputPlaceholder() {
    return this.isReturnMode
      ? "Scan item to return..."
      : "Scan item to checkout...";
  }

  get actionText() {
    return this.isReturnMode ? "return" : "check out";
  }
}
