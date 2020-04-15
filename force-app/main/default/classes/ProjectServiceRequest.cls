public with sharing class ProjectServiceRequest extends LightningRequestBase {
    String AppUsage {get;set;}

    public override Object filter(Object parameters) {
        String projectId = parseProjectId(parameters);
        this.AppUsage = getParamString(parameters, 'usage');

        if(isCommunityRequest() && isSecurityAccessOverride(projectId)){
            return getAccessServices(projectId);
        }

        return getServices(projectId);
    }

    Boolean isCommunityRequest(){
        return (this.AppUsage == 'Community Viewer' || this.AppUsage == 'Retailer')
            ? true: false;
    }

    String getParamString(Object parameters, String key){
        Map<String,object> query = (Map<String,Object>) parameters;
        return LightningRequestHelper.parseString(query.get(key));
    }

    String parseProjectId(Object parameters){
        Map<String,object> query = (Map<String,Object>) parameters;
        String projectId = LightningRequestHelper.parseString(query.get('projectId'));
        
        if(String.isEmpty(projectId)){
            throw new AuraHandledException('The project id is not specified.');
        }

        return projectId;
    }

    List<List<String>> getServices(String projectId){
        List<String> item;
        List<List<String>> result = new List<List<String>>();
        
        for(ProjectService__c ps: [SELECT Id, Title__c FROM ProjectService__c WHERE Project__c=:projectId]){
            item = new List<String>();
            item.add(ps.Id);
            item.add(ps.Title__c);
            result.add(item);
        }
        return result;
    }

    List<List<String>> getAccessServices(String projectId){
        List<String> item;
        List<List<String>> result = new List<List<String>>();
        String accountId = AppUtil.getUserAccountId();

        for(ProjectService__c ps: [SELECT Id, Title__c FROM ProjectService__c WHERE Project__c=:projectId AND Id in (SELECT ProjectService__c FROM ProjectAccountServiceAccess__c WHERE Project__c=:projectId AND ProjectAccount__r.Account__c=:accountId)]){
            item = new List<String>();
            item.add(ps.Id);
            item.add(ps.Title__c);
            result.add(item);
        }
        return result;
    }

    Boolean isSecurityAccessOverride(String projectId){
        Project__c p = [SELECT OverrideAccountAndServiceAccess__c FROM Project__c WHERE Id=:projectId LIMIT 1];
        return (p != null && p.OverrideAccountAndServiceAccess__c == true) ? true : false;
    }
}