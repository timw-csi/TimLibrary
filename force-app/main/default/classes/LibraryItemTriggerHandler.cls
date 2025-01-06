public class LibraryItemTriggerHandler {
  public void beforeInsert(List<Library_Item__c> newItems) {
      // Ensure barcode uniqueness
      for (Library_Item__c item : newItems) {
          if (item.Barcode__c == null) {
              item.addError('Barcode is required.');
          }
      }
  }

  public void beforeUpdate(List<Library_Item__c> newItems, Map<Id, Library_Item__c> oldMap) {
      for (Library_Item__c item : newItems) {
          Library_Item__c oldItem = oldMap.get(item.Id);

          // Prevent status change to "Available" if item is checked out
          if (item.Status__c == 'Available' && oldItem.Status__c == 'Checked Out') {
              item.addError('Cannot set status to Available while item is checked out.');
          }
      }
  }

  public void afterUpdate(List<Library_Item__c> newItems, Map<Id, Library_Item__c> oldMap) {
      // Perform post-update logic, like logging or related record updates
  }
}
