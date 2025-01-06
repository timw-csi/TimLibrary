public with sharing class LibraryItemService {
  public static void checkoutItem(String barcode, Id userId) {
      Library_Item__c item = [SELECT Id, Status__c FROM Library_Item__c WHERE Barcode__c = :barcode LIMIT 1];
      if (item.Status__c != 'Available') {
          throw new CustomException('Item is not available for checkout.');
      }

      Borrowing_Record__c record = new Borrowing_Record__c(
          Library_Item__c = item.Id,
          Borrower__c = userId,
          Checkout_Date__c = System.now(),
          Due_Date__c = System.now().addDays(14), // Assuming 2-week borrowing period
          Status__c = 'Active'
      );
      insert record;

      item.Status__c = 'Checked Out';
      update item;
  }

  public static void returnItem(String barcode) {
      Library_Item__c item = [SELECT Id, Status__c FROM Library_Item__c WHERE Barcode__c = :barcode LIMIT 1];
      if (item.Status__c != 'Checked Out') {
          throw new CustomException('Item is not currently checked out.');
      }

      Borrowing_Record__c record = [
        SELECT Id, Status__c 
        FROM Borrowing_Record__c 
        WHERE Library_Item__c = :item.Id AND Status__c = 'Active' LIMIT 1];
      record.Status__c = 'Returned';
      record.Return_Date__c = System.now();
      update record;

      item.Status__c = 'Available';
      update item;
  }

  public static Library_Item__c getItemDetails(String barcode) {
      return [SELECT Id, Name, Status__c, Type__c FROM Library_Item__c WHERE Barcode__c = :barcode LIMIT 1];
  }

  public static void validateCheckout(String barcode, Id userId) {
      Integer borrowLimit = 5; // Example borrowing limit
      Integer currentBorrowed = [SELECT COUNT() FROM Borrowing_Record__c WHERE Borrower__c = :userId AND Status__c = 'Active'];

      if (currentBorrowed >= borrowLimit) {
          throw new CustomException('Borrowing limit reached.');
      }

      Library_Item__c item = [SELECT Id, Status__c FROM Library_Item__c WHERE Barcode__c = :barcode LIMIT 1];
      if (item.Status__c != 'Available') {
          throw new CustomException('Item is not available for checkout.');
      }
  }
}
