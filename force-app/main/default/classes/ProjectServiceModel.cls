public with sharing class ProjectServiceModel {

    ProjectService__c ProjectService {get; private set;}
    Map<Id, ProjectServiceAttribute__c> ProjectServiceAttributes {get; private set;}

    private ProjectServiceModel(String projectServiceId) {
    	this.ProjectService = getProjectService(projectServiceId);
        this.getAttributes(projectServiceId);
    }

    private void getAttributes(String projectServiceId) {
        String psQuery = QueryUtil.FetchQuery('ProjectServiceAttribute__c') + ' WHERE ProjectService__c = :projectServiceId order by Name';
        this.ProjectServiceAttributes = new Map<Id, ProjectServiceAttribute__c>((List<ProjectServiceAttribute__c>)Database.query(psQuery));
    }

    private ProjectServiceModel(){
        this.ProjectServiceAttributes = new Map<Id, ProjectServiceAttribute__c>();
    }

    public static ProjectServiceModel get(String recordId) {
        return new ProjectServiceModel(recordId);
    }

    public static ProjectServiceModel create(){
        return new ProjectSErviceModel();
    }


    static ProjectService__c getProjectService(String projectServiceId){
        return Database.query(QueryUtil.FetchQuery('ProjectService__c') + ' WHERE Id = :projectServiceId order by Name');
    }

    
    public void updateAttachments(String recordIds){
         if(String.isBlank(recordIds)) return;

        List<string> attrList = recordIds.split(',');
        Set<String> attrSet = new Set<String>(attrList);
        list<Attachment> ObjList = [SELECT Id, Name, Description, OwnerId, ContentType, ParentId FROM Attachment where id in:attrSet];

        for(Attachment obj:ObjList){
            //delete [select id from attachment where parentid=:obj.ParentId and id !=: obj.id];
            ProjectServiceAttribute__c objPSA = ProjectServiceAttributes.get(obj.ParentId);
            objPSA.AttributeValue__c = string.valueOf(obj.Id) ;
            objPSA.AttchFileName__c = obj.Name;

            GenerateURL.GenerateNewURL(obj.ParentId ,Obj.id);

            if(objPSA.Description__c ==CONSTANTS.MANUAL){
                ProjectService.isManualGenInProgress__c=true;
            }
        }
    }
    

    public void doUpdate(ProjServiceWrapper wrapper, String attachmentIds, String attachmentIdsForDelete) {
        Savepoint saveLock = Database.setSavePoint();
        try {
            updateService(wrapper);
            resetSelectedAttributes(attachmentIdsForDelete);
            handleServiceWithoutManual();
            updateAttachments(attachmentIds);
            updateAttributes(wrapper.AvlPSA);
            commitChanges();
        } catch(Exception ex){
            Database.rollback(saveLock);
            Throw ex;
        } 
    }

    void commitChanges(){
        Database.SaveResult sr = Database.update(this.ProjectService);
        if(!sr.isSuccess()){
            throw new CustomException(AppUtil.genSaveResultError(sr));
        }

        Database.SaveResult[] srList = Database.update(this.ProjectServiceAttributes.values());
        String error = AppUtil.genSaveResultListError(srList);
        if(!String.isEmpty(error)) {
            throw new CustomException(error);
        }
    }

    void updateService(ProjServiceWrapper wrapper){
        ProjectService.JobManual__C = wrapper.JobManualTemplate;
        if(wrapper.JobManualTemplate==CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE ){
            if(ProjectService.JobManualURL__c==null){
                ProjectService.JobManualURL__c ='';
            }
            ProjectService.JobManualFileName__c ='';
            ProjectService.IncludeAutoGenManual__c = true;
            ProjectService.isManualGenInProgress__c  = false;
        }
        else{
            ProjectService.IncludeAutoGenManual__c = false;
        }
    }

    void resetSelectedAttributes(String recordIds){
            if(String.isBlank(recordIds)) return;

            ProjectServiceAttribute__c obj;
            List<string> idSet = RecordIds.split(',');
            List<String> attachmentIdSet = new List<String>();

            for(String recordId: idSet){
                if (!this.ProjectServiceAttributes.containsKey(recordId)) continue;
                obj = this.ProjectServiceAttributes.get(recordId);
                Set<String> s1 = new Set<String>();
                s1.add(string.valueof(obj.AttributeValue__c).substringBefore('='));
                obj.AttributeValue__c = null;
                obj.AttachmentExt__c = null;
                obj.AttachmentURL__c = null;
                obj.AttchFileName__c = null;

                //cache for bulk delete
                attachmentIdSet.add(string.valueof(obj.AttributeValue__c).substringBefore('='));
            }

            deleteAttachments(attachmentIdSet);
    }


    void deleteAttachments(List<String> idSet){
        if(idSet.size() == 0) return;

        List<Attachment> attachments = [
            select id from attachment where id in :idSet];
        if(attachments.size() > 0){
            delete attachments;
        }
    }


    void updateAttributes(list<PSAttributeWrapper> attributesWrapper){
        ProjectServiceAttribute__c objPSA;
        List<String> psaRecordIdSet = new List<String>();

        for(PSAttributeWrapper psa: attributesWrapper){
            if(psa.AttributeType!='Photo'){
                objPSA = ProjectServiceAttributes.get(psa.RecordID);
                objPSA.AttributeValue__c =  psa.AttributeValue;
            }

            if(psa.Attributename==CONSTANTS.MANUAL && 
                ProjectService.JobManual__C != CONSTANTS.JOB_MANUAL_CUSTOM_TEMPLATE ){
                psaRecordIdSet.add(psa.RecordID);
            }
        }
        resetSelectedAttributes(String.join(psaRecordIdSet, ','));
    }

    public void handleServiceWithoutManual()
    {        
        ProjectService.JobManualURL__c = '';
        for(ProjectServiceAttribute__c psAttr: this.ProjectServiceAttributes.values()){
            if(psAttr.AttributeTitle__c == CONSTANTS.MANUAL){
                psAttr.AttributeValue__c = null;
                psAttr.AttachmentExt__c = null;
                psAttr.AttachmentURL__c = null;
                psAttr.AttchFileName__c = null;
            }
        }
        
    }

    public void doInsert(ProjServiceWrapper wrapper){

    }
}