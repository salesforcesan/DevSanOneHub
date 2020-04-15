global class ScheduledPhotoViewerClassifier implements Schedulable {
    public static String CRON_EXP = '0 5 * * * ?';
    
    global static String schedule() {
        ScheduledPhotoViewerClassifier sch = new ScheduledPhotoViewerClassifier();
        return System.schedule('ShelfDisplay Photo Classifier', CRON_EXP, sch);
    }

    global void execute(SchedulableContext sc) {
        PhotoViewerCategorizerHandler handler = new PhotoViewerCategorizerHandler();
        Database.executeBatch(handler, AIAccessTokenProvider.getBatchSize());
    }
}