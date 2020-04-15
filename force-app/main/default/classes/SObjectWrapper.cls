public with sharing class SObjectWrapper {
    private static String NAMESPACE = CONSTANTS.CURRENTNAMESPACEPREFIX;
    private SObject record;

    private static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(NAMESPACE + typeName);
        if (targetType == null) {
            throw new NoDataFoundException();
        }
        return targetType.newSObject();
    }

    public SObjectWrapper(String typeName) {
        this.record = createObject(typeName);
    }

    public String getString(String fieldName) {
        return String.valueOf(this.record.get(NAMESPACE + fieldName));
    }

    public Integer getInteger(String fieldName) {
        return Integer.valueOf(this.record.get(NAMESPACE + fieldName));
    }

    public SObject getSObject(String fieldName) {
        return this.record.getSObject(NAMESPACE + fieldName);
    }

    public Date getDate(String fieldName) {
        return Date.valueOf(this.record.get(NAMESPACE + fieldName));
    }

    public void put(string fieldName, Object value) {
        this.record.put(NAMESPACE + fieldName, value);
    }

    public sObject doInsert() {
        insert this.record;
        return this.record;
    }
}