public without sharing class LightningRequestHelper {
  public static final Date DEFAULT_DATE {get;set;}
  public static final string ACTION_KEYWORD {get;set;}
  public static final Integer MAX_ROW_SIZE {get;set;}
  public static final Integer PAGE_SIZE {get;set;}

  static {
    DEFAULT_DATE = Date.newInstance(1900,1,1);
    ACTION_KEYWORD = '__action';
    MAX_ROW_SIZE = 100;
    PAGE_SIZE = AppUtil.PageSize;
  }

  public static string parseString(Object obj){
    return obj != null ? String.valueOf(obj): '';
  }

  public static Double parseDouble(Object obj){
    try{
      return obj != null ? Double.valueOf(obj) : 0;  
    }
    catch(Exception ex){
      return 0;
    }
  }

  public static Decimal parseDecimal(Object obj){
    try{
      String val = parseString(obj);
      return val != '' ? Decimal.valueOf(val): 0;  
    }
    catch(Exception ex){
      return 0;
    }
  }

  public static Boolean parseBoolean(Object obj){
    return parseString(obj) == '1' ? true : false;
  }

  public static Boolean isOneHubLocationId(string ohId){
    String num = String.isBlank(ohId) ? '' : ohId;
    return num.length() > 10;
  }

  public static Boolean isId(Object obj){
    try {
      String idStr = String.valueOf(obj);
      Id data = Id.valueOf(idStr);
      return true;
    }
    catch(Exception ex){
      return false;
    }
  }

  public static List<String> parseArrayOfString(Object obj){
    String locId;
    try{
      List<String> results = new List<String>();
      List<Object> items = obj != null ? (List<Object>) obj : new List<Object>();
      for(Object item: items){
        locId = String.valueOf(item);
        if (String.isNotBlank(locId)){
          results.add(locId);
        }
      }
      return results;
    }catch(Exception ex){
      return new List<String>();
    }
  }

  public static List<Id> parseArrayOfId(Object obj){
    try{
      List<Object> items = (obj != null) ? (List<Object>) obj : new List<Object>();
      List<Id> idSet = new List<Id>();
      for(Object item: items){
        idSet.add(ID.valueOf(String.valueOf(item)));
      }
      return idSet;
    }catch(Exception ex){
      return new List<Id>();
    }
  }

  public static String getRequestAction(Map<String,Object> query){
    return parseString(query.get(ACTION_KEYWORD));
  }

  public static Integer parseInteger(Object obj){
    return obj != null ? Integer.valueOf(obj) : 0;
  }

  public static Date parseDate(Object obj) {
    String dateString = parseString(obj);
    if(String.isBlank(dateString)){
      return DEFAULT_DATE;
    }
    
    if(dateString.indexOf('/') != -1) {
      return Date.parse(dateString);
    }

    String[] dateItems= dateString.split('-');
    if (dateItems.size() != 3){
      return DEFAULT_DATE;
    }

    return Date.parse(dateItems[1] + '/' + dateItems[2] + '/' + dateItems[0]);
  }

  public static Boolean isDateNull(Date source){
    return source == DEFAULT_DATE;
  }

  public static Map<String,Object> parseObjectMap(Object obj){
    try {
      return (Map<String,object>)obj;
    }
    catch(Exception ex){
      return new Map<String,object>();
    }
  }

  public static List<String> parseStringList(Object val){
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

  public static Map<String,String> parseStringMap(Object val){
    Map<String,Object> vals = (Map<String,Object>)val;
    Map<String,String> result = new Map<String,String>();
    for(String key: vals.keySet()){
      result.put(key, vals.get(key) != null 
        ? String.valueOf(vals.get(key)) : '');
    }
    return result;
  }

  public static List<Map<String,Object>> parseMapList(Object val){
    List<Map<String,Object>> result = new List<Map<String,Object>>();
    if(null != val){
      List<Object> values = (List<Object>) val;
      for(Object obj: values) {
        Map<String,Object> rec = new Map<String,Object>();
        Map<String,Object> objMap = parseObjectMap(obj);
        for(String key: objMap.keyset()){
          rec.put(key, objMap.get(key));
        }
        result.add(rec);
      }
    }
    return result;
  }

  public static List<Map<String,String>> getPicklist(string recordName, string fieldName){
    List<Map<String,String>> items = new List<Map<String,String>>();
    String record = CONSTANTS.CURRENTNAMESPACEPREFIX + recordName;
    String field = CONSTANTS.CURRENTNAMESPACEPREFIX + fieldName;

    Schema.DescribeSObjectResult meta = Schema.describeSObjects(new String[]{record}).get(0);
    Map<String, Schema.SObjectField> fieldMap = meta.fields.getMap();
    List<Schema.PicklistEntry> pickList = fieldMap.get(field)
      .getDescribe().getPickListValues();

    for(Schema.PicklistEntry entry: pickList){
      Map<String,String> mapItem = new Map<String,String>();
      mapItem.put('id', entry.getValue());
      mapItem.put('value', entry.getLabel());
      items.add(mapItem);
    }
    return items;
  }

  public static void checkStringValueRequired(String value, String message){
    if (String.isBlank(value)) {
      throw new AuraHandledException(message);
    }
  }

  public static void checkStringArrayRequired(List<String> values, String message){
    if (values.size() == 0){
      throw new AuraHandledException(message);
    }
  }

  public static Map<String,Object> createResponse(String status, String message){
    Map<String,Object> response = new Map<String, Object>();
    response.put('state', status);
    response.put('message', message);
    return response;
  }

  public static Map<String,Object> createResponseWithData(String status, String message, Object data){
    Map<String,Object> response = new Map<String, Object>();
    response.put('state', status);
    response.put('message', message);
    response.put('data', data);
    return response;
  }
}