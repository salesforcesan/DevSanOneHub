global class ScheduledCalculateLocationAssetCapacity implements Schedulable {
  public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledCalculateLocationAssetCapacity sch = new ScheduledCalculateLocationAssetCapacity ();
        return System.schedule('Calculate Location Asset Capacity', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ScheduledCalculateLocationAssetCapacity Execute**');
        BatchBuildLocationAssetCapacity batch = new BatchBuildLocationAssetCapacity();
        Database.executeBatch(batch, 25);
    }
}