public class cdlinkTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        if (TriggerUtil.skipCDLinkTrigger) return;
        Schema.DescribeSObjectResult inv = Opportunity.sObjectType.getDescribe();
        String invKeyPrefix = inv.getKeyPrefix(); 
        system.debug('invKeyPrefix:::' + invKeyPrefix);
        
        if(trigger.isInsert){
            map<string,string> ContentDocumentLinkMap = new map<string,string>();
            for(ContentDocumentLink a :(List<ContentDocumentLink> )trigger.new){
                
                if(invKeyPrefix == String.valueOf(a.LinkedEntityId).left(3))
                {
                    ContentDocumentLinkMap.put(a.LinkedEntityId,a.ContentDocumentId);
                    a.ShareType = 'I';
                    
                }
                
            }
            
            if(ContentDocumentLinkMap.size()>0)
            {
                List<Project__c> lstProjects = [SELECT Id,name,Opportunity__c FROM Project__c WHERE Opportunity__c = :ContentDocumentLinkMap.keySet()];
                
                if(lstProjects.size() >0 )
                {
                    List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
                    for(Project__c p  :lstProjects)
                    {
                        
                        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = p.Id, ContentDocumentId = ContentDocumentLinkMap.get(p.Opportunity__c) ,ShareType ='I');
                        cdList.add(cdl);
                        
                    }
                    
                    if(cdList.size() > 0){
                        insert cdList;
                    }
                }
                
            }
        }
    }
    
}