trigger BorrowingRecordTrigger on Borrowing_Record__c (before insert, after insert, after update) {
  BorrowingRecordTriggerHandler handler = new BorrowingRecordTriggerHandler();

  if (Trigger.isBefore) {
      if (Trigger.isInsert) {
          handler.beforeInsert(Trigger.new);
      }
  } else if (Trigger.isAfter) {
      if (Trigger.isInsert) {
          handler.afterInsert(Trigger.new);
      } else if (Trigger.isUpdate) {
          handler.afterUpdate(Trigger.new, Trigger.oldMap);
      }
  }
}
