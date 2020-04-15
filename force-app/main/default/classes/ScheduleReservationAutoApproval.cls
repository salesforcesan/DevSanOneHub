global class ScheduleReservationAutoApproval implements Schedulable {
  public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduleReservationAutoApproval sch = new ScheduleReservationAutoApproval ();
        return System.schedule('Reservation Auto Approval', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ScheduleReservationAutoApproval Execute**');
        
        ReservationHelper.AutoApprovePendingApprovalReservations();
    }
}