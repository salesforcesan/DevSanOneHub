public with sharing class TargetRequest extends LightningRequestBase {
    
    public override Object filter(Object parameters) {
        String serviceId = parseServiceId(parameters);
        return filterTargets(serviceId);
    }

    String parseServiceId(Object parameters){
        Map<String,Object> query = (Map<String,Object>) parameters;
        return lightningRequestHelper.parseString(query.get('serviceId'));
    }

    List<List<String>> filterTargets(String serviceId){
        List<List<String>> rs = new List<List<String>>();
        List<String> r;
        for(ProjectServiceTarget__c t: [SELECT Target__c, TargetName__c FROM ProjectServiceTarget__c WHERE ProjectService__c = :serviceId]){
            r = new List<String>();
            r.add(t.Target__c);
            r.add(t.TargetName__c);
            rs.add(r);
        }
        return rs;
    }
}