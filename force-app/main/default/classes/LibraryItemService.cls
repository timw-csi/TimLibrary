public with sharing class LibraryItemService {
  private static final Integer BORROWING_LIMIT = 5;
  
  // Bulkified version that handles multiple checkouts at once
  public void checkoutItems(List<String> barcodes, Id userId) {
      // Query all items at once
      Map<String, Library_Item__c> itemsByBarcode = new Map<String, Library_Item__c>();
      for (Library_Item__c item : [
        SELECT Id, Status__c, Barcode__c 
        FROM Library_Item__c 
        WHERE Barcode__c IN :barcodes]) {
          itemsByBarcode.put(item.Barcode__c, item);
      }
      
      // Check borrowing limit once
      Integer currentBorrowings = [
        SELECT COUNT() 
        FROM Borrowing_Record__c 
        WHERE Borrower__c = :userId 
        AND Status__c = 'Active'];
      
      if (currentBorrowings + barcodes.size() > BORROWING_LIMIT) {
          throw new CustomException('This checkout would exceed the borrowing limit.');
      }
      
      // Create all borrowing records at once
      List<Borrowing_Record__c> recordsToInsert = new List<Borrowing_Record__c>();
      List<Library_Item__c> itemsToUpdate = new List<Library_Item__c>();
      
      for (String barcode : barcodes) {
          Library_Item__c item = itemsByBarcode.get(barcode);
          if (item == null) {
              throw new CustomException('Item with barcode ' + barcode + ' not found.');
          }
          if (item.Status__c != 'Available') {
              throw new CustomException('Item ' + barcode + ' is not available for checkout.');
          }
          
          recordsToInsert.add(new Borrowing_Record__c(
              Library_Item__c = item.Id,
              Borrower__c = userId,
              Checkout_Date__c = System.now(),
              Due_Date__c = System.now().addDays(14),
              Status__c = 'Active'
          ));
          
          itemsToUpdate.add(new Library_Item__c(
              Id = item.Id,
              Status__c = 'Checked Out'
          ));
      }
      
      // Perform DML operations in bulk
      if (!recordsToInsert.isEmpty()) {
          insert recordsToInsert;
          update itemsToUpdate;
      }
  }
  
  // Bulkified version for returns
  public void returnItems(List<String> barcodes) {
      // Query all items at once
      Map<Id, Library_Item__c> itemsById = new Map<Id, Library_Item__c>();
      Map<String, Library_Item__c> itemsByBarcode = new Map<String, Library_Item__c>();
      
      for (Library_Item__c item : [
        SELECT Id, Status__c, Barcode__c 
        FROM Library_Item__c 
        WHERE Barcode__c IN :barcodes]) {
          itemsById.put(item.Id, item);
          itemsByBarcode.put(item.Barcode__c, item);
      }
      
      // Query all active borrowing records for these items at once
      Map<Id, Borrowing_Record__c> activeRecords = new Map<Id, Borrowing_Record__c>(
        [SELECT Id, Status__c, Library_Item__c 
        FROM Borrowing_Record__c 
        WHERE Library_Item__c IN :itemsById.keySet() 
        AND Status__c = 'Active']
      );
      
      List<Borrowing_Record__c> recordsToUpdate = new List<Borrowing_Record__c>();
      List<Library_Item__c> itemsToUpdate = new List<Library_Item__c>();
      
      for (String barcode : barcodes) {
          Library_Item__c item = itemsByBarcode.get(barcode);
          if (item == null) {
              throw new CustomException('Item with barcode ' + barcode + ' not found.');
          }
          
          Borrowing_Record__c record = activeRecords.get(item.Id);
          if (record == null) {
              throw new CustomException('No active borrowing record found for item ' + barcode);
          }
          
          record.Status__c = 'Returned';
          record.Return_Date__c = System.now();
          recordsToUpdate.add(record);
          
          itemsToUpdate.add(new Library_Item__c(
              Id = item.Id,
              Status__c = 'Available'
          ));
      }
      
      // Perform DML operations in bulk
      if (!recordsToUpdate.isEmpty()) {
          update recordsToUpdate;
          update itemsToUpdate;
      }
  }
  
  // Single-item methods that use the bulkified methods internally
  public void checkoutItem(String barcode, Id userId) {
      checkoutItems(new List<String>{barcode}, userId);
  }
  
  public void returnItem(String barcode) {
      returnItems(new List<String>{barcode});
  }
}