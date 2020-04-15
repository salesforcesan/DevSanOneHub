global class ScheduledUpdateProjectServiceJobSummary implements Schedulable {
  public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledUpdateProjectServiceJobSummary sch = new ScheduledUpdateProjectServiceJobSummary();
        return System.schedule('Update Project Service Job Summary', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ScheduledUpdateProjectServiceJobSummary Execute**');
        ProjectServiceActionshelper.RunProjectServiceJobSummaryUpdate();
    }
}