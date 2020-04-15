public without sharing class Locations extends LightningRequestBase {
  static Integer MAX_ROW_SIZE;
  public static String ACTION_UPLOADFILE;

  static {
    MAX_ROW_SIZE = 9500;
    ACTION_UPLOADFILE = 'uploadFile';
  }

  //api: search
  public override Object search(Object parameters) {
    Map<String, object> query = (Map<String, object>) parameters;
    String action = LightningRequestHelper.getRequestAction(query);
    String projectId = LightningRequestHelper.parseString(query.get('projectId'));
    String keyword = LightningRequestHelper.parseString(query.get('keyword'));

    if (String.isBlank(projectId)) {
      throw new AuraHandledException('The project identifier is required when searching locations.');
    }

    Project__c project = getProject(projectId);

    if (action == ACTION_UPLOADFILE) {
      List<String> locations = LightningRequestHelper.parseArrayOfString(query.get('locations'));
      Boolean useGuid = LightningRequestHelper.parseString(query.get('useGuid')) == '1';
      return handleFileUpload(project, locations, useGuid);
    }

    Map<String, Object> response = new Map<String, Object>();
    List<Map<String, Object>> data = new List<Map<String, Object>>();
    List<Location__c> locations = getLocationsByKeyword(project, keyword);
    for (Location__c rec : locations) {
      data.add(transformLocation(rec));
    }
    return data;
  }

  static Integer countExistedProjectLocations(String projectId) {
    AggregateResult[] results = [SELECT count(id) cnt FROM ProjectLocation__c WHERE Project__c = :projectId];
    return Integer.valueOf(results[0].get('cnt'));
  }

  Map<String, Object> handleFileUpload(Project__c project, List<String> idSet, Boolean useGuid) {
    Map<String, Object> result = new Map<String, Object>();
    //step 1: if no data to upload, error out
    if (idSet.size() == 0) {
      throw new AuraHandledException('No locations to upload.');
    }

    LocationUploadPasteAnalyzer analyzer = new LocationUploadPasteAnalyzer(idSet, useGuid);
    Map<String, List<Map<String, Object>>> data = analyzer.getData(project.Id, project.Retailer__c, project.RetailerAccount__c);
    result.put(LocationUploadPasteAnalyzer.LocationsKey, data.get(LocationUploadPasteAnalyzer.LocationsKey));
    result.put(LocationUploadPasteAnalyzer.ExclusionsKey, data.get(LocationUploadPasteAnalyzer.ExclusionsKey));

    return result;
  }

  private static List<Location__c> getLocationsByKeyword(Project__c project, String keyword) {
    String projectId = project.Id;
    List<String> sql = genLocationSelectBaseSoql();
    if (String.isNotBlank(keyword)) {
      keyword = keyword + '%';
      sql.add('AND (OneHubLocationId__c Like :keyword OR Name Like :keyword)');
    }

    String retailerId = project.Retailer__c;
    if (String.isNotBlank(retailerId)) {
      sql.add('AND Retailer__c = :retailerId');
    }

    String retailerAccountId = project.RetailerAccount__c;
    if (String.isNotBlank(retailerAccountId)) {
      sql.add('AND RetailerAccount__c = :retailerAccountId');
    }

    Integer count = MAX_ROW_SIZE - countExistedProjectLocations(project.Id);
    sql.add('LIMIT ' + count);
    return database.query(String.join(sql, ' '));
  }

  private static Map<String, Object> transformLocation(Location__c location) {
    Map<String, Object> rec = new Map<String, Object>();
    rec.put('id', location.Id);
    rec.put('uid', location.OneHubLocationID__c);
    rec.put('num', location.LocationNumber__c);
    rec.put('name', location.Name);
    rec.put('postal', location.PostalCode__r != null ? location.PostalCode__r.Name : '');
    rec.put('city', location.City__c);
    rec.put('state', location.State__c);
    rec.put('type', location.Parent__r != null ? location.Parent__r.Name : '');
    return rec;
  }

  private static List<String> genLocationSelectBaseSoql() {
    List<String> sql = new List<String>();
    sql.add('SELECT Id, LocationNumber__c, OneHubLocationID__c, Name, Address__c, City__c, State__c, PostalCode__r.Name, Parent__r.Name FROM Location__c');
    sql.add('WHERE IsActive__c=true AND Type__c=\'Location\'');
    sql.add('AND OneHubLocationID__c <> null');
    sql.add('AND Id Not In (SELECT Location__c FROM ProjectLocation__c WHERE Project__c=:projectId AND Status__c != \'Canceled\')');
    return sql;
  }

  //api: filter
  public override Object filter(Object parameters) {
    Map<String, object> query = (Map<String, object>) parameters;
    String projectId = LightningRequestHelper.parseString(query.get('projectId'));

    if (String.isBlank(projectId)) {
      throw new AuraHandledException('The project identifier is required when filtering locations.');
    }

    Project__c project = getProject(projectId);

    String keyword = LightningRequestHelper.parseString(query.get('keyword'));
    String city = LightningRequestHelper.parseString(query.get('city'));
    String state = LightningRequestHelper.parseString(query.get('state'));
    String postal = LightningRequestHelper.parseString(query.get('postal'));
    String storeType = LightningRequestHelper.parseString(query.get('type'));

    Map<String, Object> response = new Map<String, Object>();
    List<Map<String, Object>> data = new List<Map<String, Object>>();
    List<Location__c> locations = getLocationsByFilter(project,keyword, city, state, postal, storeType);
    for (Location__c rec : locations) {
      data.add(transformLocation(rec));
    }
    return data;
  }
  static List<Location__c> getLocationsByFilter(Project__c project,  String keyword, String city, String state, String postal, String storeType) {
    Integer count = MAX_ROW_SIZE - countExistedProjectLocations(project.Id);
    if (count == 0) {
      throw new AuraHandledException('The maximum of 9500 Locations has been reached.');
    }
    String projectId = project.Id;
    List<String> sql = genLocationSelectBaseSoql();
    
    String retailerId = project.Retailer__c;
    if (String.isNotBlank(retailerId)) {
      sql.add('AND Retailer__c = :retailerId');
    }

    String retailerAccountId = project.RetailerAccount__c;
    if (String.isNotBlank(retailerAccountId)) {
      sql.add('AND RetailerAccount__c = :retailerAccountId');
    }

    if (!String.isBlank(keyword)) {
      keyword = keyword + '%';
      sql.add('AND (LocationNumber__c Like :keyword OR Name Like :keyword)');
    }
    if (!String.isBlank(city)) {
      city = city + '%';
      sql.add('AND City__c like :city');
    }
    if (!String.isBlank(city)) {
      city = city + '%';
      sql.add('AND City__c like :city');
    }
    if (!String.isBlank(state)) {
      state = state + '%';
      sql.add('AND State__c like :state');
    }
    if (!String.isBlank(postal)) {
      postal = postal + '%';
      sql.add('AND PostalCode__r.Name like :postal');
    }
    if (!String.isBlank(storeType)) {
      storeType = storeType + '%';
      sql.add('AND Parent__r.Name LIKE :storeType');
    }

    sql.add('LIMIT ' + count);
    return database.query(String.join(sql, ' '));
  }

  static Project__c getProject(String projectId) {
    List<Project__c> pList = [SELECT Id, Retailer__c, RetailerAccount__c FROM Project__c WHERE Id = :projectId];
    if (pList.isEmpty()) {
      throw new AuraHandledException('The project is not found.');
    }

    return pList[0];
  }
}