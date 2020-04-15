public without sharing class LocationUploadPasteAnalyzer {
  private static final integer USE_LOCATION_NUMBER = 1;
  private static final integer USE_LOCATION_GUID = 2;
  private static final integer USE_LOCATION_UNDEFINED = 0;

  public List<String> guids {get; private set;}
  public List<String> numbers {get; private set;}
  public List<String> errors {get; set;}

  //used with org custom setting to determine how dup is checked.
  private boolean retailerAccountAssigned {get; set;}
  private Integer overrideUseGuid;

  public static string LocationsKey = 'locations';
  public static string ExclusionsKey = 'exclusions';
  private static string baseSQL;
  private static boolean useLocationNubmerBySetting;

  static {
    baseSQL = 'SELECT Id, LocationNumber__c, Name, OneHubLocationID__c FROM Location__c WHERE IsActive__c=true AND Type__c=\'Location\'';
    useLocationNubmerBySetting = AppUtil.LocationSearchField == 'OneHubLocationId__c'
                                 ? false
                                 : true;
  }

  public LocationUploadPasteAnalyzer(List<String> idSet) {
    this.retailerAccountAssigned = false;
    this.overrideuseGuid = USE_LOCATION_UNDEFINED;
    this.guids = new List<String>();
    this.numbers = new List<String>();
    this.errors = new List<String>();
    this.splitDataset(idSet);
  }

  public LocationUploadPasteAnalyzer(List<String> idSet, Boolean useGuid) {
    this.retailerAccountAssigned = false;
    this.guids = new List<String>();
    this.numbers = new List<String>();
    this.errors = new List<String>();
    if (useGuid) {
      this.overrideUseGuid = USE_LOCATION_GUID;
      this.guids.addAll(idSet);
    } else {
      this.overrideUseGuid = USE_LOCATION_NUMBER;
      this.numbers.addAll(idSet);
    }
  }

  private void logError(String msg) {
    this.errors.add(msg);
  }

  private void splitDataset(List<String>idSet) {
    for (String someId : idSet) {
      if (LightningRequestHelper.isOneHubLocationId(someId)) {
        this.guids.add(someId);
      } else {
        this.numbers.add(someId);
      }
    }
  }

  public Boolean hasError() {
    return this.errors.size() > 0;
  }

  public static Map<String, String> toIdUidMap(Map<String, Location__c> uidLocationMap) {
    Map<String, String> idMap = new Map<String, String>();
    for (String key : uidLocationMap.keySet()) {
      idMap.put(uidLocationMap.get(key).Id, key);
    }
    return idMap;
  }

  public static Map<String, Location__c> dedupUidLocationMap(Map<String, Location__c> uidLocationMap) {
    Map<String, Location__c> result = new Map<String, Location__c>();
    List<Map<String, Object>> dataSet = toMapList(uidLocationMap.values());
    Set<String> dupSet = aggregateDataForDup(dataSet, 'num');

    for (String key : uidLocationMap.keySet()) {
      if (!dupSet.contains(uidLocationMap.get(key).LocationNumber__c)) {
        result.put(key, uidLocationMap.get(key));
      }
    }
    return result;
  }

  private static List<Map<String, Object>> toMapList(List<Location__c> locations) {
    List<Map<String, Object>> data = new List<Map<String, Object>>();
    for (Location__c loc : locations) {
      data.add(genRecord(loc.LocationNumber__c, loc));
    }
    return data;
  }

  private static Set<String> findDupUids(Map<String, Location__c> uidLocationMap) {
    Set<String> detector = new Set<String>();
    Set<String> dupSet = new Set<String>();
    String locId;
    for (String key : uidLocationMap.keySet()) {
      locId = uidLocationMap.get(key).Id;
      if (detector.contains(locId)) {
        dupSet.add(key);
      } else {
        detector.add(locId);
      }
    }
    return dupSet;
  }

  public Map<String, Location__c> getUidLocationMap(String projectId, String retailerId) {
    Map<String, Location__c> result = new Map<String, Location__c>();
    Map<String, Location__c> locMap = new Map<String, Location__c>();

    if (this.numbers.size() > 0) {
      if (string.isBlank(retailerId)) {
        logError('In order to use location number, you must select a Retailer on the project');
      } else {
        List<String> locNums = this.numbers;
         
        locMap = new Map<String, Location__c>([SELECT Id, Name, LocationNumber__c from Location__c Where IsActive__c = true AND Type__c = 'Location' AND Retailer__c = :retailerId AND LocationNumber__c IN :locNums AND Id Not In (Select Location__c FROM ProjectLocation__c Where Project__c = :projectId )]);

        for (Location__c loc : locMap.values()) {
          result.put(loc.LocationNumber__c.toUpperCase(), loc);
        }
      }
    }

    if (this.guids.size() > 0) {
      List<String> ohIdSet = this.guids;
      Set<String> locIdSet = locMap.keySet();
      List<Location__c>
      locs = (locIdSet.size() > 0)
             ? [SELECT Id, Name, LocationNumber__c, OneHubLocationID__c from Location__c Where IsActive__c = true AND Type__c = 'Location' AND LocationNumber__c NOT IN :locIdSet AND OneHubLocationID__c IN :ohIdSet AND Id Not In (Select Location__c FROM ProjectLocation__c Where Project__c = :projectId )]
             : [SELECT Id, Name, LocationNumber__c, OneHubLocationID__c  from Location__c Where IsActive__c = true AND Type__c = 'Location' AND OneHubLocationID__c IN :ohIdSet AND Id Not In (Select Location__c FROM ProjectLocation__c Where Project__c = :projectId )];
      for (Location__c loc : locs) {
        result.put(loc.OneHubLocationID__c.toUpperCase(), loc);
      }
    }

    return result;
  }

  public static Set<String> findDupLocationUids(Map<String, Location__c> uidLocationMap) {
    Set<String> result = new Set<String>();
    Map<String, String> idUidMap = LocationUploadPasteAnalyzer.toIdUidMap(uidLocationMap);
    Set<String> idSet = idUidMap.keySet();

    for (ProjectLocation__c pl : [SELECT Location__c FROM ProjectLocation__c WHERE Location__c IN :idSet ]) {
      if (idUidMap.containsKey(pl.Location__c)) {
        result.add(idUidMap.get(pl.Location__c));
      }
    }
    result.addAll(findDupUids(uidLocationMap));

    return result;
  }

  public List<Map<String, Object>> findDupLocations(List<Map<String, Object>> locations) {
    List<Map<String, Object>> result = new List<Map<String, Object>>();
    Set<Object> detector = new Set<Object>();

    for (Map<String, Object> loc : locations) {
      if (!detector.contains(loc.get('id'))) {
        detector.add(loc.get('id'));
      } else {
        result.add(loc);
      }
    }
    return result;
  }

  public static Map<String, Map<String, Object>> toUidMap(List<Map<String, Object>> data) {
    Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();
    for (Map<String, Object> m : data) {
      result.put(String.valueOf(m.get('uid')).toUpperCase(), m);
    }
    return result;
  }

  public static Set<String> toNumSet(List<Map<String, Object>> data) {
    return toFieldSet(data, 'num');
  }

  public static Set<String> toFieldSet(List<Map<String, Object>> data, String field) {
    Set<String> fieldSet = new Set<String>();
    for (Map<String, object> m : data) {
      if (m.get(field) != null) {
        fieldSet.add(String.valueOf(m.get(field)));
      }
    }
    return fieldSet;
  }

  public List<Map<String, Object>> findValidData(Map<String, List<Map<String, Object>>> dataSet) {
    List<Map<String, Object>> exclusions = dataSet.get(ExclusionsKey);
    List<Map<String, Object>> data = dataSet.get(LocationsKey);
    if (exclusions.size() == 0) {
      return data;
    }
    
    String keyField = getSearchField();
    Set<String> dupKeySet = toFieldSet(exclusions, keyField);

    List<Map<String, Object>> result = new List<Map<String, Object>>();
    for (Map<String, Object> m : data) {
      if (m.get(keyField) != null) {
        if (!dupKeySet.contains(String.valueOf(m.get(keyField)))) {
          result.add(m);
        }
      }
    }
    return result;
  }

  public Map<String, List<Map<String, Object>>> getData (String projectId, String retailerId, String retailerAccountId) {
    Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();
    Map<String, List<Map<String, Object>>> guidData = getLocationsByGuid(projectId);
    Map<String, List<Map<String, Object>>> numData = getLoctionsByNumber(projectId, retailerId, retailerAccountId);

    List<Map<String, Object>> data = new List<Map<String, Object>>();
    List<Map<String, Object>> exclusions = new List<Map<String, Object>>();
    data.addAll(guidData.get(LocationsKey));
    data.addAll(numData.get(LocationsKey));
    exclusions.addAll(guidData.get(ExclusionsKey));
    exclusions.addAll(numData.get(ExclusionsKey));
    exclusions.addAll(findExclusions(guidData, numData));
    result.put(LocationsKey, data);
    result.put(ExclusionsKey, exclusions);
    return result;
  }

  public Map<String, List<Map<String, Object>>> getLocationsByGuid(String projectId) {
    List<String> idSet = this.guids;
    List<Map<String, Object>> data = new List<Map<String, Object>>();
    Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();
    Map<String, Object> rec;

    if (idSet.size() == 0) {
      return createNilResult();
    }

    List<String> conditions = new List<String>();
    conditions.add('OneHubLocationID__c IN :idSet');

    String sql = baseSQL + ' AND ' + String.join(conditions, ' AND ');

    for (Location__c loc : Database.query(sql)) {
      data.add(genRecord(loc.OneHubLocationID__c, loc));
    }
    result.put(LocationsKey, data);
    system.debug('all locations++++' + result );

    data = new List<Map<String, Object>>();
    conditions.add('Id IN (SELECT Location__c FROM ProjectLocation__c Where  Project__c=:projectId)');
    sql = baseSQL + ' AND ' + String.join(conditions, ' AND ');
      system.debug('soql::::' + sql);

    for (Location__c loc : Database.query(sql)) {
      data.add(genRecord(loc.OneHubLocationID__c, loc));
    }

    result.put(ExclusionsKey, data);
     // system.debug('ExclusionsKey locations++++' + result );
    return result;
  }

  public Map<String, List<Map<String, Object>>> getLoctionsByNumber(String projectId, String retailerId, String retailerAccountId) {

    List<String> idSet = this.numbers;
    if (idSet.size() == 0) {
      return createNilResult();
    }

    if (String.isNotBlank(retailerAccountId)) {
      this.retailerAccountAssigned = true;
    } else if (useLocationNubmerBySetting || this.overrideUseGuid == USE_LOCATION_NUMBER) {
      throw new AuraHandledException('In order to add locations by the location number, you must select A Retailer Account on the project.');
    }

    Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();
    List<Map<String, Object>> data = new List<Map<String, Object>>();
    Map<String, Object> rec;
    List<String> conditions = new List<String>();
    system.debug('retailerAccountId:::' + retailerAccountId);
    system.debug('retailerId:::' + retailerId);
      
      
    if (this.retailerAccountAssigned) {
      conditions.add('RetailerAccount__c = :retailerAccountId');
    }

    if (String.isNotBlank(retailerId)) {
      conditions.add('Retailer__c = :retailerId');
    }
    
    conditions.add('LocationNumber__c IN :idSet');
    String sql = baseSQL + ' AND ' + String.join(conditions, ' AND ');
    for (Location__c loc : Database.query(sql)) {
      data.add(genRecord(loc.LocationNumber__c, loc));
    }
    result.put(LocationsKey, data);

    data = new List<Map<String, Object>>();
    conditions.add('Id IN (SELECT Location__c FROM ProjectLocation__c Where Project__c=:projectId)');

    sql = baseSQL + ' AND ' + String.join(conditions, ' AND ');
    system.debug('sql:::' + sql);
    for (Location__c loc : Database.query(sql)) {
      data.add(genRecord(loc.LocationNumber__c, loc));
    }

    result.put(ExclusionsKey, data);
    return result;
  }

  private List<Map<String, Object>> findExclusions(
    Map<String, List<Map<String, Object>>> guidData,
    Map<String, List<Map<String, Object>>> numData) {

    String key;
    List<Map<String, Object>> exclusions = new List<Map<String, Object>>();
    List<Map<String, Object>> data = new List<Map<String, Object>>();

    data.addAll(guidData.get(LocationsKey));
    data.addAll(numData.get(LocationsKey));

    string field = getSearchField();
    system.debug('field' + field);
    Set<String> dupSet = aggregateDataForDup(data, field);
    system.debug('dupSet+++++' + dupSet);

    for (Map<String, Object> m : data) {
      key = String.valueOf(m.get(field));
      if (dupSet.contains(key)) {
        exclusions.add(m);
      }
    }
    system.debug('exculsions+++++++' + exclusions);
    return exclusions;
  }

  private String getSearchField() {
    if (this.overrideUseGuid == USE_LOCATION_NUMBER) {
      return 'num';
    } else if (this.overrideUseGuid == USE_LOCATION_GUID){
      return 'guid';
    } 

    return (this.retailerAccountAssigned || useLocationNubmerBySetting)
           ? 'num'
           : 'guid';
  }


  private static Set<String> aggregateDataForDup(List<Map<String, Object>> data, String field) {
    String key;
    Set<String> bufSet = new Set<String>();
    Set<String> result = new Set<String>();

    for (Map<String, Object> m : data) {
      key = String.valueOf(m.get(field));
      if (bufSet.contains(key)) {
        result.add(key);
      } else {
        bufSet.add(key);
      }
    }

    return result;
  }

  private Map<String, List<Map<String, Object>>> createNilResult() {
    Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();
    result.put(LocationsKey, new List<Map<String, Object>>());
    result.put(ExclusionsKey, new List<Map<String, Object>>());
    return result;
  }

  private static Map<String, Object> genRecord(string uid, Location__c loc) {
    Map<String, Object> rec = new Map<String, Object>();
    rec.put('id', loc.Id);
    rec.put('uid', uid.toUpperCase());
    rec.put('num', loc.LocationNumber__c);
    rec.put('guid', loc.OneHubLocationID__c);
    rec.put('desc', loc.Name);
    return rec;
  }
}