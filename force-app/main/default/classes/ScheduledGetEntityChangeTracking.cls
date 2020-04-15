global class ScheduledGetEntityChangeTracking implements Schedulable {
  public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledGetEntityChangeTracking sch = new ScheduledGetEntityChangeTracking ();
        return System.schedule('Entity Change Tracking', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ScheduledGetEntityChangeTracking Execute**');
        
        EntityHistoryActionHelper.RunEntityHistoryGetter(); 
        
        ProjectActionsHelper.RunProjectSequenceUpdater();
    }
}