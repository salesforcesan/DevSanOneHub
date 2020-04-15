global class ScheduledProjectStatusChange implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledProjectStatusChange sch = new ScheduledProjectStatusChange ();
        return System.schedule('Change Project Status', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ProjectStatusChangeJob Execute**');
        ProjectStatusChangeHandler handler = new ProjectStatusChangeHandler();
        handler.changeStatus();
        
        JobActionsHelper.RunCreateAttempts();
    }
}