public class QuestionWrapper {
        
        @AuraEnabled
        public string ID {get; set;}
            
        @AuraEnabled
        public string ParentID {get; set;}
    
        @AuraEnabled
        public Boolean Active {get; set;}

        @AuraEnabled
        public string QuestionId {get; set;}
    
        @AuraEnabled
        public string ProjectServiceQuestionId {get; set;}
    
        @AuraEnabled
        public string MinValue {get; set;}
    
        @AuraEnabled
        public string MaxValue {get; set;}
    
        @AuraEnabled
        public string HintQuestion {get; set;}
    
        @AuraEnabled
        public Boolean HintLock {get; set;}
    
        @AuraEnabled
        public string QuestionText {get; set;}
    
        @AuraEnabled
        public string QuestionTitle {get; set;}
    
    
        @AuraEnabled
        public Boolean ItemQuestion {get; set;}
    
        @AuraEnabled
        public string QuestionType {get; set;}
    
        @AuraEnabled
        public Integer DefinedResponseCount {get; set;}

        @AuraEnabled
        public Boolean ServiceQuestion {get; set;}
    
        @AuraEnabled
        public Boolean CanRemove {get; set;}

        @AuraEnabled
        public Boolean IsOptionEditable {get;set;}
        
        @AuraEnabled
        public Boolean Optional {get; set;}
        
        @AuraEnabled
        public Integer QuestionNumber {get; set;}
    
        @AuraEnabled
        public Boolean IsProjectServiceQuestion {get; set;}
    
        @AuraEnabled
        public Boolean IsServiceQuestion {get; set;}
    
        @AuraEnabled
        public Boolean IsQuestion {get; set;}
    
        @AuraEnabled
        public Boolean IsFirstItemQuestion {get; set;}
    
        @AuraEnabled
        public Boolean IsLastItemQuestion {get; set;}
        
        @AuraEnabled
        public Boolean IsExceptionQuestion {get; set;}
    
        @AuraEnabled
        public string JumpToAction {get; set;}
    
    	@AuraEnabled
        public string AILabelName {get; set;}
    
    	@AuraEnabled
        public string AILabelId{get; set;}
    
        @AuraEnabled
        public List<UISelectWrapper> AllowedJumpToActions {get; set;}
    
		@AuraEnabled
        public string QuestionIndentation {get; set;}

        @AuraEnabled
        public string ParentQuestionIndentation {get; set;}
    
    	@AuraEnabled
        public integer QuestionIndentationSize {get; set;}
    
    	@AuraEnabled
        public integer QuestionIndentationLevel {get; set;}
    
		@AuraEnabled
        public string[] QuestionIndentationArray {get; set;}

        @AuraEnabled
        public Boolean HasChild {get; set;}
    
    	@AuraEnabled
        public ServiceQuestionRuleWrapper ServiceQuestionRule {get; set;}
    
    	@AuraEnabled
        public List<ServiceQuestionRuleWrapper> ServiceQuestionRuleList {get; set;}
        
    	//@AuraEnabled
        //public ProjectServiceQuestionRuleWrapper ProjectServiceQuestionRule {get; set;}

    	//@AuraEnabled
        //public List<ProjectServiceQuestionRuleWrapper> ProjectServiceQuestionRuleList {get; set;}
    
    	@AuraEnabled
        public QuestionWrapper PreviousServiceQuestion {get; set;}
    
        @AuraEnabled
        public DefinedResponseWrapper[] DefinedResponses {get; set;}    
    
    	public QuestionWrapper() 
        {
          
        } 
    }