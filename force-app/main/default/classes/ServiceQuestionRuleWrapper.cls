public class ServiceQuestionRuleWrapper {
    
    @AuraEnabled
    public String Id{get;set;}
    @AuraEnabled
    public String Name{get;set;}
    @AuraEnabled
    public String ServiceQuestion{get;set;}
    @AuraEnabled
    public String ParentServiceQuestion{get;set;}
    @AuraEnabled
    public String SqOperator{get;set;}
    @AuraEnabled
    public String SqValue{get;set;}
    @AuraEnabled
    public String ServiceQuestionText{get;set;}
    @AuraEnabled
    public String ParentServiceQuestionText{get;set;}
    
    @AuraEnabled
    public String RuleText{get;set;}
    
    @AuraEnabled
    public List<String> RuleValueText{get;set;}
    
    @AuraEnabled
    public ResponseWrapper DefinedResponses {get;set;}
        
    public ServiceQuestionRuleWrapper()
    {
        
    }
    
    public ServiceQuestionRuleWrapper(ServiceQuestionRule__c serviceQuestionRule)
    {
        Map<String, Object> fieldsToValue = serviceQuestionRule.getPopulatedFieldsAsMap();
        
        Id = serviceQuestionRule.Id;
		Name = serviceQuestionRule.Name;             
        ServiceQuestion = serviceQuestionRule.ServiceQuestion__c;                        
        ParentServiceQuestion = serviceQuestionRule.ParentServiceQuestion__c;                         
        SqOperator = serviceQuestionRule.Operator__c;         
        SqValue =serviceQuestionRule.Value__c;
        ServiceQuestionText = serviceQuestionRule.ServiceQuestionText__c;
        ParentServiceQuestionText = serviceQuestionRule.ParentServiceQuestionText__c;
        //OH2-2168
        RuleText = SqOperator + ' ' + ((serviceQuestionRule.ParentServiceQuestionType__c == 'Single-Select List' || serviceQuestionRule.ParentServiceQuestionType__c == 'Multi-Select List'  ) ? serviceQuestionRule.Value__c : '');
        //RuleText = SqOperator + ' ' + ((serviceQuestionRule.ParentServiceQuestionType__c == 'Single-Select List' ) ? serviceQuestionRule.Value__c : '');
    }
    
    public ServiceQuestionRuleWrapper(ProjectServiceQuestionRule__c projectServiceQuestionRule)
    {
        Map<String, Object> fieldsToValue = projectServiceQuestionRule.getPopulatedFieldsAsMap();
        
        Id = projectServiceQuestionRule.Id;
        Name = projectServiceQuestionRule.Name;             
        ServiceQuestion = projectServiceQuestionRule.ProjectServiceQuestion__c;                        
        ParentServiceQuestion = projectServiceQuestionRule.ParentProjectServiceQuestion__c;                         
        SqOperator = projectServiceQuestionRule.Operator__c;         
        SqValue = projectServiceQuestionRule.Value__c;//projectServiceQuestionRule.Value__c == null ? '' : projectServiceQuestionRule.Value__c;
        ServiceQuestionText = projectServiceQuestionRule.ProjectServiceQuestionText__c;
        ParentServiceQuestionText = projectServiceQuestionRule.ParentProjectServiceQuestionText__c;
        RuleText = SqOperator + ' ' + ((projectServiceQuestionRule.ParentProjectServiceQuestionType__c == 'Single-Select List' ) ?  projectServiceQuestionRule.value__c : SqValue);                    
    }
    
}