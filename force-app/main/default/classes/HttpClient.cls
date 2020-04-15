global with sharing class HttpClient implements IHttpClient {
    private string url;
    private Map<String, String> headers;
    private Map<String, Object> fields;
    private String body;
    private String method;
    private String requestContentType;

    private static String MULTIPART_BOUNDARY = '717ca875e72446fd87b8779215de9d98';
    global static String HTTP_METHOD_GET = 'GET';
    global static String HTTP_METHOD_POST = 'POST';
    global static String HTTP_METHOD_PUT = 'PUT';
    global static String HTTP_METHOD_DELETE = 'DELETE';

    global static String CONTENTTYPE_JSON = 'Application/json';
    global static String CONTENTTYPE_FORM = 'application/x-www-form-urlencoded';
    global static String CONTENTTYPE_FORMDATA = 'multipart/form-data';
    global static Integer RESPONSE_BAD_REQUEST = 400;
    global static Integer RESPONSE_UNAUTHORIZED = 401;
    global static Integer RESPONSE_FORBIDDEN = 403;
    global static Integer RESPONSE_NOT_FOUDN = 404;
    global static Integer RESPONSE_NOT_ALLOWED = 405;
    global static Integer RESPONSE_NOT_ACCEPTED = 406;
    global static Integer RESPONSE_GONE = 410;
    global static Integer RESPONSE_PAYLOAD_TOO_LARGE = 413;
    global static Integer RESPONSE_INVALID_MEDIA_TYPE = 415;
    global static Integer RESPONSE_INTERNAL_SERVER_ERROR = 500;
    global static Integer RESPONSE_BAD_GATEWAY = 502;
    global static Integer RESPONSE_SERVICE_NOT_AVAILABLE = 503;
    global static Integer RESPONSE_NOT_IMPLEMENTED = 501;

    public HttpClient() {
        this.headers = new Map<String, String>();
        this.fields = new Map<String, Object>();
        this.method = HTTP_METHOD_GET;
    }

    public IHttpClient url(String url) {
        this.url = url;
        return this;
    }

    public IHttpClient header(String key, String value) {
        this.headers.put(key, value);
        return this;
    }

    public IHttpClient field(String key, Object value) {
        this.fields.put(key, value);
        return this;
    }

    public IHttpClient body(String body) {
        this.body = body;
        return this;
    }

    public IHttpClient contentType(String type) {
        this.requestContentType = type;
        return this;
    }

    public IHttpClient method(String method) {
        this.method = method;
        return this;
    }

    public HttpResponse submitToResponse() {
        if (String.isEmpty(this.requestContentType)) {
            throw new CustomException('The content-type is not assigned.');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod(this.method);
        if (this.requestContentType == CONTENTTYPE_FORMDATA) {
            request.setHeader('Content-Type', CONTENTTYPE_FORMDATA + '; charset="UTF-8"; boundary="' + MULTIPART_BOUNDARY + '"');
        } else {
            request.setHeader('Content-Type', this.requestContentType);
        }

        for (String key : this.headers.keySet()) {
            request.setHeader(key, this.headers.get(key));
        }

        if (this.method == HTTP_METHOD_GET) {
            String query = this.genQuery();
            String url = String.isNotBlank(query) ? (this.url + '?' + query) : this.url;
            request.setEndpoint(url);
        } else {
            request.setEndpoint(this.url);
            if (this.requestContentType == CONTENTTYPE_FORMDATA) {
                Blob body = genMultiPartFormData();
                request.setHeader('Content-Length', String.valueOf(body.size()));
                request.setBodyAsBlob(body);
            } else {
                request.setBody(this.genBody());
            }
        }

        Http http = new Http();
        HttpResponse response = http.send(request);
        Integer status = response.getStatusCode();

        if (status > 399) {
            throw new CustomException(response.getBody());
        }

        return response;
    }

    public Map<String, Object> submit() {
        HttpResponse res = this.submitToResponse();
        return JsonContentParser.parse(res.getBody());
    }

    private String genBody() {
        List<String> params = new List<String>();
        if (this.fields.size() > 0) {
            for (String key : this.fields.keySet()) {
                if (this.fields.get(key) != null) {
                    params.add(key + '=' + String.valueOf(this.fields.get(key)));
                }
            }
        }
        if (this.body != null) {
            params.add(this.body);
        }

        return String.join(params, '&');
    }

    private String genQuery() {
        if (this.fields.size() == 0) {
            return '';
        }
        List<String> params = new List<String>();
        for (String key : fields.keySet()) {
            if (this.fields.get(key) != null) {
                params.add(key + '=' + EncodingUtil.urlEncode(String.valueOf(this.fields.get(key)), 'UTF-8'));
            }
        }
        return params.size() > 0 ? String.join(params, '&') : '';
    }

    private Blob genMultiPartFormData() {
        Boolean hasField = false;
        List<String> body = new List<String>();
        for (String key : this.fields.keySet()) {
            if (this.fields.get(key) != null) {
                body.add(writeBoundary());
                body.add(writeBodyParam(key, String.valueOf(this.fields.get(key))));
                hasField = true;
            }
        }

        if (hasField) {
            body.add(writeBoundary(EndingType.CrLf));
        }

        return EncodingUtil.base64Decode(String.join(body, ''));
    }

    private static String writeBoundary() {
        String value = '--' + MULTIPART_BOUNDARY + '\r\n';
        return EncodingUtil.base64Encode(Blob.valueOf(value));
    }

    private static String writeBoundary(EndingType ending) {
        List<String> value = new List<String>();
        if (ending == EndingType.Cr) {
            value.add('\n');
        } else if (ending == EndingType.None) {
            value.add('\r\n');
        }

        value.add('--');
        value.add(MULTIPART_BOUNDARY);
        value.add('--');

        return EncodingUtil.base64Encode(Blob.valueOf(String.join(value, '')));
    }

    private static string writeBodyParam(String key, String value) {
        string contentDisposition = 'Content-Disposition: form-data; name="' + key + '"';
        string contentDispositionCrLf = contentDisposition + '\r\n\r\n';
        blob contentDispositionCrLfBlob = blob.valueOf(contentDispositionCrLf);
        string contentDispositionCrLf64 = EncodingUtil.base64Encode(contentDispositionCrLfBlob);
        string content = safelyPad(contentDisposition, contentDispositionCrLf64, '\r\n\r\n');
        string valueCrLf = value + '\r\n';
        blob valueCrLfBlob = blob.valueOf(valueCrLf);
        string valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);

        content += safelyPad(value, valueCrLf64, '\r\n');

        return content;
    }

    private static string safelyPad(
        string value,
        string valueCrLf64,
        string lineBreaks) {
        string valueCrLf = '';
        blob valueCrLfBlob = null;

        while (valueCrLf64.endsWith('=')) {
            value += ' ';
            valueCrLf = value + lineBreaks;
            valueCrLfBlob = blob.valueOf(valueCrLf);
            valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
        }

        return valueCrLf64;
    }

    private enum EndingType {
        Cr,
        CrLf,
        None
    }
}