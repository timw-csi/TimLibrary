trigger LibraryItemTrigger on Library_Item__c (before insert) {
  // Delegate the logic to the trigger handler
  LibraryItemTriggerHandler handler = new LibraryItemTriggerHandler();

  if (Trigger.isBefore) {
      if (Trigger.isInsert) {
          handler.beforeInsert(Trigger.new);
      }
  }    
}