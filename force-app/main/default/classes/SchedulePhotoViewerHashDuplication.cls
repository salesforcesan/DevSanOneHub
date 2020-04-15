global class SchedulePhotoViewerHashDuplication  implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        SchedulePhotoViewerHashDuplication sch = new SchedulePhotoViewerHashDuplication ();
        return System.schedule('Detecting Duplicated Photos', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        PhotoViewerHashDuplicationHandler handler = new PhotoViewerHashDuplicationHandler();
        Database.executeBatch(handler, 500);
    }
}