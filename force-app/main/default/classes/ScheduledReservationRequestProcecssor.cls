global class ScheduledReservationRequestProcecssor implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledReservationRequestProcecssor sch = new ScheduledReservationRequestProcecssor ();
        return System.schedule('Reservation Request Processor', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        system.debug('**ScheduledReservationRequestProcecssor Execute**');
        //First check if any reservation has expired
        //EXPIRED RESERVATIONS
        Date todaysDate = system.Today();
        List<Reservation__c> expiredReservations = [SELECT Id, Name, Status__c
                                                    FROM Reservation__c 
                                                    WHERE ExpirationDate__c < :todaysDate AND 
                                                    Isexpirable__c = true LIMIT 1];
        if (!expiredReservations.isEmpty())
        {
            ReservationHelper.ExpireReservation(expiredReservations[0].Id);
        }
        
        ReservationHelper.notifyReservationExpiration();
    }
}