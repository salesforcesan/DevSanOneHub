global class ScheduledPurgeEntityChangeLog implements Schedulable {
	public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledPurgeEntityChangeLog sch = new ScheduledPurgeEntityChangeLog ();
        return System.schedule('Purge Entity Change Log', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        
        system.debug('**ScheduledPurgeEntityChangeLog Execute**');
        
        Apputil.RunEntityChangeLogPurge();
    }
}