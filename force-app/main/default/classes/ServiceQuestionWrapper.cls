global class ServiceQuestionWrapper implements Comparable {

    public ServiceQuestion__c ServiceQuestion;
    
    // Constructor
    public ServiceQuestionWrapper(ServiceQuestion__c sq) {
        ServiceQuestion = sq;
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        
        // Cast argument to OpportunityWrapper
        ServiceQuestionWrapper compareToOppy = (ServiceQuestionWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (ServiceQuestion.QuestionNumber__c > compareToOppy.ServiceQuestion.QuestionNumber__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (ServiceQuestion.QuestionNumber__c < compareToOppy.ServiceQuestion.QuestionNumber__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}