/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LibraryItemServiceTest {
   // Set up test data that will be used by multiple tests
   @TestSetup
   static void setupTestData() {
       // Create a test user
       User testUser = new User(
           ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
           LastName = 'TestUser',
           Email = 'test@test.com',
           Username = 'test@test.com' + System.currentTimeMillis(),
           CompanyName = 'TEST',
           Title = 'title',
           Alias = 'alias',
           TimeZoneSidKey = 'America/Los_Angeles',
           EmailEncodingKey = 'UTF-8',
           LanguageLocaleKey = 'en_US',
           LocaleSidKey = 'en_US'
       );
       insert testUser;

       // Create a Library Member linked to the test user
       Library_Member__c member = new Library_Member__c(
           User__c = testUser.Id,
           Employee_Number__c = 'EMP123'
       );
       insert member;

       // Create some test Library Items
       List<Library_Item__c> items = new List<Library_Item__c>();
       for(Integer i = 1; i <= 5; i++) {
           items.add(new Library_Item__c(
               Name = 'Test Book ' + i,
               Barcode__c = 'TEST' + i,
               Status__c = 'Available',
               Type__c = 'Book'
           ));
       }
       insert items;
   }

   @isTest
   static void testSuccessfulCheckout() {
       // Get test data
       Library_Item__c item = [SELECT Id, Barcode__c FROM Library_Item__c WHERE Barcode__c = 'TEST1' LIMIT 1];
       User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];

       // Run test as the test user
       System.runAs(testUser) {
           Test.startTest();
           
           try {
               LibraryItemService.processCheckouts(new List<String>{item.Barcode__c});
               
               // Verify item status was updated
               Library_Item__c updatedItem = [SELECT Status__c FROM Library_Item__c WHERE Id = :item.Id];
               System.assertEquals('Checked Out', updatedItem.Status__c, 'Item should be checked out');
               
               // Verify borrowing record was created
               Borrowing_Record__c record = [
                   SELECT Status__c 
                   FROM Borrowing_Record__c 
                   WHERE Library_Item__c = :item.Id
               ];
               System.assertEquals('Active', record.Status__c, 'Borrowing record should be active');
           } catch(Exception e) {
               System.assert(false, 'No exception should be thrown: ' + e.getMessage());
           }

           Test.stopTest();
       }
   }

   @isTest
   static void testBorrowingLimitExceeded() {
       // Get test user
       User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
       
       System.runAs(testUser) {
           Test.startTest();
           
           // Try to check out 4 items (over the limit of 3)
           List<String> barcodes = new List<String>{'TEST1', 'TEST2', 'TEST3', 'TEST4'};
           
           try {
               LibraryItemService.processCheckouts(barcodes);
               System.assert(false, 'Should have thrown an exception');
           } catch(AuraHandledException e) {
               System.assert(true, 'Expected exception was thrown');
            
               // Optionally verify no records were created
               List<Borrowing_Record__c> records = [SELECT Id FROM Borrowing_Record__c];
               System.assertEquals(0, records.size(), 'No borrowing records should be created');
           }

           Test.stopTest();
       }
   }

   @isTest
   static void testSuccessfulReturn() {
       // Get test data
       Library_Item__c item = [SELECT Id, Barcode__c FROM Library_Item__c WHERE Barcode__c = 'TEST1' LIMIT 1];
       User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];

       System.runAs(testUser) {
           // First check out the item
           LibraryItemService.processCheckouts(new List<String>{item.Barcode__c});
           
           Test.startTest();
           
           try {
               LibraryItemService.processReturn(item.Barcode__c);
               
               // Verify item status was updated
               Library_Item__c updatedItem = [SELECT Status__c FROM Library_Item__c WHERE Id = :item.Id];
               System.assertEquals('Available', updatedItem.Status__c, 'Item should be available');
               
               // Verify borrowing record was updated
               Borrowing_Record__c record = [
                   SELECT Status__c 
                   FROM Borrowing_Record__c 
                   WHERE Library_Item__c = :item.Id
               ];
               System.assertEquals('Returned', record.Status__c, 'Borrowing record should be returned');
           } catch(Exception e) {
               System.assert(false, 'No exception should be thrown: ' + e.getMessage());
           }

           Test.stopTest();
       }
   }

   @isTest
   static void testReturnNonExistentItem() {
       User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];

       System.runAs(testUser) {
           Test.startTest();
           
           try {
               LibraryItemService.processReturn('NONEXISTENT');
               System.assert(false, 'Should have thrown an exception');
           } catch(AuraHandledException e) {
               System.assert(e.getMessage().contains('not found'), 
                   'Should throw appropriate error message');
           }

           Test.stopTest();
       }
   }
}