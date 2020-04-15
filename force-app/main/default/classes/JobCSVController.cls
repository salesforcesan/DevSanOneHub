public without sharing class JobCSVController {
    
    @auraEnabled
    public static Map<String,Object> getJobImportSettings(){
        Map<String, Object> m = new Map<String,Object>();
        m.put('chunkSize', AppUtil.JobImportChunkSize);
        m.put('importColumnTitles', AppUtil.JobImportHeaderDefinition);

        return m;
    }

    @auraEnabled
    public static Integer getChunkSize(){
        return AppUtil.JobImportChunkSize;
    }

    @auraEnabled
    public static void rollbackImportJobs(string projectId){
        try{
            JobCSVModel.createInstance(projectId).deleteAttachments();                
        }
        catch(DmlException dml){
            throw new AuraHandledException(genDMLMessage(dml));
        }
        catch(AuraHandledException aura){
            throw aura;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }   
    }

    @auraEnabled
    public static void importJobs(String request)
    {
        try{
            JobImportRequest jobRequest = (JobImportRequest) JSON.deserialize(request, Type.forName('JobImportRequest'));
            JobCSVModel model = JobCSVModel.createInstance(jobRequest.ProjectId);

            if(jobRequest.StartImport == 1){
                model.startImport();
            }
            model.importJobs(jobRequest.Jobs);
            if(jobRequest.EndImport == 1){
                model.endImport();
            }
        }
        catch(DmlException dml){
            throw new AuraHandledException(genDMLMessage(dml));
        }
        catch(AuraHandledException aura){
            throw aura;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }
    }

    static string genDMLMessage(DmlException dml){
        List<String> msgs = new List<String>();
        for(Integer i=0; i < dml.getNumDml(); i++){
            msgs.add(dml.getDmlMessage(i));
        }
        return String.join(msgs, '. ');
    }
 
}