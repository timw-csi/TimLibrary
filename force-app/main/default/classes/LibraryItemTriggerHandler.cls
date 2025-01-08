public class LibraryItemTriggerHandler {
  public void beforeInsert(List<Library_Item__c> newItems) {
      // Ensure barcode present
      for (Library_Item__c item : newItems) {
          if (item.Barcode__c == null) {
              item.addError('Barcode is required.');
          }
      }
  }
}
