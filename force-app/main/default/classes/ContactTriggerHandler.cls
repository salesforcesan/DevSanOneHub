public class ContactTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
        if (TriggerUtil.skipContactTrigger) return;
        system.debug('Inside Before Update');
        
        Set<string> managerids = new Set<string>();
        for (Contact ct: (List < Contact> ) Trigger.new) {
            managerids.Add(ct.ManagerId__c);
        }
        
        List<Contact> managersList = [Select id, name, ContactId__c from Contact where ContactId__c in :managerids];        
        
        Map<string, Contact> managersMap = new Map<string, Contact>();
        for (Contact ct: managersList)
        {
            managersMap.put(ct.ContactId__c, ct);
        }
        
        for (Contact ct: (List < Contact> ) Trigger.new) {
            Contact oldContact = (Contact) Trigger.oldMap.get(ct.Id);
            if (oldContact.ManagerId__c != ct.ManagerId__c)
            {
                Contact rptCont = managersMap.get(ct.ManagerId__c);
                if (rptCont != null)
                {
                    ct.ReportsToId = rptCont.Id;
                }
                else
                {
                    ct.ReportsToId = null;
                }
            }
            
            if(string.isNotEmpty(string.valueOf(ct.Pin__c)) &&  oldContact.Pin__c != ct.Pin__c)
            {
                ct.PinHash__c = generateMD5Pin(ct.Pin__c);
            }
            ct.Pin__c ='****';
            
        }
        
    }    
    
    public override void beforeInsert() {
        if (TriggerUtil.skipContactTrigger) return;
        
        Set<string> managerids = new Set<string>();
        for (Contact ct: (List < Contact> ) Trigger.new) {
            managerids.Add(ct.ManagerId__c);
        }
        
        List<Contact> managersList = [Select ContactId__c from Contact where ContactId__c in :managerids];        
        
        Map<string, Contact> managersMap = new Map<string, Contact>();
        for (Contact ct: managersList)
        {
            managersMap.put(ct.ContactId__c, ct);
        }
        
        
        for (Contact ct: (List < Contact> ) Trigger.new) {
            if (ct.ManagerId__c != null)
            {
                Contact rptCont = managersMap.get(ct.ManagerId__c);
                if (rptCont != null)
                {
                    ct.ReportsToId = rptCont.Id;
                }
            }
            
            
            // system.debug('pin value' +string.valueOf(ct.Pin__c));
            if(string.isNotEmpty(string.valueOf(ct.Pin__c)))
            {
                ct.PinHash__c = generateMD5Pin(ct.Pin__c);
            }
            ct.Pin__c ='****';
           
        }
        
        
    }
    private static String generateMD5Pin(String inputString){
        String algorithmName = 'MD5';
        Blob targetBlob = Blob.valueOf(inputString);
        Blob hash = Crypto.generateDigest(algorithmName, targetBlob);
        return EncodingUtil.convertToHex(hash);
    }     
}