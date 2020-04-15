public with sharing class SObjectListHelper {
    public static Set<ID> getIdSet(List<SObject> sObjects, String idName) {
        Set<ID> idSet = new Set<ID>();
        String idField = idName.toUpperCase() == 'ID' ? idName : CONSTANTS.CURRENTNAMESPACEPREFIX + idName;
        for(SObject obj: sObjects) {
            if (null != obj.get(idField)) {
                idSet.add((ID)obj.get(idField));
            }
        }
        return idSet;
    }

    public static Set<String> getStringSet(List<SObject> sObjects, String fieldName) {
        Set<String> result = new Set<String>();
        String idField = fieldName.toUpperCase() == 'NAME' ? fieldName : CONSTANTS.CURRENTNAMESPACEPREFIX + fieldName;
        for(SObject obj: sObjects) {
            if (null != obj.get(idField)) {
                result.add(String.valueOf(obj.get(idField)));
            }
        }
        return result;
    }
}