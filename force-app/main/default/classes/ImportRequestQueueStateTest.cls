@isTest
private class ImportRequestQueueStateTest
{
	@isTest
	static void ItShouldNotifyUserIfQueueCompletedWithoutError()
	{
		// Given
		ImportRequestQueueNotifierState ctx = 
			ImportRequestQueueNotifierState.newInstance();

		// When
		test.startTest();
		ctx.markCompleted();
		ctx.plusSuccessCount(1000);
		ctx.plusTotalCount(1000);
		ctx.plusErrorCount(0);
		ctx.markEmailNotified();
		test.stopTest();

		// Then
		QA.EQ(ctx.getTotalCount(), ctx.getSuccessCount(), '1000 matched');
		QA.isTrue(ctx.shouldNotifyUser(), 'should notfier user if completed');
		QA.isTrue(ctx.getEmailNotified(), 'notified = true');
		QA.EQ('Completed', ctx.getStatus(), 'status = Completed');
		QA.isTrue(String.isBlank(ctx.getErrorString()), 'no error');
	}

	@isTest
	static void ItShouldNotifyUserIfQueueCompletedWithError()
	{
		// Given
		ImportRequestQueueNotifierState ctx = 
			ImportRequestQueueNotifierState.newInstance();

		// When
		test.startTest();
		ctx.markCompleted();
		ctx.plusSuccessCount(1000);
		ctx.plusTotalCount(1010);
		ctx.plusErrorCount(10);
		ctx.addError('test');
		test.stopTest();

		// Then
		QA.isTrue(ctx.hasError(), 'has error message');
		QA.EQ(ctx.getTotalCount(), ctx.getErrorCount() + ctx.getSuccessCount(), '1010 matched');
		QA.isTrue(ctx.shouldNotifyUser(), 'should notfier user if completed');
		QA.EQ('Completed', ctx.getStatus(), 'status = Completed');
		QA.EQ(1010, ctx.getSuccessCount() + ctx.getErrorCount(), '1010');
		QA.isTrue(ctx.getErrorString().indexOf('test') != -1, 'test in message');
	}

	@isTest
	static void checkStatusAssignedProperly(){
		//GIVEN
		ImportRequestQueueNotifierState ctx = 
			ImportRequestQueueNotifierState.newInstance();

		//WHEN
		ctx.markCanceled();
		QA.isTrue(ctx.getStatus() == 'Canceled', 'canceled');

		ctx.markQueued();
		QA.isTrue(ctx.getStatus() == 'Queued', 'queued');

		ctx.markProcessing();
		QA.isTrue(ctx.getStatus() == 'Processing', 'processing');

		ctx.markFailed();
		QA.isTrue(ctx.getStatus() == 'Failed', 'failed');
		QA.isTrue(ctx.shouldNotifyUser(), 'need tell user if failed');
	}

}