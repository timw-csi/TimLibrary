public with sharing class LibraryItemBrowser {
  @AuraEnabled(cacheable=true)
  public static List<Library_Item__c> getLibraryItems(
      String searchTerm,
      String itemType,
      String status
  ) {
      String query = 'SELECT Id, Name, Barcode__c, Type__c, Status__c, Category__c ' +
                    'FROM Library_Item__c WHERE Id != null';
      
      List<String> conditions = new List<String>();
      
      // Add search term condition
      if (String.isNotBlank(searchTerm)) {
          conditions.add('(Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' OR ' +
                       'Barcode__c LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\')');
      }
      
      // Add type filter
      if (String.isNotBlank(itemType)) {
          conditions.add('Type__c = \'' + String.escapeSingleQuotes(itemType) + '\'');
      }
      
      // Add status filter
      if (String.isNotBlank(status)) {
          conditions.add('Status__c = \'' + String.escapeSingleQuotes(status) + '\'');
      }
      
      // Add conditions to query
      if (!conditions.isEmpty()) {
          query += ' AND ' + String.join(conditions, ' AND ');
      }
      
      // Add order by
      query += ' ORDER BY Name LIMIT 1000';
      
      return Database.query(query);
  }
}