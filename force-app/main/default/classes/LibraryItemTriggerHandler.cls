// This runs BEFORE a new library item is created
// It checks if the barcode field is filled in
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
