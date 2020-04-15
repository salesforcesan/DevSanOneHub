public class ProjectInvoiceLineItemTriggerHandler  extends TriggerHandler {
    
    public override void beforeInsert(){
        
        Set<String> piids = new Set<String>();
        Map<String, Integer> pimaxitemsmap = new Map<String, Integer>();       
        
        
        if (TriggerUtil.skipProjectInvoiceLineItemTrigger) return;
        
        for(ProjectInvoiceLineItem__c pili :(List<ProjectInvoiceLineItem__c> )Trigger.new){
        
            piids.add(pili.ProjectInvoice__c);
        }        
        List<ProjectInvoice__c> pis = [SELECT Id, Name, NumberOfLineItems__c FROM ProjectInvoice__c 
                                       WHERE ID IN :piids FOR UPDATE];
        for (ProjectInvoice__c pi : pis)
        {
            pimaxitemsmap.put(pi.Id, Integer.valueof(pi.NumberOfLineItems__c));
        }
        for(ProjectInvoiceLineItem__c pili :(List<ProjectInvoiceLineItem__c> )Trigger.new){
            Integer maxno = 0;
            if (pimaxitemsmap.get(pili.ProjectInvoice__c) != null)
                maxno = pimaxitemsmap.get(pili.ProjectInvoice__c);
            pili.LineItemOrder__c = maxno + 1;
            pimaxitemsmap.put(pili.ProjectInvoice__c, maxno + 1);
        }        
    }
        
    
}