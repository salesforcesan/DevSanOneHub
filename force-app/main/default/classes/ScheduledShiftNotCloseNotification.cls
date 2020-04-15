global without sharing class ScheduledShiftNotCloseNotification implements Schedulable {
     global void execute(SchedulableContext sc ){
        BatchShiftNotCloseNotification notifyBatch = new BatchShiftNotCloseNotification();
        Database.executeBatch(notifyBatch, 5);
    }
}