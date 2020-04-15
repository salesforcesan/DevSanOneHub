public class ProjectServiceQuestionRuleWrapper {
    
    @AuraEnabled
    public String Id{get;set;}
    @AuraEnabled
    public String Name{get;set;}
    @AuraEnabled
    public String ProjectServiceQuestion{get;set;}
    @AuraEnabled
    public String ParentProjectServiceQuestion{get;set;}
    @AuraEnabled
    public String SqOperator{get;set;}
    @AuraEnabled
    public String SqValue{get;set;}
    @AuraEnabled
    public String ServiceQuestionText{get;set;}
    @AuraEnabled
    public String ParentProjectServiceQuestionText{get;set;}    
    
    @AuraEnabled
    public String RuleText{get;set;}
    
    @AuraEnabled
    public List<String> RuleValueText{get;set;}
    
    @AuraEnabled
    public ResponseWrapper DefinedResponses {get;set;}
        
    public ProjectServiceQuestionRuleWrapper()
    {
        
    }
    
    public ProjectServiceQuestionRuleWrapper(ProjectServiceQuestionRule__c projectServiceQuestionRule)
    {
        Map<String, Object> fieldsToValue = projectServiceQuestionRule.getPopulatedFieldsAsMap();
        
        Id = projectServiceQuestionRule.Id;
		Name = projectServiceQuestionRule.Name;             
        ProjectServiceQuestion = projectServiceQuestionRule.ProjectServiceQuestion__c;                        
        ParentProjectServiceQuestion = projectServiceQuestionRule.ParentProjectServiceQuestion__c;                         
        SqOperator = projectServiceQuestionRule.Operator__c;         
        SqValue = projectServiceQuestionRule.DefinedResponseValue__c;//projectServiceQuestionRule.Value__c == null ? '' : projectServiceQuestionRule.Value__c;
        ServiceQuestionText = projectServiceQuestionRule.ProjectServiceQuestionText__c;
        ParentProjectServiceQuestionText = projectServiceQuestionRule.ParentProjectServiceQuestionText__c;
        RuleText = SqOperator + ' ' + ((projectServiceQuestionRule.ParentProjectServiceQuestionType__c == 'Single-Select List' || projectServiceQuestionRule.ParentProjectServiceQuestionType__c == 'Multi-Select List') ?  projectServiceQuestionRule.DefinedResponseValueText__c : SqValue);                    
    }
    
}