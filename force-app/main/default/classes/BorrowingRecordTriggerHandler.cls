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
}
