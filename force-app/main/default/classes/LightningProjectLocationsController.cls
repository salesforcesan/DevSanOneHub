public with sharing class LightningProjectLocationsController {
  private static Integer MAX_ROW_SIZE;
  static {
    MAX_ROW_SIZE = 100;
  }
@AuraEnabled
  public static void createJobs(Map<String,String> query){
    try{
      //todo call create job logic
    }
    catch(Exception ex){
        throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String,Object> getSettings(Map<String,String> query){
    try{
    Map<String,Object> result = new Map<String,Object>();
    String projectId = parseString(query.get('projectId'));
    
    if (String.isBlank(projectId)){
      throw new AuraHandledException('The project identifier and location identifiers are required.');
    }
    result.put('storeTypes', getStoreTypes());
    result.put('services',getServices(projectId));
    return result;
    }catch(Exception ex){
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  private static  List<Map<String,String>> getServices(String projectId){
    List<Map<String,String>> services = new List<Map<String,String>>();
    String[] names = new String[] {'Beer Test','Drug Test'};
    for(String name: names){
      Map<String,String> mapItem = new Map<String,String>();
      mapItem.put('id', name);
      mapItem.put('value', name);
      services.add(mapItem);
    }
    return services;

  }
  private static  List<Map<String,String>> getStoreTypes(){
    List<Map<String,String>> storeTypes = new List<Map<String,String>>();
    String[] names = new String[] {'Banner XYZ','24 Hrs Pharmacy'};
    for(String name: names){
      Map<String,String> mapItem = new Map<String,String>();
      mapItem.put('id', name);
      mapItem.put('value', name);
      storeTypes.add(mapItem);
    }
    return storeTypes;
  }
  @AuraEnabled
  public static void addLocations(Map<String,Object> query){
    try {
      List<Map<String,Object>> data = new List<Map<String,Object>>();
      String projectId = parseString(query.get('id'));
      List<String> locations = parseStringList(query.get('locations'));
      if (locations.size() > 0 && !String.isBlank(projectId)){
        addProjectLocations(projectId, locations);
        return;
      }
    }
    catch(Exception ex){
      throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
    }
    throw new AuraHandledException('The project identifier and location identifiers are required when adding locations.');
  }

  private static void addProjectLocations(String projectId, List<String>locations){
    List<ProjectLocation__c> recordSet= new List<ProjectLocation__c>();
    ProjectLocation__c projectLocation;
    Project__c project = [SELECT Id,Status__c FROM Project__c WHERE Id =:projectId];
    Boolean isNewLocation = CONSTANTS.PROJECT_STATUS_PLANNING.equalsIgnoreCase(project.Status__c)?false: true; 
    List<String> sql = new List<String>();
    sql.add('SELECT Id From Location__c WHERE IsActive__c=true');
    sql.add('AND Id In :locations');
    sql.add('AND Id Not In (Select Location__c FROM ProjectLocation__c Where Project__c=:projectId)');
    
    for(Location__c location: database.query(String.join(sql, ' '))){
      projectLocation = new ProjectLocation__c();
      projectLocation.Location__c = location.id;
      projectLocation.Project__c = projectId;
      projectLocation.IsNewLocation__c = isNewLocation;
      recordSet.add(projectLocation);
    }
    if (recordSet.size() > 0) {
      database.insert(recordset);
    }
  }

  @AuraEnabled
  public static void removeProjectLocations(Map<String,Object>query){
    try
    {
      String projectId = parseString(query.get('id'));
      List<String> locations = parseStringList(query.get('locations'));
      if (locations.isEmpty() || String.isBlank(projectId)){
        throw new AuraHandledException('The project identifier and locations\' identifiers are required.');
      }
      //todo remove project locations
    }
    catch(Exception ex)
    {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private static List<String> parseStringList(Object val){
    List<String> result = new List<String>();
    List<Object> values;
    if (null != val) {
      values = (List<Object>)val;
      for(Object obj: values){
        result.add(String.valueOf(obj));
      }
    }
    return result;
  }

  @AuraEnabled
  public static List<Map<String,Object>> searchKeyword(Map<String,String> query){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    String[] params = validateKeywordSearch(query);
    try{
      List<Location__c> locations = getLocationsByKeyword(params[0], params[1]);
      for(Location__c rec: locations){
        data.add(transformLocation(rec));
      }
      return data;
    }
    catch(Exception ex){
      throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
    }
  }

  private static String[] validateKeywordSearch(Map<String,String> query){
    String projectId = parseString(query.get('projectId'));
    String keyword = parseString(query.get('keyword'));
    if (String.isBlank(projectId)){
      throw new AuraHandledException('The project identifier is required when searching locations.');
    }
    return new String[] {projectId, keyword};
  }

  private static List<Location__c> getLocationsByKeyword(String projectId, String keyword){
    List<String> sql = genLocationSelectBaseSoql();
    if (!String.isBlank(keyword)){
      keyword = keyword + '%';
      sql.add('AND (LocationNumber__c Like :keyword OR Name Like :keyword)');
    }
    sql.add(' LIMIT ' + MAX_ROW_SIZE);
    return database.query(String.join(sql,' '));
  }

  private static Map<String,Object> transformLocation(Location__c location){
    Map<String,Object> rec = new Map<String,Object>();
    rec.put('id', location.Id);
    rec.put('num', location.LocationNumber__c);
    rec.put('name', location.Name);
    rec.put('postal', location.PostalCode__r != null ? location.PostalCode__r.Name : '');
    rec.put('city', location.City__c);
    rec.put('state', location.State__c);
    rec.put('type', location.Banner__c);
    return rec;
  }

  @AuraEnabled
  public static List<Map<String,Object>> searchProjectLoctionsByKeyword(Map<String,String>query){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    String[] params = validateKeywordSearch(query);
    try{
      List<ProjectLocation__c> projectLocations = getProjectLocationByKeyword(params[0], params[1]);
      for(ProjectLocation__c rec: projectLocations){
        data.add(transformProjectLocation(rec));
      }
      return data;
    }
    catch(Exception ex){
      throw new AuraHandledException(ex.getMessage() + ':' + ex.getStackTraceString());
    }
    
    return data;
  }

  private static List<ProjectLocation__c> getProjectLocationByKeyword(string projectId, string keyword){
    List<String> sql = new List<String>();

    return new List<ProjectLocation__c>();
  }

  private static Map<String,Object> transformProjectLocation(ProjectLocation__c c){
      Map<String,Object>item = new Map<String,Object>();
      /*
      item.put('id', 100 + i);
      item.put('name', names[remainder]);
      item.put('postal', 75020 + i);
      item.put('city', cities[remainder]);
      item.put('state',states[remainder]);
      item.put('workers',remainder + 1);
      item.put('hours', remainder + 1);
      item.put('type',storeTypes[remainder]);
      item.put('address', (100+i) + ' ' + addresses[remainder]);
      item.put('schedule',baseDate.addDays(i));
      item.put('execution',executions[math.mod(i,3)]);
      item.put('company',companies[remainder]);
      */
      return item;
  }

  @AuraEnabled
  public static List<Map<String,Object>> filterLocations(Map<String,String> query){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    String city = parseString(query.get('city'));

    return data;
  }

  private static List<Location__c> getLocationsByFilter(Map<String,String>query){
    List<String> sql = genLocationSelectBaseSoql();
    String projectId = parseString(query.get('projectId'));
    return database.query(String.join(sql,' '));
  }

  private static List<String> genLocationSelectBaseSoql(){
    List<String> sql = new List<String>();
    sql.add('SELECT Id, LocationNumber__c, Name, Address__c, City__c, State__c, PostalCode__r.Name, Banner__c FROM Location__c');
    sql.add('WHERE IsActive__c=true');
    sql.add('AND Id Not In (SELECT Location__c FROM ProjectLocation__c WHERE Project__c=:projectId)');
    return sql;
  }

  @AuraEnabled
  public static List<Map<String,Object>> filterProjectLocations(Map<String,String> query){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    List<Map<String,Object>> results = getProjectLocationTestData();
    String city = parseString(query.get('city')),
      state = parseString(query.get('state')),
      postal = parseString(query.get('postal'));
      for(Map<String,Object> rec: results){
        if (String.valueOf(rec.get('city')).containsIgnoreCase(city)){
          data.add(rec);
        }
    }
    return data;
  }

  private static String parseString(object val){
    return val != null ? String.valueOf(val): '';
  }

  /* demo API */
  private static String[] names {get;set;}
  private static String[] cities {get;set;}
  private static String[] states {get;set;}
  private static String[] storeTypes {get;set;}
  private static String[] addresses {get;set;}
  private static Integer[] executions{get;set;}
  private static String[] companies {get;set;}

  static {
    names = new String[] {
      'Walmart',
      'Walmart SuperCenter',
      'Walgreen',
      'LoneStar Drugstore'
    };
    cities = new String[] {
      'Dallas',
      'Plano',
      'Frisco',
      'Irving'
    };
    storeTypes = new String[] {'24 Hr Pharmacy','Drugstore','Foot&Wear','Food Store'};
    states = new String[] {'TX','CA','OH','NY'};
    addresses = new String[] {
      'main st.','monroe ave.','LaGrange Blvd','Palor St'
    };
    executions = new Integer[]{-1,0,1,0};
    companies = new String[]{
      'Walmart Inc',
      'Soloman Tech Inc',
      'American Airline Inc',
      'User'
    };
  }
  private static List<Map<String,Object>> getLocationTestData(){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    Map<String,Object> item;
    Integer remainder;
    for(Integer i=0; i < 200; i++){
      remainder = math.mod(i,4);
      item = new Map<String,Object>();
      item.put('id', (100 + i) + '');
      item.put('name', names[remainder]);
      item.put('postal', 75020 + i);
      item.put('city', cities[remainder]);
      item.put('state',states[remainder]);
      item.put('type',storeTypes[remainder]);
      data.add(item);
    }
    return data;
  }

    private static List<Map<String,Object>> getProjectLocationTestData(){
    List<Map<String,Object>> data = new List<Map<String,Object>>();
    Map<String,Object> item;
    Integer remainder;
    Date baseDate = Date.newInstance(2017,1,1);

    for(Integer i=0; i < 200; i++){
      remainder = math.mod(i,4);
      item = new Map<String,Object>();
      item.put('id', 100 + i);
      item.put('name', names[remainder]);
      item.put('postal', 75020 + i);
      item.put('city', cities[remainder]);
      item.put('state',states[remainder]);
      item.put('workers',remainder + 1);
      item.put('hours', remainder + 1);
      item.put('type',storeTypes[remainder]);
      item.put('address', (100+i) + ' ' + addresses[remainder]);
      item.put('schedule',baseDate.addDays(i));
      item.put('execution',executions[math.mod(i,3)]);
      item.put('company',companies[remainder]);
      data.add(item);
    }
    return data;
  }
}