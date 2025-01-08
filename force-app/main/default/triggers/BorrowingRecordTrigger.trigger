trigger BorrowingRecordTrigger on Borrowing_Record__c (before insert) {
  BorrowingRecordTriggerHandler handler = new BorrowingRecordTriggerHandler();

  if (Trigger.isBefore) {
      if (Trigger.isInsert) {
          handler.beforeInsert(Trigger.new);
      }
  } 
}
