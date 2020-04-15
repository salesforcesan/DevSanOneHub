public with sharing class PhotoViewerWordExporterController {

    public List<Map<String,Object>> Photos {get;set;}

    public PhotoViewerWordExporterController() {
        try{
            String images = ApexPages.currentPage().getParameters().get('images');
            this.Photos = this.shapeData(this.getPhotos(parseImageIds(images)));
        } catch(Exception ex){
            system.debug(ex.getStackTraceString());
        }

    }

    List<Map<String,Object>> shapeData(List<JobImage__c> images){
        List<Map<String,Object>> results = new List<Map<String,Object>>();
        for(JobImage__c img: images) {

            results.add(
                new Map<String,Object> {
                'questionName' => normalizeValue(img.Question__r.Name),
                'questionText' => normalizeValue(img.Question__r.QuestionText__c),
                'isFavorite' => normalizeValue(img.IsFavorite__c),
                'isPoorQuality' => normalizeValue(img.PoorQualityCheck__c),
                'imageUrl' => normalizeValue(img.CloudinaryImageUrl__c),
                'projectTitle' => normalizeValue(img.Project__r.Name),
                'reportDate' => formatDatetime(img.JobDateReported__c),
                'banner' => normalizeValue(img.ParentLocation__r.Name),
                'locationName' => normalizeValue(img.ProjectLocation__r.LocationName__c),
                'locationNumber' => normalizeValue(img.ProjectLocation__r.LocationNumber__c),
                'targetName' => normalizeValue(img.Target__r.Name),
                'serviceTitle' => normalizeValue(img.Job__r.ProjectService__r.ServiceTitle__c),
                'state' => normalizeValue(img.ProjectLocation__r.State__c),
                'city' => normalizeValue(img.ProjectLocation__r.City__c),
                'city_state' => normalizeValue(img.ProjectLocation__r.City__c) + ', ' + normalizeValue(img.ProjectLocation__r.State__c),
                'startDate' => formatDate(img.Project__r.StartDate__c),
                'endDate' => formatDate(img.Project__r.EndDate__c)
                });
        }

        return results;
    }

    String formatDate(Date dt){
        return (dt != null) ? dt.format(): '';
    }

    Object normalizeValue(Object val){
        return val != null ? val : '';
    }

    Set<Id> parseImageIds(String images){
        String[] ids = images.split(',');
        Set<Id> idSet = new Set<Id>();

        for(String v: ids){
            idSet.add(Id.valueOf(v));
        }

        return idSet;
    }

    String formatDatetime(Datetime dttm){
        return (dttm != null) ? dttm.format('M/d/yyyy h:mm a', 'America/Chicago'): '';
    }

    List<JobImage__c> getPhotos(Set<Id> imageIds){
        return [SELECT Id, Question__r.Name, Question__r.QuestionText__c, IsFavorite__c, PoorQualityCheck__c, CloudinaryImageUrl__c,  Project__r.Name, Job__r.ProjectService__r.ServiceTitle__c, ProjectLocation__r.LocationName__c, ProjectLocation__r.LocationNumber__c, JobDateReported__c , ProjectLocation__r.City__c, ProjectLocation__r.State__c, Target__r.Name, ParentLocation__r.Name, Project__r.StartDate__c, Project__r.EndDate__c FROM JobImage__c WHERE Id in :imageIds Order By SystemModstamp DESC];
    }

}