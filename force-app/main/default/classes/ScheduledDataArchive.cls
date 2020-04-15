global class ScheduledDataArchive  implements Schedulable {
  public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledDataArchive sch = new ScheduledDataArchive ();
        return System.schedule('START - Scheduled Data Archive', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        DataArchiveHandler handler = new DataArchiveHandler();
        handler.archive();
    }
}