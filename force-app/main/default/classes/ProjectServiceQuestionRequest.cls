public with sharing class ProjectServiceQuestionRequest extends LightningRequestBase {
    
    public override Object filter(Object parameters) {
        String psId = parseServiceId(parameters);
        return filterQuestions(psId);
    }

    String parseServiceId(Object parameters){
        Map<String,Object> query = (Map<String,Object>) parameters;
        String psId = LightningRequestHelper.parseString(query.get('serviceId'));
        if(String.isEmpty(psId)){
            throw new AuraHandledException('The project serivce id is required.');
        }
        return psId;
    }

    List<List<String>> filterQuestions(String psId){
        List<String> rec;
        List<List<String>> rs = new List<List<String>>();
        
        for(ProjectServiceQuestion__c q: [SELECT Question__c, Question__r.Name, AILabel__c 
                                          FROM ProjectServiceQuestion__c 
                                          WHERE ProjectService__c=:psId 
                                          AND QuestionType__c = 'Photo']){
            rec = new List<String>();
            rec.add(q.Question__c);
            rec.add(q.Question__r.Name);
            rec.add(q.AILabel__c);
            rs.add(rec);
        }


        return rs;
    }
}