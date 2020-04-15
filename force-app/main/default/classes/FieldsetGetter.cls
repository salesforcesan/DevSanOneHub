public without sharing class FieldsetGetter {
    String ObjectType {get;set;}
    List<Map<String,String>> FieldDefinitons {get;set;}

    private FieldsetGetter(String sObjectType){
        this.ObjectType = sObjectType;
    }

    public static FieldsetGetter create(String sObjectType){
        return new FieldsetGetter(sObjectType);
    }

    public List<Map<String,String>> getFieldsetDefinition(String fieldsetName){
        Map<String, String> fieldDefinition;
        List<Map<String,String>> result = new List<Map<String,String>>();
        Schema.FieldSet root = getFieldSet(fieldSetName);
        
        for(FieldSetMember m: root.getFields()){
            fieldDefinition = new Map<String,String>();
            fieldDefinition.put('name', m.getFieldPath());
            fieldDefinition.put('label', m.getLabel());
            fieldDefinition.put('type', String.valueOf(m.getType()));
            fieldDefinition.put('required', String.valueOf(m.getRequired()));
            result.add(fieldDefinition);
        }
        this.FieldDefinitons = result;
        return result;
    }

    public List<String[]> getNameValueList(SObject record){
        List<String[]> rs = new List<String[]>();
        for(Map<String,String> field: this.FieldDefinitons){
            if(!Boolean.valueOf(field.get('required'))){
                rs.add(new String[]{
                    field.get('label'),
                    getValue(field.get('name'), record)
                    });
            }
        }

        return rs;
    }

    @testVisible
    String getValue(String fieldName, Sobject record){
        if(fieldName.indexOf('.') == -1){
            return String.valueOf(record.get(namespacify(fieldName)));
        }
        Integer pos = fieldName.indexOf('.');
        String refName = fieldName.substring(0, pos), refFldName = fieldName.substring(pos + 1);
        Sobject ref = record.getSobject(refName);
        if(ref == null || ref.get(refFldName) == null){
            return '';
        }
        return string.valueOf(ref.get(namespacify(refFldName)));
    }

    public String getTitle(SObject record){
        List<String> title = new List<String>();

        for(Map<String,String> field: this.FieldDefinitons){
            if(Boolean.valueOf(field.get('required'))){
                title.add(String.valueOf(getValue(field.get('name'), record)));
            }
        }        
        return string.join(title, ' - ');
    }

    @testVisible
    Schema.FieldSet getFieldSet(String fieldSetName){
        DescribeSObjectResult sResult = getSObjectResult();        
        return sResult.fieldSets.getMap().get(namify(fieldSetName));
    }

    @testVisible
    DescribeSObjectResult getSObjectResult(){
        String[] types = new String[] {namespacify(this.ObjectType)};
        for(Schema.DescribeSobjectResult res : Schema.describeSObjects(types)){
            return res;
        }
        throw new CustomException('The SObject Type ' + this.ObjectType + ' is invalid');
    }

    String namespacify(String name){
        if(!isCustomField(name)) {return name;}
        
        return namify(name);
    }
    static Boolean isCustomField(String name){
        return (name.indexOfIgnoreCase('__c') != -1) 
            ? true
            : false;
    }
    static String namify(string name){
         return name.indexOf(CONSTANTS.CURRENTNAMESPACEPREFIX) == 0 
                ? name 
                : CONSTANTS.CURRENTNAMESPACEPREFIX + name;   
    }
}