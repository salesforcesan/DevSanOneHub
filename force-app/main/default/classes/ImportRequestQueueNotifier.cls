global class ImportRequestQueueNotifier implements Schedulable  {
	private static final String APP_ID = 'ImportRequestQueueNotifier';

	global void execute(SchedulableContext SC) {
		try {
			ImportRequestQueueNotifierBatchHandler batcher =
			  new ImportRequestQueueNotifierBatchHandler(EmailNotifier1.class);

			String jobId = Database.executeBatch(batcher, 1);
			if (jobId == '000000000000000') {
				AppLogBatch.batchWarn('Faild to submit batch job', 'The executeBatch call fails to acquire an Apex flex queue lock', '', APP_ID);
			}
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, '', APP_ID);
		}
	}

	global static String scheduleToRun(String cronSetting) {
		return scheduleToRun('ImportJobQueueManager', cronSetting);
	}

	global static String scheduleToRun(String jobName, String cronSetting) {

		ImportRequestQueueNotifier notifier = new ImportRequestQueueNotifier();
		String cron_exp = String.isNotBlank(cronSetting)
		                  ? cronSetting
		                  : '0 15 * * * ?';
		return System.schedule(APP_ID + jobName, cron_exp, notifier);
	}
}