global class ScheduledBatchRetry implements Schedulable {
	public static String CRON_EXP = '0 0 * * * ?';
    
    global static String schedule() {
        ScheduledBatchRetry sch = new ScheduledBatchRetry ();
        return System.schedule('START - Scheduled Batch Retry', CRON_EXP, sch);
    }
    
    global void execute(SchedulableContext sc) {
        BatchRetryHandler handler = new BatchRetryHandler();
        handler.retry();
    }
}