@isTest
public class AttachmentUrlGeneratorTest implements HttpCalloutMock{
    
    private HttpResponse resp;
    
     public AttachmentUrlGeneratorTest(String testBody) {
        resp = new HttpResponse();
        resp.setBody(testBody);
        resp.setStatusCode(200);
    }

    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
    }
    
    public static testMethod void test_generateUrl(){
        
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        String userSessionId = '00Dj0000001uLTs!ARgAQP128DkA0MNmhkVUKXG0Mg7_WZeRk.fHtzWA.fgFB0Qys2ly4k38xAekIgwTjzUl188npXUw.ykGzV94oeV0gMxKzU5O ';
        
        ProjectService__c ps = [SELECT Id,Service__c FROM ProjectService__c LIMIT 1];
        String url = '/services/apexrest/generateAttachmentUrl/'+project.Id;
        System.debug(userSessionId);

        RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();

		req.requestURI = System.URL.getSalesforceBaseURL()+'/services/apexrest/generateAttachmentUrl/'+project.Id;  
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		AttachmentURLGenerator.GenerateURL();

		System.assertEquals(201, res.statusCode);
		System.assertEquals(null, String.valueof(res.responseBody));
        
        
        try{
            test.startTest();
            HttpCalloutMock mock = new AttachmentUrlGeneratorTest('This is a test');

        	Test.setMock(HttpCalloutMock.class, mock);

            test.stopTest();
        }
        catch(Exception e){
        	System.debug(e.getMessage());
        }

    }


    public static testMethod void test_generateJobManualUrl(){
        
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        String userSessionId = '00Dj0000001uLTs!ARgAQP128DkA0MNmhkVUKXG0Mg7_WZeRk.fHtzWA.fgFB0Qys2ly4k38xAekIgwTjzUl188npXUw.ykGzV94oeV0gMxKzU5O ';
        
        ProjectService__c ps = [SELECT Id,Service__c FROM ProjectService__c LIMIT 1];
        String psID = ps.Id;
        String url = '/services/apexrest/generateAttachmentUrl/'+project.Id;
        ps.JobManualURL__c = url;
        
        update ps;
        
        attribute__c attr = new attribute__c(Active__c=true,
                                             AttributeType__c = 'Job Manual');
        insert attr;
        System.debug(userSessionId);

        RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();

		req.requestURI = System.URL.getSalesforceBaseURL()+'/services/apexrest/generateAttachmentUrl/'+project.Id;  
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		AttachmentURLGenerator.GenerateURL();

		//System.assertEquals(null, res.statusCode);
		//System.assertEquals(null, String.valueof(res.responseBody));
        
        
        try{
            test.startTest();
            HttpCalloutMock mock = new AttachmentUrlGeneratorTest('This is a test');

        	Test.setMock(HttpCalloutMock.class, mock);

            test.stopTest();
        }
        catch(Exception e){
        	System.debug(e.getMessage());
        }

    }
    
    public HTTPResponse respond(HTTPRequest req) {
        return resp;
    }

}