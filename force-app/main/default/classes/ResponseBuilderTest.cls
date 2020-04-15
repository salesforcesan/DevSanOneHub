@isTest
private class ResponseBuilderTest
{
    @testSetup 
    static void setup() {
        TestDataUtil.init();
    }

	@isTest
	static void itShouldCreateExpectedContract()
	{
		// Given
        ResponseBuilder builder = new ResponseBuilder();
		
        // When
        test.startTest();
        builder.addElement('accounts', 'accounts');
        builder.addElement('locations', 'locations');
        builder.addElements('locations', new String[]{'1','2'});
        builder.addError('err1');
        builder.addAllErrors(new String[]{'err2','err3'});
        builder.addWarn('warn1');
        builder.addAllWarns(new String[]{'warn2','warn3'});
        builder.addAllWarns(null);
        builder.addAllErrors(new String[]{});
        builder.addElements('locations', null);
        test.stopTest();

		// Then
        Map<String,Object> result = builder.build();
        QA.EQ(CONSTANTS.STATUS_ERROR, result.get('status'), 'should be ERROR');
        List<Object> target =(List<Object>) result.get('accounts');
	    QA.EQ(1, target.size(), 'one account');
        target = (List<Object>) result.get('locations');
        QA.EQ(3, target.size(), '3 locations');
        target = (List<Object>) result.get('warnings');
        QA.EQ(3, target.size(),'3 warnings');
        target = (List<Object>) result.get('errors');
        QA.EQ(3, target.size(), '3 errors');
    }
}