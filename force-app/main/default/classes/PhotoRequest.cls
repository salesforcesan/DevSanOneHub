public with sharing class PhotoRequest extends LightningRequestBase {

    public override Object get(Object parameters){
        String jobImageId = getJobImageId(parameters);
        validateId(jobImageId);
        return this.getOneImageDetail(jobImageId);
    }

    public override Object filter(Object parameters) {
        List<String> idSet = this.parseJobImageIds(parameters);
        return this.getImageDetails(idSet);
    }

    public override Object modify(Object parameters){
        String jobImageId = getJobImageId(parameters);
        validateId(jobImageId);

        JobImage__c img = getJobImage(jobImageId);
        if(hasParameter(parameters, 'favorite')){
            boolean favorite = getBoolean(parameters, 'favorite');
            String usage = getString(parameters, 'usage');
            String favoriteClause;

            if(isCommunitySite(usage)) {
                img.IsUserFavorite__c = favorite;
                favoriteClause = 'IsUserFavorite__c = true';
            } else{
                img.IsFavorite__c = favorite;
                favoriteClause = 'IsFavorite__c = true';                
            }

            if(favorite){
                validateMarkFavorite(jobImageId, favoriteClause);
            }
        }

        if(hasParameter(parameters, 'qc')){
            img.PoorQualityCheck__c = getBoolean(parameters, 'qc');
        }

        Database.SaveResult result = Database.update(img);
        if(!result.isSuccess()){
            throw new AuraHandledException(AppUtil.genSaveResultError(result));
        }
        return this.getOneImageDetail(jobImageId);
    }

    boolean isCommunitySite(String usage){
        return usage == 'Retailer' || usage == 'Community Viewer';
    }

    @testvisible
    void validateMarkFavorite(String currentImageId, string favoriteClause){
        integer maxCount = AppUtil.MaxFavoritePhotoCount;
        JobImage__c img = getJobImage(currentImageId);

        if(img == null || string.isBlank(img.Project__c)){
            throw new AuraHandledException(img == null ? 'The photo record is not found.' : 'The photo record does not have project identifier.');
        }

        string projectId = img.Project__c;
        integer count = Database.countQuery('SELECT COUNT() FROM JobImage__c Where Project__c=:projectId AND ' + favoriteClause + ' AND Id != :currentImageId');
        if(count >= maxCount) {
            throw new AuraHandledException('The maximum number of favorite photos is reached.');
        }
    }

    JobImage__c getJobImage(String id){
        return [SELECT Id, Project__c FROM JobImage__c WHERE Id=:id LIMIT 1];
    }

    @testvisible
    void validateId(String jobImageId){
        if (String.isBlank(jobImageId))
        {
            throw new AuraHandledException('The Photo Id is required when retrieving the photo detail.');
        }
    }

    @testvisible
    List<String> parseJobImageIds(Object parameters){
        Map<String,Object> query = (Map<String,Object>)parameters;
        return LightningRequestHelper.parseArrayOfString(query.get('ids'));
    }


    @testvisible
    String getJobImageId(Object parameters){
        Map<String,object> query = (Map<String,Object>) parameters;
        return LightningRequestHelper.parseString(query.get('id'));
    }

    @testvisible
    boolean hasParameter(Object parameters, String parameterId){
        Map<String,Object> query = (Map<String,Object>) parameters;
        return query.get(parameterId) != null;
    }

    @testvisible
    boolean getBoolean(Object parameters,String parameterId){
        Map<String,Object> query = (Map<String,Object>) parameters;
        String flag = LightningRequestHelper.parseString(query.get(parameterId));
        return flag == '1' ? true : false;
    }

    String getString(Object parameters, String parameterId){
        Map<String,Object> query = (Map<String,Object>) parameters;
        return LightningRequestHelper.parseString(query.get(parameterId));
    }

    Map<String,Object> getOneImageDetail(String imageId){
        List<Map<String,Object>> result = this.getImageDetails(new List<String>{imageId});
        return result.size() > 0 ? result[0]: new Map<String,Object>();
    }

    @testvisible
    List<Map<String,Object>> getImageDetails(List<String> idSet){
        List<Map<String,Object>> resList = new List<Map<String,Object>>();
        Map<String,Object> res;
        String url;

        List<JobImage__c> images = [SELECT Id, Question__r.Name, Question__r.QuestionText__c, IsFavorite__c, PoorQualityCheck__c, ImageUrl__c, CloudinaryImageUrl__c, IsDuplicated__c, PhotoHash__c, JobAttempt__r.ReportedContactFirstName__c,JobAttempt__r.ReportedContactLastName__c, Project__r.Name, Project__r.ProjectNumber__c, ProjectService__r.ServiceTitle__c, ProjectLocation__r.LocationName__c, JobDateReported__c, ProjectLocation__r.City__c, ProjectLocation__r.State__c, ProjectLocation__r.LocationNumber__c, Target__r.Name, ParentLocation__r.Name, IsUserFavorite__c, Project__r.StartDate__c, Project__r.EndDate__c, IsErrored__c, ErrorMessage__c, JobAttempt__r.ECAttemptId__c FROM JobImage__c WHERE Id IN :idSet];
        
        RegExEngine regEx = RegExEngine.createInstance(RegExEngine.UrlPattern);
        for(JobImage__c ph: images){
            res = new Map<String,Object>();
            res.put('id', ph.Id);
            res.put('title', ph.Question__r.Name);
            res.put('question', ph.Question__r.QuestionText__c);
            if (regEx.matches(ph.ImageUrl__c)){
                res.put('url', ph.ImageUrl__c);
                res.put('url1', ph.CloudinaryImageUrl__c);
            } else {
                res.put('url','');
            }

            res.put('externalId', ph.JobAttempt__r.ECAttemptId__c);
            res.put('project', ph.Project__r.Name);
            res.put('projectNumber', ph.Project__r.ProjectNumber__c);
            res.put('service', ph.ProjectService__r.ServiceTitle__c);
            res.put('target', ph.Target__r.Name);
            res.put('location',ph.ProjectLocation__r.LocationName__c);
            res.put('locationNumber', ph.ProjectLocation__r.LocationNumber__c);
            res.put('banner', ph.ParentLocation__r.Name);
            res.put('city', ph.ProjectLocation__r.City__c);
            res.put('duplicated', ph.IsDuplicated__c ? 1:0);
            res.put('hash', ph.PhotoHash__c);
            res.put('state', ph.ProjectLocation__r.State__c);
            res.put('repName', genRepName(ph.JobAttempt__r.ReportedContactFirstName__c,ph.JobAttempt__r.ReportedContactLastName__c));
            res.put('favorite', ph.IsFavorite__c ? 1 : 0);
            res.put('userFavorite', ph.IsUserFavorite__c ? 1 : 0);
            res.put('qc', ph.PoorQualityCheck__c ? 1 : 0);
            res.put('photoDate', formatDatetime(ph.JobDateReported__c));
            res.put('startDate', formatDate(ph.Project__r.StartDate__c));
            res.put('endDate', formatDate(ph.Project__r.EndDate__c));
            res.put('error', ph.IsErrored__c ? 1 : 0);
            res.put('message',ph.ErrorMessage__c != null ? ph.ErrorMessage__c  : '');
            resList.add(res);
        }

        return resList;
    }

    String formatDate(Date dt){
        return (dt != null) ? dt.format(): '';
    }

    String formatDatetime(Datetime dttm){
        return (dttm != null) ? dttm.format('M/d/yyyy h:mm a', 'America/Chicago') : '';
    }

    @testvisible
    String genRepName(String firstName, string lastName){
        List<String> names = new List<String>();
        if(String.isNotEmpty(firstName)){
            names.add(firstName);
        }
        if(String.isNotEmpty(lastName)){
            names.add(lastName);
        }
        return String.join(names, ', ');
    }
}