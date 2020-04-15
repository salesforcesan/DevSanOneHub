global interface IHttpClient {
    IHttpClient url(String url);
    IHttpClient header(String key, String value);
    IHttpClient body(String body);
    IHttpClient contentType(String type);
    IHttpClient method(String method);
    IHttpClient field(String key, Object value);
    HttpResponse submitToResponse();
    Map<String, Object> submit();
}