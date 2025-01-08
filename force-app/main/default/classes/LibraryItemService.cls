public with sharing class LibraryItemService {
  private static final Integer BORROWING_LIMIT = 3;
  
  @AuraEnabled(cacheable=false)
  public static void processCheckouts(List<String> barcodes) {
      try {
          // Get the Library Member ID for this user using the User__c field
          Library_Member__c member = [
            SELECT Id, Employee_Number__c 
            FROM Library_Member__c 
            WHERE User__c = :UserInfo.getUserId()
            LIMIT 1];
            
        if (member == null) {
            throw new AuraHandledException('No Library Member record found for this user. Please ensure you have a Library Member record.');
        }
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
              WHERE Borrower__c = :member.Id 
              AND Status__c = 'Active'];
          
          if (currentBorrowings + barcodes.size() > BORROWING_LIMIT) {
            String errorMsg = 'This checkout would exceed the borrowing limit of ' + BORROWING_LIMIT + ' items.';
            AuraHandledException e = new AuraHandledException(errorMsg);
            e.setMessage(errorMsg);
            throw e;
          }
          
          // Create all borrowing records at once
          List<Borrowing_Record__c> recordsToInsert = new List<Borrowing_Record__c>();
          List<Library_Item__c> itemsToUpdate = new List<Library_Item__c>();
          
          for (String barcode : barcodes) {
              Library_Item__c item = itemsByBarcode.get(barcode);
              if (item == null) {
                String errorMsg = 'Item with barcode ' + barcode + ' not found.';
                AuraHandledException e = new AuraHandledException(errorMsg);
                e.setMessage(errorMsg);
                throw e;
              }
              if (item.Status__c != 'Available') {
                String errorMsg = 'Item ' + barcode + ' is not available for checkout.';
                AuraHandledException e = new AuraHandledException(errorMsg);
                e.setMessage(errorMsg);
                throw e;
              }
              
              recordsToInsert.add(new Borrowing_Record__c(
                  Library_Item__c = item.Id,
                  Borrower__c = member.Id,
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
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  }
  
  @AuraEnabled(cacheable=false)
public static void processReturn(String barcode) {
    try {
        // Get the Library Member for current user
        Library_Member__c member = [
            SELECT Id 
            FROM Library_Member__c 
            WHERE User__c = :UserInfo.getUserId() 
            LIMIT 1
        ];
        
        // Find the library item
        Library_Item__c item = [
            SELECT Id, Status__c 
            FROM Library_Item__c 
            WHERE Barcode__c = :barcode
            LIMIT 1
        ];
        
        // Find active borrowing record
        Borrowing_Record__c record = [
            SELECT Id, Status__c
            FROM Borrowing_Record__c
            WHERE Library_Item__c = :item.Id
            AND Borrower__c = :member.Id
            AND Status__c = 'Active'
            LIMIT 1
        ];
        
        // Update the borrowing record
        record.Status__c = 'Returned';
        record.Return_Date__c = System.now();
        update record;
        
        // Update the item status
        item.Status__c = 'Available';
        update item;
        
    } catch (QueryException e) {
        String errorMsg = 'Item with barcode ' + barcode + ' either not found or was checked out by another user.';
        AuraHandledException err = new AuraHandledException(errorMsg);
        err.setMessage(errorMsg);
        throw err;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
  }
}