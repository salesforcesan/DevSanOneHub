@isTest
public class GetJobUpdatesMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;        
        protected String bodyAsString=        '{'+
        '   "JobUpdates": [{'+
        '       "JobId": "a08j0000002oSHg",'+
        '       "JobName": "JOB-000005518",'+
        '       "StartDate": "2015-10-27",'+
        '       "EndDate": "2015-10-27",'+
        '       "StartTime": "9:30am",'+
        '       "EndTime": "12:30am",'+
        '       "LocationNumber": "3509",'+
        '       "LocationId": "B449FD8D-441B-4C98-9762-237F40E1D75A",'+
        '       "ExecutionCompany": "CROSSMARK",'+
        '       "LastModifiedDate": "2015-04-13T18:37:56.000Z",'+
        '       "Status": "Completed",'+
        '       "ExecutedDate": "2015-05-15",'+
        '       "AssignedDate": "2015-05-15",'+
        '       "CancelledDate": "2015-05-15",'+
        '       "ScheduledDate": "2015-05-15",'+
        '       "UpdateId": "100",'+
        '       "Responses": [{'+
        '           "QuestionId": "a0Rj0000001gQapEAE",'+
        '           "Answers": ["Somewhat familiar"]'+
        '       },'+
        '       {'+
        '           "QuestionId": "a0Rj0000001gQaqEAE",'+
        '           "Answers": ["Yes"]'+
        '       },'+
        '       {'+
        '           "QuestionId": "a0Rj0000001gQarEAE",'+
        '           "Answers": ["2015-10-27"]'+
        '       },'+
        '       {'+
        '           "QuestionId": "a0Rj0000001gQawEAE",'+
        '           "Answers": ["Taste",'+
        '           "Nutritional or health benefits"]'+
        '       }]'+
        '   },'+
        '   {'+
        '       "JobId": "a08j0000003H2Tv",'+
        '       "JobName": "JOB-000006873",'+
        '       "StartDate": "2015-06-16",'+
        '       "EndDate": "2015-06-16",'+
        '       "StartTime": "10:30am",'+
        '       "EndTime": "12:30am",'+
        '       "LocationNumber": "3509",'+
        '       "LocationId": "B449FD8D-441B-4C98-9762-237F40E1D75A",'+
        '       "ExecutionCompany": "CROSSMARK",'+
        '       "LastModifiedDate": "2015-04-13T18:37:56.000Z",'+
        '       "Status": "Completed",'+
        '       "ExecutedDate": "2015-10-28",'+
        '       "AssignedDate": "2015-05-15",'+
        '       "CancelledDate": "2015-05-15",'+
        '       "ScheduledDate": "2015-05-15",'+
        '       "UpdateId": "102",'+
        '       "Responses": [{'+
        '           "QuestionId": "a0Rj0000001kMWGEA2",'+
        '           "Answers": ["Yes"]'+
        '       },'+
        '       {'+
        '           "QuestionId": "a0Rj0000001kMWHEA2",'+
        '           "Answers": ["2 Hrs"]'+
        '       }]'+
        '   }]'+
        '}';
        
        protected Blob bodyAsBlob;
        protected Map<String, String> responseHeaders;

        public GetJobUpdatesMock(Integer code, String status, Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;           
            this.bodyAsBlob = null;
            this.responseHeaders = responseHeaders;
        }

        public GetJobUpdatesMock(Integer code, String status, Blob body,
                                         Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsBlob = body;
            this.bodyAsString = null;
            this.responseHeaders = responseHeaders;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(code);
            resp.setStatus(status);
            if (bodyAsBlob != null) {
                resp.setBodyAsBlob(bodyAsBlob);
            } else {
                resp.setBody(bodyAsString);
            }

            if (responseHeaders != null) {
                 for (String key : responseHeaders.keySet()) {
                resp.setHeader(key, responseHeaders.get(key));
                 }
            }
            return resp;
        }
}