// libraryItemBrowser.test.js
import { createElement } from "lwc";
import { registerApexTestWireAdapter } from "@salesforce/sfdx-lwc-jest";
import LibraryItemBrowser from "c/libraryItemBrowser";
import getLibraryItems from "@salesforce/apex/LibraryItemBrowser.getLibraryItems";

// Create a wire adapter for the Apex method
const getLibraryItemsAdapter = registerApexTestWireAdapter(getLibraryItems);

describe("library-item-browser", () => {
  let element;

  beforeEach(() => {
    element = createElement("library-item-browser", {
      is: LibraryItemBrowser
    });
    document.body.appendChild(element);
  });

  afterEach(() => {
    document.body.removeChild(element);
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  // Test data display
  it("displays data from wire service", async () => {
    // Wait for component to render
    await Promise.resolve();

    // Emit mock data through the wire adapter
    const mockData = [
      {
        Id: "1",
        Name: "Test Book",
        Barcode__c: "B123",
        Status__c: "Available",
        Type__c: "Book",
        Category__c: "Fiction"
      }
    ];

    getLibraryItemsAdapter.emit(mockData);

    // Wait for any promises to resolve
    await Promise.resolve();

    // Verify the data table exists and contains our data
    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data).toEqual(mockData);
  });
});
