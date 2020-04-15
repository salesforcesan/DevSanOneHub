global class ProjectServiceQuestionWrapper implements Comparable {

    public ProjectServiceQuestion__c ProjectServiceQuestion;
    
    // Constructor
    public ProjectServiceQuestionWrapper(ProjectServiceQuestion__c sq) {
        ProjectServiceQuestion = sq;
    }
    
    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        
        // Cast argument to OpportunityWrapper
        ProjectServiceQuestionWrapper compareToOppy = (ProjectServiceQuestionWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (ProjectServiceQuestion.QuestionNumber__c > compareToOppy.ProjectServiceQuestion.QuestionNumber__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (ProjectServiceQuestion.QuestionNumber__c < compareToOppy.ProjectServiceQuestion.QuestionNumber__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}