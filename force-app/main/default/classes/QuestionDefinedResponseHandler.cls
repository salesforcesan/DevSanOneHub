public class QuestionDefinedResponseHandler extends TriggerHandler {
    
    public override void afterInsert(){
        if (TriggerUtil.skipQuestionDefinedResponseTrigger) return;
        //TriggerUtil.skipQuestionDefinedResponseTrigger = true; 
        set<Id>sQuestions = New set<Id>();
        Map<Id,List<QuestionDefinedResponse__c>> mapQDR = new Map<Id,list<QuestionDefinedResponse__c >>();
        List<ServiceQuestionDefinedResponse__c>lstSQDR= new  List<ServiceQuestionDefinedResponse__c>();
        for (QuestionDefinedResponse__c qdr: (List<QuestionDefinedResponse__c> ) Trigger.new) {
         sQuestions .add(qdr.Question__c);
            
        }
        
        for(Id question :sQuestions )
        {
            List<QuestionDefinedResponse__c> lstQDR = new List<QuestionDefinedResponse__c >();
            for (QuestionDefinedResponse__c qdr: (List<QuestionDefinedResponse__c> ) Trigger.new) {
                
                if(question == qdr.Question__c)
                {
                    lstQDR.add(qdr);
                    
                }
                
            }
            
            mapQDR.put(question,lstQDR);
        }
        
        List<ServiceQuestion__c> lsq = [Select Id,Question__c from ServiceQuestion__c  where  Question__c  IN :mapQDR.keyset()];
        
        for(  ServiceQuestion__c sq: lsq )
        {
            List<QuestionDefinedResponse__c> lstQuestionDefinedResponse =(List<QuestionDefinedResponse__c>)mapQDR.get(sq.Question__c);
            
            for (QuestionDefinedResponse__c qdr: lstQuestionDefinedResponse )
            {
                
                ServiceQuestionDefinedResponse__c sqdefResp = new ServiceQuestionDefinedResponse__c();
                sqdefResp.ServiceQuestion__c = sq.Id;
                sqdefResp.QuestionDefinedResponse__c =qdr.Id;
                //sqdefResp.DefinedResponseText__c = qdr.DefinedResponseText__c;
                sqdefResp.isActive__c=false;
                sqdefResp.CanRemove__c = false;
                lstSQDR.add(sqdefResp);
                
                
            } 
            
        }
        
        if(lstSQDR.size()>0)
        {
            insert lstSQDR;
        }
        
    }
    
}