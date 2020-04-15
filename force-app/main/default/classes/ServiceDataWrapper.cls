public class ServiceDataWrapper {

    public ServiceData Service;
    public List<ServiceAttributeData> ServiceAttributes;
    public List<ServiceQuestionData> ServiceQuestions;
    public List<ServiceQuestionDRData> ServiceQuestionDRs;
    public List<ServiceQuestionRuleData> ServiceQuestionRules;

    public class ServiceData{
    
        public String Name;
        public Boolean AllowDistribution;
        public Boolean NoSurvey;
        public String Duration;
        public Boolean IsNumberOfWorkersRequired;
        public string ServiceDescription;
        public String TargetType;
        public Boolean IsBulkScan;
        public Boolean IsSelfDirected;
        public Boolean IsBillable;
        public string Specialization;
        
        public Integer Minutes;
        public string SurveyTemplateVersion;
        public Boolean IsVisibleToClient;
        public string AllowedTargetUse;
        public string ServiceFamily;
        public string ExceptionPrompt;
        
        
    
    }
      
    public class ServiceAttributeData{
        public Decimal AttributeOrder;
        public String AttributeTitle;
        public String AttributeType;
        public string DefaultAttributeValue;
        public Boolean ExcludeFromJobManual;
        public Boolean IsVisible;
        
        
        
    }
    
    public class ServiceQuestionData{

        public String JumpToAction;
        public String OneHubQuestionId;
        public Decimal QuestionNumber;
        public Boolean CanRemove;
        public Boolean Optional;
        
        public Integer MaxValue;
        public Integer MinValue;
        public String QuestionIndentation;
        public String ParentOneHubQuestionId;
        
        
        
        
    }   
    
    public class ServiceQuestionDRData{

        public String OneHubQuestionId;
        public String OneHubDefinedResponseId;
        public Boolean CanRemove;
        public Boolean Optional;
        public String JumpToAction;
        public String JumpToOneHubQuestionId;    
        
        public Boolean IsActive;    
                
    }
    
    public class ServiceQuestionRuleData{

        public String Operator;
        public String Value;
        public String OneHubQuestionId;
        public String ParentOneHubQuestionId;
    }    
    
    
    
    
}