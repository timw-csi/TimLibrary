import { LightningElement, wire } from "lwc";
import getLibraryItems from "@salesforce/apex/LibraryItemBrowser.getLibraryItems";

export default class LibraryItemBrowser extends LightningElement {
  items = [];
  error;
  isLoading = false;
  searchTerm = "";
  selectedType = "";
  selectedStatus = "";

  columns = [
    { label: "Name", fieldName: "Name", type: "text" },
    { label: "Barcode", fieldName: "Barcode__c", type: "text" },
    { label: "Type", fieldName: "Type__c", type: "text" },
    { label: "Status", fieldName: "Status__c", type: "text" },
    { label: "Category", fieldName: "Category__c", type: "text" }
  ];

  typeOptions = [
    { label: "All Types", value: "" },
    { label: "Book", value: "Book" },
    { label: "AV Equipment", value: "AV Equipment" }
  ];

  statusOptions = [
    { label: "All Statuses", value: "" },
    { label: "Available", value: "Available" },
    { label: "Checked Out", value: "Checked Out" }
  ];

  // Wire the Apex method with refreshable cache
  @wire(getLibraryItems, {
    searchTerm: "$searchTerm",
    itemType: "$selectedType",
    status: "$selectedStatus"
  })
  wiredItems({ error, data }) {
    this.isLoading = true;
    if (data) {
      this.items = data;
      this.error = undefined;
    } else if (error) {
      this.error =
        error.message || "An error occurred while loading library items.";
      this.items = [];
    }
    this.isLoading = false;
  }

  // Event handlers
  handleSearchChange(event) {
    this.searchTerm = event.target.value;
  }

  handleTypeChange(event) {
    this.selectedType = event.detail.value;
  }

  handleStatusChange(event) {
    this.selectedStatus = event.detail.value;
  }

  // Computed property for no results state
  get noResults() {
    return !this.isLoading && this.items && this.items.length === 0;
  }

  // locally update UI with new status when book checked out or returned
  handleStatusUpdate = (event) => {
    const { barcode, newStatus } = event.detail;
    this.items = this.items.map((item) =>
      item.Barcode__c === barcode ? { ...item, Status__c: newStatus } : item
    );
  };

  connectedCallback() {
    window.addEventListener("statusupdate", this.handleStatusUpdate);
  }

  disconnectedCallback() {
    window.removeEventListener("statusupdate", this.handleStatusUpdate);
  }
}
