trigger LibraryItemTrigger on Library_Item__c (before insert, before update, after update) {
  // Delegate the logic to the trigger handler
  LibraryItemTriggerHandler handler = new LibraryItemTriggerHandler();

  if (Trigger.isBefore) {
      if (Trigger.isInsert) {
          handler.beforeInsert(Trigger.new);
      } else if (Trigger.isUpdate) {
          handler.beforeUpdate(Trigger.new, Trigger.oldMap);
      }
  } else if (Trigger.isAfter) {
      if (Trigger.isUpdate) {
          handler.afterUpdate(Trigger.new, Trigger.oldMap);
      }
  }
}
