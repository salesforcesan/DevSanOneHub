public without sharing class FieldSetQueryBuilder {
    String ObjectType {get;set;}
    Integer LimitSize {get; set;}
    String OrderByStatement {get;set;}
    List<String> UserAddedFields {get;set;}
    List<String> UserPredicates {get;set;}

    private FieldSetQueryBuilder(String sObjectType){
        this.ObjectType = sObjectType;
        this.UserAddedFields = new List<String>();
        this.UserPredicates = new List<String>();
        this.LimitSize = 0;
        this.OrderByStatement = '';
    }

    public static FieldSetQueryBuilder create(String sObjectType){
        return new FieldSetQueryBuilder(sObjectType);
    }

    public FieldSetQueryBuilder addAdditionalFields(String[] fields){
        if(fields == null || fields.size() == 0) {
            throw new CustomException('No fields to add.');
        }
        
        this.UserAddedFields = new List<String>(fields);
        return this;
    }

    public FieldSetQueryBuilder addPredicates(String[] predicates){
        if(predicates == null || predicates.size()==0 ){
            throw new CustomException('No predicates to add.');
        }

        this.UserPredicates = new List<String>(predicates);
        return this;
    }

    public FieldSetQueryBuilder addOrderByStatement(String orderBy){
        this.OrderByStatement = orderBy;
        return this;
    }

    public FieldSetQueryBuilder setLimitSize(Integer size){
        this.LimitSize = size;
        return this;
    }

    public String build(List<Map<String,String>> fields){

        if (fields == null || fields.size() == 0){
            throw new CustomException('No fieldset is defined for the object ' + this.ObjectType);
        }
        
        List<String> sql = New List<String>(new String[]{'SELECT', 
            getFieldListString(fields),'FROM', this.ObjectType});

        if(this.UserPredicates.size() > 0){
            sql.add('WHERE');
            List<String> filter = new List<String>();
            for(String predicate: this.UserPredicates){
                filter.add(predicate);
            }
            sql.add(String.join(filter, ' AND '));
        }

        if(!String.isBlank(this.OrderByStatement)) {
            sql.add(this.OrderByStatement);
        }

        if(this.LimitSize > 0){
            sql.add('Limit ' + String.valueOf(this.LimitSize));
        }

        return String.join(sql, ' ');
    }

    @testVisible
    String getFieldListString(List<Map<String,String>> fields){
        Set<String> sqlFields = new Set<String>();
        Boolean hasId = false;

        for(Map<String,String> field: fields){
            sqlFields.add(field.get('name'));
            if ('ID'.equalsIgnoreCase(field.get('type'))){
                hasId = true;
            }
        }
        
        for(String field: this.UserAddedFields){
            if('Id'.equalsIgnoreCase(field)) {
                hasId = true;
            }
            sqlFields.add(field);
        }

        if(!hasId){
            sqlFields.add('Id');
        }

        return String.join(new List<String>(sqlFields),',');
    }
}