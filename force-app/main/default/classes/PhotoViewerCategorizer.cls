global with sharing class PhotoViewerCategorizer {
    List<JobImage__c> dataset;
    IAIImageClassifier classifier;

    private PhotoViewerCategorizer(IAIImageClassifier classifier, List<JobImage__c> scope) {
        this.dataset = new List<JobImage__c>(scope);
        this.classifier = (scope.size() > 0) ? classifier : null;
    }

    global static PhotoViewerCategorizer create(IAIImageClassifier classifier, List<JobImage__c> scope) {
        return new PhotoViewerCategorizer(classifier, scope);
    }

    global void run() {
        if (this.classifier == null) {
            return;
        }
        List<JobImage__c> images = new List<JobImage__c>();
        for (JobImage__c img : this.dataset) {
            try {
                Map<String, Double> result = this.classifier.predict(img.AIImageUrl__c);

                images.add(new JobImage__c(
                    id = img.Id,
                    isClassified__c = true,
                    classifiedLabel__c = this.findLikelyLabel(result),
                    ClassifiedResponse__c = JSON.serialize(result)
                ));
            } catch (Exception ex) {

                images.add(new JobImage__c(
                    id = img.Id,
                    IsErrored__c = true,
                    ErrorMessage__c = ex.getMessage()
                    ));
            }
        }
        if (images.size() > 0) {
            update images;
        }
    }


    private String findLikelyLabel(Map<String, Double> result) {
        Double max = 0.0;
        String maxLabel = '';
        for(String label: result.keySet()){
            Double val = Double.valueOf(result.get(label));
            if (val > max) {
                max = val;
                maxLabel = label; 
            }
        }
        return maxLabel;
    }
}