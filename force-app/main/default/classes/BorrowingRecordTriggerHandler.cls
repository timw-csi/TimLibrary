public class BorrowingRecordTriggerHandler {
  public void beforeInsert(List<Borrowing_Record__c> newRecords) {
    // Collect all Library Item IDs from the borrowing records
    Set<Id> libraryItemIds = new Set<Id>();
    
    for (Borrowing_Record__c borrowingRecord : newRecords) {
      libraryItemIds.add(borrowingRecord.Library_Item__c);
    }
    // Query Library Items to check their status. bulkify SOQL query best practice
    Map<Id, Library_Item__c> libraryItems = new Map<Id, Library_Item__c>(
      [SELECT Id, Status__c 
      FROM Library_Item__c 
      WHERE Id IN :libraryItemIds]
    );
    // Validate each borrowing record
    for (Borrowing_Record__c borrowingRecord : newRecords) {
      Library_Item__c libraryItem = libraryItems.get(borrowingRecord.Library_Item__c);
      if (libraryItem.Status__c != 'Available') {
          borrowingRecord.addError('Item is not available for checkout.');
      }
    }
  }

  public void afterInsert(List<Borrowing_Record__c> newRecords) {
    // Update item status to "Checked Out" after successful checkout
    List<Library_Item__c> itemsToUpdate = new List<Library_Item__c>();
    
    for (Borrowing_Record__c record : newRecords) {
        Library_Item__c item = new Library_Item__c(Id = record.Library_Item__c, Status__c = 'Checked Out');
        itemsToUpdate.add(item);
    }
    update itemsToUpdate;
  }

  public void afterUpdate(List<Borrowing_Record__c> newRecords, Map<Id, Borrowing_Record__c> oldMap) {
    // Update item status to Available after successful return
    List<Library_Item__c> itemsToUpdate = new List<Library_Item__c>();
    
    for (Borrowing_Record__c record : newRecords) {
      Borrowing_Record__c oldRecord = oldMap.get(record.Id);
      if (record.Status__c == 'Returned' && oldRecord.Status__c != 'Returned') {
        Library_Item__c item = new Library_Item__c(Id = record.Library_Item__c, Status__c = 'Available');
          itemsToUpdate.add(item);
      }
    }
    update itemsToUpdate;
  }
}
