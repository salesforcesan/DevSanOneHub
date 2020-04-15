public class JobAttemptTriggerHandler extends TriggerHandler {

static ILogger DEBUG_LOGGER;
    static {
        DEBUG_LOGGER = LoggerFactory.createLogger('JobAttemptTrigger', false);
    }

    public override void beforeUpdate() {
        if (true == TriggerUtil.skipJobAttemptTrigger) {
            DEBUG_LOGGER.debug('skip beforeUpdate');
            return;
        }

        JobAttemptTriggerBeforeUpdateHandler.newInstance((Map<ID, JobAttempt__c>)Trigger.newMap, (Map<ID, JobAttempt__c>)Trigger.oldMap).execute();
    }

    public override void afterUpdate() {
        if (true == TriggerUtil.skipJobAttemptTrigger) {
            DEBUG_LOGGER.debug('skip afterUpdate');
            DEBUG_LOGGER.save();
            return;
        }
		TriggerUtil.skipJobAttemptTrigger = true;
        
        JobAttemptTriggerAfterUpdateHandler.newInstance((Map<ID, JobAttempt__c>)Trigger.newMap, (Map<ID, JobAttempt__c>)Trigger.oldMap).execute();
    }    
}