import { createElement } from "lwc";
import LibraryCheckout from "c/libraryCheckout";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import processCheckouts from "@salesforce/apex/LibraryItemService.processCheckouts";
import processReturn from "@salesforce/apex/LibraryItemService.processReturn";

// Mock the Apex methods
jest.mock(
  "@salesforce/apex/LibraryItemService.processCheckouts",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/LibraryItemService.processReturn",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe("c-library-checkout", () => {
  let element;

  beforeEach(() => {
    element = createElement("c-library-checkout", {
      is: LibraryCheckout
    });
    document.body.appendChild(element);
    jest.clearAllMocks();
  });

  afterEach(() => {
    document.body.removeChild(element);
  });

  // Test initial state
  it("initializes with correct default values", () => {
    // Get elements
    const input = element.shadowRoot.querySelector("lightning-input");
    const modeButton = element.shadowRoot.querySelector("lightning-button");
    const spinner = element.shadowRoot.querySelector("lightning-spinner");

    // Verify initial state
    expect(input.value).toBe("");
    expect(input.placeholder).toBe("Scan item to checkout...");
    expect(modeButton.label).toBe("Switch to Return");
    expect(spinner).toBeNull();
  });

  // Test mode toggle
  it("toggles between checkout and return modes", () => {
    const modeButton = element.shadowRoot.querySelector("lightning-button");
    const input = element.shadowRoot.querySelector("lightning-input");

    // Initial state check
    expect(modeButton.label).toBe("Switch to Return");
    expect(input.placeholder).toBe("Scan item to checkout...");

    // Click toggle button
    modeButton.click();

    return Promise.resolve()
      .then(() => {
        // Check return mode
        expect(modeButton.label).toBe("Switch to Checkout");
        expect(input.placeholder).toBe("Scan item to return...");
        expect(input.value).toBe("");

        // Toggle back
        modeButton.click();
        return Promise.resolve();
      })
      .then(() => {
        // Check checkout mode
        expect(modeButton.label).toBe("Switch to Return");
        expect(input.placeholder).toBe("Scan item to checkout...");
      });
  });

  // Test barcode input and processing
  it("handles barcode input changes and processes it correctly", () => {
    const input = element.shadowRoot.querySelector("lightning-input");
    const testBarcode = "TEST123";

    // Mock the checkout method
    processCheckouts.mockResolvedValue();

    // Set the input value
    input.value = testBarcode;
    input.dispatchEvent(new CustomEvent("change"));

    // Verify input value
    expect(input.value).toBe(testBarcode);

    // Trigger Enter key
    input.dispatchEvent(new KeyboardEvent("keypress", { key: "Enter" }));

    return Promise.resolve().then(() => {
      // Verify the checkout was called with the correct barcode
      expect(processCheckouts).toHaveBeenCalledWith({
        barcodes: [testBarcode]
      });
    });
  });

  // Test processing state
  it("shows spinner during processing", () => {
    let resolvePromise;
    processCheckouts.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolvePromise = resolve;
        })
    );

    const input = element.shadowRoot.querySelector("lightning-input");

    // Trigger checkout
    input.value = "TEST123";
    input.dispatchEvent(new CustomEvent("change"));
    input.dispatchEvent(new KeyboardEvent("keypress", { key: "Enter" }));

    return Promise.resolve()
      .then(() => {
        // Check spinner is shown
        const spinner = element.shadowRoot.querySelector("lightning-spinner");
        expect(spinner).not.toBeNull();

        // Resolve the checkout
        resolvePromise();
        return Promise.resolve();
      })
      .then(() => {
        // Check spinner is gone
        const spinner = element.shadowRoot.querySelector("lightning-spinner");
        expect(spinner).toBeNull();
      });
  });

  // Test successful status update event
  it("dispatches status update event on successful checkout", () => {
    processCheckouts.mockResolvedValue();

    // Set up spy for status update event
    const statusHandler = jest.fn();
    element.addEventListener("statusupdate", statusHandler);

    const input = element.shadowRoot.querySelector("lightning-input");

    // Trigger checkout
    input.value = "TEST123";
    input.dispatchEvent(new CustomEvent("change"));
    input.dispatchEvent(new KeyboardEvent("keypress", { key: "Enter" }));

    return Promise.resolve().then(() => {
      expect(statusHandler).toHaveBeenCalled();
      const updateEvent = statusHandler.mock.calls[0][0];
      expect(updateEvent.detail).toEqual({
        barcode: "TEST123",
        newStatus: "Checked Out"
      });
    });
  });
});
