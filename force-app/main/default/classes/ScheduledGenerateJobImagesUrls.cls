global class ScheduledGenerateJobImagesUrls implements Schedulable{
    public static String CRON_EXP = '0 15 * * * ?';
    global static String schedule() {
        ScheduledGenerateJobImagesUrls sch = new ScheduledGenerateJobImagesUrls();
        return System.schedule('Generate JobImages Urls', CRON_EXP, sch);
    } 
    global void execute(SchedulableContext sc) {
              
       list<JobImage__c> lstjobImages = JobImageHandler.getJobImages();
  	   JobImageHandler.InvokeBatchJobImages(lstjobImages);
   
    }
    
}