public with sharing class ProjectAccountModel {
    static final string OBJECT_TYPE = 'ProjectAccount__c';
    static final string FIELD_SET_NAME = 'default';

    String ProjectId {get;set;}

    FieldsetGetter  FieldsetGetterInstance {get;set;}

    private ProjectAccountModel(String id){
        FieldsetGetterInstance = FieldsetGetter.create(OBJECT_TYPE);
        this.ProjectId = id;
    }

    public static ProjectAccountModel create(string projectId){
        return new ProjectAccountModel(projectId);   
    }

    public List<Map<String,Object>> getList() {
        List<Map<String,Object>> rs = new List<Map<String,Object>>();
        
        Map<String,object> r;
      	Map<String,List<ProjectServiceTarget__c>> pstMap = new Map<String,List<ProjectServiceTarget__c>>();
        
        Map<String,List<ProjectServiceQuestion__c >> psqMap = new Map<String,List<ProjectServiceQuestion__c>>();        
        
        for(ProjectServiceTarget__c pst : LightningProjectServiceTargetsController.getProjectServiceTarget(this.ProjectId)){
             // for line item detail
                List<ProjectServiceTarget__c> pstList = new List<ProjectServiceTarget__c>();
                pstList.add(pst);
                
                if ( pstMap.get(pst.ProjectAccount__c) != null) {
                    pstList.addall(pstMap.get(pst.ProjectAccount__c));
                }
                pstMap.put(pst.ProjectAccount__c,pstList);   
        }

        for(ProjectServiceQuestion__c psq : [SELECT Id,Question__r.Account__c from ProjectServiceQuestion__c 
                                             Where ProjectService__r.Project__c =: this.ProjectId 
                                             AND Question__r.Account__c != null]){
             // for line item detail
                List<ProjectServiceQuestion__c> psqList = new List<ProjectServiceQuestion__c>();
                psqList.add(psq);
                
                if (psqMap.get(psq.Question__r.Account__c) != null) {
                    psqList.addall(psqMap.get(psq.Question__r.Account__c));
                }
                psqMap.put(psq.Question__r.Account__c,psqList);   
        }
                   

        for(ProjectAccount__c acct: getAccounts()){
            r = new Map<String,Object>();
            r.put('id', acct.Id);
            r.put('accountId', acct.Account__c);
            r.put('isPrimary', acct.IsPrimary__c);
            r.put('projectStatus', acct.Project__r.Status__c);
            r.put('canSetPrimary', !UIConfig.checkFieldHidden(acct.Project__r.Status__c, 'ProjectAccount__c.Primary'));
            r.put('canDelete', !UIConfig.checkFieldHidden(acct.Project__r.Status__c, 'ProjectAccount__c.Delete'));
            r.put('title', FieldsetGetterInstance.getTitle(acct));
            r.put('fieldset', FieldsetGetterInstance.getNameValueList(acct));
            r.put('hasServiceTarget', pstMap.containsKey(acct.Id));
            r.put('hasAccountSpecificServiceQuestion',psqMap.containsKey(acct.Account__c));
            
            rs.add(r);
        }

        return rs;
    }

    List<ProjectAccount__c> getAccounts(){
        String id = this.ProjectId;
        String sql = FieldSetQueryBuilder.create(OBJECT_TYPE)
            .addAdditionalFields(new String[]{'Account__c','IsPrimary__c','Project__r.Status__c'})
            .addPredicates(new String[]{ 'Project__c=:id Order By IsPrimary__c DESC' })
            .build(FieldsetGetterInstance.getFieldsetDefinition(FIELD_SET_NAME));
        return Database.query(sql);
    }
}