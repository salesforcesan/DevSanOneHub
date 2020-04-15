public without sharing class SurveyState {
	boolean hasExceptionQuestion;
	Set<Id> questions;

	private SurveyState(Set<Id> added, Boolean hasException) {
		questions = added;
		hasExceptionQuestion = hasException;
	}

	public static SurveyState fromProjectBuilder(String objId){
		List<Object> result = getAlreadyAddedQuestions(objId, true);
		return new SurveyState((Set<Id>) result[0], (Boolean) result[1]);
	}

	public static SurveyState fromServiceBuilder(String objId){
		List<Object> result = getAlreadyAddedQuestions(objId, false);
		return new SurveyState((Set<Id>) result[0], (Boolean) result[1]);
	}

	public Boolean isQuestionValidToAdd(Id questionId, Boolean isException){
		if (questions.contains(questionId)) {return false;}
		if (hasExceptionQuestion && isException){
			return false;
		}
		return true;
	}

	@testVisible
	static List<Object> getAlreadyAddedQuestions(String sId, Boolean isProjectService) {
		List<Object> result = new List<Object>();
		Set<Id> targets = new Set<Id>();
		Boolean hasException = false;

		if (isProjectService) {
			for (ProjectServiceQuestion__c psq : [SELECT Question__c, Question__r.ExceptionQuestion__c
			                                      FROM ProjectServiceQuestion__c WHERE ProjectService__c = :sId]) {
				targets.add(psq.Question__c);
				if (psq.Question__r.ExceptionQuestion__c){
					hasException = true;
				}
			}
		} else {
			for (ServiceQuestion__c sq : [SELECT Question__c, Question__r.ExceptionQuestion__c
			                              FROM ServiceQuestion__c WHERE Service__c = :sId]) {
				targets.add(sq.Question__c);
				if (sq.Question__r.ExceptionQuestion__c){
					hasException = true;
				}	
			}
		}

		result.addAll(new Object[]{targets, hasException});
		return result;
	}
}