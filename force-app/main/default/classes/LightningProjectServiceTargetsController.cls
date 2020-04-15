public class LightningProjectServiceTargetsController {
    @AuraEnabled
    public static List<ProjectServiceTargetWrapper> GetProjectServiceTargets(String projectServiceId) {
        List<ProjectServiceTarget__c> targets = [SELECT Name, Id, ProjectService__c, target__r.AccountInfo__c,
                                      TargetName__c, target__r.ImageURL__c, Quantity__c, Visibility__c, TargetDescription__c,
                                      TargetUPC__c, Target__r.StockCode__c, TargetStockCode__c, Type__c, Account__c,
                                      ProjectAccount__c, ProjectAccount__r.AccountName__c, sortorder__c,
                                      ProjectService__r.Project__r.Status__c, ProjectService__r.TargetType__c
                                      FROM ProjectServiceTarget__c
                                      WHERE projectService__c = :projectServiceId Order by sortorder__c];

        List<ProjectServiceTargetWrapper> projectServiceTargets = new List<ProjectServiceTargetWrapper>();
        for (ProjectServiceTarget__c serviceTarget : targets) {
            projectServiceTargets.add(new ProjectServiceTargetWrapper(serviceTarget));
        }

        return projectServiceTargets;
    }

    @AuraEnabled
    public static boolean ProjectTypeInfo(string projId) {
        project__C proj =  [SELECT ProjectType__r.IsProjectAccountMandatory__c FROM Project__c where id = : projId limit 1];
        return proj.ProjectType__r.IsProjectAccountMandatory__c;
    }

    @AuraEnabled
    public static boolean ProjectTypeInfoDetail(string projId) {
        project__C proj =  [SELECT ProjectType__r.IsProjectAccountMandatory__c FROM Project__c where id = : projId limit 1];
        return proj.ProjectType__r.IsProjectAccountMandatory__c;
    }


    //there are two scenarios to check
    //scenario 1: there are no targets: in this case, make sure that to-be added targets have the same target type.
    //scenario 2: there are at least one target: in this case, make sure that 
    //to-be added targets have the same target type as the existed target

    @testvisible
    static String genTargetTypeError(String expectedType) {
        String message = 'The targets with the different target types are not allowed.';

        if (String.isNotBlank(expectedType)){
            return message + ' The expected target type is ' + expectedType;
        }

        return message;
    }
    @testVisible
    static void ensureOneTargetTypePolicy(List<ProjectServiceTarget__c> existedTargets, List<Target__c> newTargets){
        if (newTargets.isEmpty()){return;}

        String expectedType = existedTargets.isEmpty()
            ? ''
            : existedTargets[0].ProjectService__r.TargetType__c;

        
        Set<String> types = new Set<String>();
        for(Target__c t: newTargets){
            if (t.RecordType == null || String.isBlank(t.RecordType.Name)){
                throw new AuraHandledException('The target ' + t.name + ' has no recordtype specified.');
            }
            types.add(t.RecordType.Name);
        }

        if (types.size() != 1) {
            throw new AuraHandledException(
                genTargetTypeError(expectedType));
        }

        if (String.isNotBlank(expectedType) && !types.contains(expectedType)){
            throw new AuraHandledException(
                genTargetTypeError(expectedType)
                );
        }
    }

    @AuraEnabled
    public static List<string> AddTargets(String searchIds, string projectServiceId, string targetUseType, string projectAccountId, string projectId) {

        Set<String> uniqueList = (Set<String>)JSON.deserialize(searchIds, Set<String>.class);
        
        //step 1 get existed targets
        List<ProjectServiceTarget__c> existingServiceTargets = [
            SELECT 
                Id, 
                Target__c, 
                ProjectService__r.TargetType__c 
            FROM ProjectServiceTarget__c
            WHERE projectService__c = :projectServiceId];

        //step 2 get list of the existed targets
        List<Id> existingTargets = new List<Id>();
        for (ProjectServiceTarget__c pst : existingServiceTargets) {
            existingTargets.add(pst.Target__c);
        }

        //step 3 get targets that are not in the existed target list
        list<Target__c> targetList = [
            SELECT 
                Name, 
                Id, 
                UPC__c, 
                description__c, 
                ImageUrl__c, 
                status__c,
                RecordType.Name,
                StockCode__c, 
                AccountInfo__c
              FROM Target__c
              WHERE ( UPC__c in :uniqueList or StockCode__c in :uniqueList or Id in :uniqueList )
              AND Id not in :existingTargets
              AND Status__c = 'Active'];


        //Integer sortCounter = (Integer)existingServiceTargets.clone().size();
        integer sortCounter = 0;
        List<AggregateResult> res = [select max(sortorder__c) maxval
                                     from ProjectServiceTarget__c
                                     where ProjectService__c = :projectServiceId];

        if (res != null)
            sortCounter = res[0].get('maxval') != null ? Integer.valueof(res[0].get('maxval')) : 0;

        if (string.isEmpty(projectAccountId)) { projectAccountId = null;}
        List<ProjectServiceTarget__c> projectServiceTargetList = new List<ProjectServiceTarget__c>();
        List<Target__c> newTargetList = new List<Target__c>();
        for (String idInUnique : uniqueList) {
            for (Target__c targ : targetList) {
                if (string.valueOf(targ.Id) == idInUnique || string.valueOf(targ.StockCode__c) == idInUnique || string.valueOf(targ.UPC__c) == idInUnique) {
                    newTargetList.add(targ);
                }
            }
        }

        ensureOneTargetTypePolicy(existingServiceTargets, newTargetList);

        for (Target__c target : newTargetList) {
            sortCounter = sortCounter + 1;
            ProjectServiceTarget__c newProjectServiceTarget = new ProjectServiceTarget__c(ProjectService__c = projectServiceId,
                    Target__c = target.Id,
                    sortorder__c = sortCounter,
                    Type__c = targetUseType,
                    ProjectAccount__c = projectAccountId,
                    Project__c = projectId
                                                                                         );
            projectServiceTargetList.add(newProjectServiceTarget);
        }

        // To get all invalid search Id's
        List<String> idsNotFoundOrAlreadyExist = new List<String>();

        for (String searchId : uniqueList) {

            for (Target__c target : targetList) {

                //string.valueOf(target.Id) != searchId && target.UPC__c != searchId &&
                //
                if ( target.StockCode__c != searchId ) {
                    idsNotFoundOrAlreadyExist.add(searchId);
                }
            }
        }

        insert projectServiceTargetList;

        return idsNotFoundOrAlreadyExist;

    }


    
    @AuraEnabled
    public static string UpdateTargets(string projectServiceTargetWrapperList) {
        if (string.isEmpty(projectServiceTargetWrapperList)) {return null;}
        ResponseWrapper rw;
        try {
            List<ProjectServiceTargetWrapper> parsedList = (List<ProjectServiceTargetWrapper>) JSON.deserialize(projectServiceTargetWrapperList, List<ProjectServiceTargetWrapper>.class);
            List<ProjectServiceTarget__c> projectServiceTargetList = new List<ProjectServiceTarget__c>();
            for (ProjectServiceTargetWrapper p : parsedList) {
                ProjectServiceTarget__c psTarget = new ProjectServiceTarget__c();
                if (!string.isEmpty(p.ProjectAccountId)) {
                    psTarget.ProjectAccount__c = p.ProjectAccountId;
                }
                psTarget.Id = p.ProjectServiceTargetId;
                if (!string.isEmpty(p.TargetUse)) {
                    psTarget.Type__c = p.TargetUse;
                }
                projectServiceTargetList.add(psTarget);
            }
            system.debug('targets: ' + projectServiceTargetList);

            update projectServiceTargetList;
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully updated the target(s)', 'SUCCESS');

        } catch (Exception e) {
            System.debug(e);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to update target. ' + e.getMessage(), 'ERROR');
        }
        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static string RemoveProjectServiceTargets(List<String> projectServiceTargetIdList) {
        if (projectServiceTargetIdList == null ) {
            return null;
        }
        ResponseWrapper rw;
        List<ProjectServiceTarget__c> projectServiceTarget = [Select Id from ProjectServiceTarget__c where id in : projectServiceTargetIdList ];

        try {
            if (projectServiceTarget != null ) {
                delete projectServiceTarget;
            }

            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully deleted target from project', 'SUCCESS');
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Unable to delete target. ' + dmlEx.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete target. ' + e.getMessage());
        }

        return JSON.serialize(rw);
    }

    @AuraEnabled
    public static string GetTargetAccounts(String projectId) {
        if (projectId == null) {
            return null;
        }
        List<ProjectAccount__c> targetAccounts = [Select Id, Name, AccountName__c from ProjectAccount__c where Project__c = : projectId];

        String ta = JSON.serialize(targetAccounts);
        String tac = ta.replace('__c', '');

        String tas = tac.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');
        return tas;
    }

    @AuraEnabled
    public static list<String> GetTargetTypes() {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Target__c;
        Map<Id, Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();

        Set<String> TargetRecordTypes = new Set<String>();
        for (Schema.RecordTypeInfo i : rtMapById.values()) {
            if (!i.isMaster() & i.isAvailable()) {
                TargetRecordTypes.Add(i.getName());
            }
        }
        //OH-2692 - make product default choice
        if (TargetRecordTypes.contains('Product')) {
            TargetRecordTypes.remove('Product');
        }
        List<String> targetTypes = new List<String>();
        targetTypes.add('Product');
        targetTypes.addAll(TargetRecordTypes);
        return targetTypes;
    }

    @AuraEnabled
    public static list<ProjectServiceTarget__c> getProjectServiceTarget(String projectId) {
        if (projectId == null) {
            return null;
        }

        List<ProjectServiceTarget__c> projectServiceTargets = [Select Id, Target__c, ProjectAccount__c
                From ProjectServiceTarget__c
                where ProjectAccount__r.Project__c = : projectId
                        And ProjectAccount__c != null];
        return projectServiceTargets;
    }

    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }

    @AuraEnabled
    public Static List<String> GetTargetUseTypes(String projectServiceId) {
        System.debug('psId to get USETYPES: ' + projectServiceId);
        List<String> lstUseTypes = new List<String>();
        List<ProjectService__c> existingServiceTargets = [SELECT Id, TargetUse__c FROM ProjectService__c WHERE Id = :projectServiceId];
        if (existingServiceTargets.size() > 0) {
            string targetuses  = string.ValueOf(existingServiceTargets[0].TargetUse__c);

            if (!string.isEmpty(targetuses)) {
                integer x = targetuses.indexOf(';');
                if (x != -1) {
                    lstUseTypes.addAll(targetuses.split(';'));
                } else {
                    lstUseTypes.add(targetuses);
                }
            }

        }
        System.debug('use types: ' + lstUseTypes);
        return lstUseTypes;

    }
}