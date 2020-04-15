public without sharing class LightningGatewayController {
  static String AppNameSpace {get; set;}
  static {
    AppNameSpace = CONSTANTS.CURRENTNAMESPACE;
  }

  static Map<String, Object> parseQ(string query) {
    return (Map<String, Object>)JSON.deserializeUntyped(query);
  }

  @AuraEnabled
  public static Object add(string query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.add(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object modify(string query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.modify(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object remove(String query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.remove(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object search(String query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.search(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  @AuraEnabled
  public static Object filter(String query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.filter(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }


  @AuraEnabled
  public static Object get(String query) {
    try {
      Map<String, Object> params = parseQ(query);
      ILightningRequest instance = createInstance(params);
      return instance.get(mapObject(params.get('body'), params.get('action')));
    } catch (DmlException dml) {
      throw new AuraHandledException(genDMLMessage(dml));
    } catch (AuraHandledException auraEx) {
      throw auraEx;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getStackTraceString() + ' :' + ex.getMessage());
    }
  }

  static ILightningRequest createInstance(Map<String, Object> query) {
    string className = LightningRequestHelper.parseString(query.get('class'));
    if (String.isBlank(className)) {
      throw new AuraHandledException('The apex class name are missing.');
    }

    Type classType = Type.forName(AppNameSpace, className);
    return (ILightningRequest) classType.newInstance();
  }

  static Map<String, Object> mapObject(object obj, object action) {
    Map<String, Object> result = new Map<String, Object>();
    try {
      Map<String, Object> params = (Map<String, Object>) obj;
      for (String key : params.keySet()) {
        result.put(key, params.get(key));
      }
    } catch (Exception ex) {
      result = new Map<String, object>();
    }
    result.put(LightningRequestHelper.ACTION_KEYWORD, action);
    return result;
  }

  static string genDMLMessage(DmlException dml) {
    List<String> msgs = new List<String>();
    for (Integer i = 0; i < dml.getNumDml(); i++) {
      msgs.add(dml.getDmlMessage(i));
    }
    return String.join(msgs, '. ');
  }
}