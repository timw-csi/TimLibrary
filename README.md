# Library Management System - Technical Design Document

## Data Model

### Custom Objects

1. `Library_Item__c`

   - Fields:
     - Name (Text)
     - Barcode\_\_c (Text, External ID)
     - Type\_\_c (Picklist: Book, AV Equipment)
     - Status\_\_c (Picklist: Available, Checked Out)
     - Category\_\_c (Picklist: Fiction, Non-Fiction, Reference, Projector, Camera)
     - Description\_\_c (Rich Text)

2. `Borrowing_Record__c`

   - Fields:
     - Name (Auto Number: BR-{0000})
     - Library_Item**c (Master-Detail to Library_Item**c)
     - Borrower\_\_c (Lookup to Library_Member\_\_c)
     - Checkout_Date\_\_c (DateTime)
     - Due_Date\_\_c (DateTime)
     - Return_Date\_\_c (DateTime)
     - Status\_\_c (Picklist: Active, Returned, Overdue)

3. `Library_Member__c`
   - Fields:
     - Employee_Number\_\_c
     - User\_\_c (Lookup to User object)

## Apex Classes

### Core Classes

1. `LibraryItemService`

   - Methods:
     - `processCheckouts(List<String> barcodes, Id userId)`
     - `processReturns(List<String> barcodes)`

2. `LibraryItemTriggerHandler`

   - Methods:
     - `beforeInsert(List<Library_Item__c> newItems)`

3. `LibraryItemBrowser`

- Methods:
  - ` getLibraryItems(String searchTerm, String itemType, String status)`

<!--
STUB to be implemented
### Batch Classes

1. `OverdueBorrowingsBatch`
   - Processes overdue items and sends reminders
   - Scheduled to run daily
-->

### Test Classes

1. `LibraryItemServiceTest`

### JS Unit Tests

1. `libraryCheckout.test.js`
2. `libraryItemBrowser.test.js`

## Lightning Components

1. `libraryCheckout`

   - Quick checkout interface for barcode scanning
   - Features:
     - Barcode input field with auto-focus
     - Real-time status updates
     - Error handling display

2. `libraryItemBrowser`

   - Searchable/filterable list of library items
   - Features:
     - Advanced search capabilities
     - Filter by type, status, category

<!-- STUB to be implemented
### Main Components

 1. `borrowerDashboard`
   - Personal dashboard for users
   - Features:
     - Currently borrowed items
     - Borrowing history
     - Overdue notifications -->

### Triggers

1. Library Item Trigger

   - Ensures barcode present for new items

<!-- STUB to be implemented

### Workflows

1. Overdue Item Notification
   - Sends email alerts for overdue items
   - Updates record status


## Reports & Dashboards

### Reports

1. Current Borrowings
2. Overdue Items
3. Popular Items
4. Frequent Borrowers
5. Item Availability


### Dashboard

1. Library Operations Dashboard
   - Current vs. Historical checkouts
   - Item type distribution
   - Overdue items tracking
   - Popular items chart -->

## Testing Strategy

1. Unit Tests

   - Cover main business logic in LibraryItemService class
   - Cover checkout and browser lwc's

<!-- ## Deployment Plan

1. Phase 1: Data Model

   - Custom objects
   - Fields
   - Relationships

2. Phase 2: Backend Logic

   - Apex classes
   - Triggers
   - Test classes

3. Phase 3: Frontend
   - Lightning components
   - Page layouts
   - Reports and dashboards -->
