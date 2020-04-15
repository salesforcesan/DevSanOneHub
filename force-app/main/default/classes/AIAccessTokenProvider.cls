global without sharing class AIAccessTokenProvider
    implements IAIAccessTokenProvider {
    private String refreshToken;
    private String refreshTokenTest2;
    private String refreshTokenTest4;
        
    //test
//test3
    global AIAccessTokenProvider() {
        this.refreshToken = '';
    }

    global String getAccessToken(Integer expirationInMinutes) {
        Map<String, String> setting = getAiSettingMap();
        String body = this.genBody(setting, expirationInMinutes);
        IHttpClient client = new HttpClient();
        Map<String, Object> result = client.url(setting.get('tokenUrl'))
                                     .method(HttpClient.HTTP_METHOD_POST)
                                     .field('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer')
                                     .field('scope', 'offline')
                                     .field('assertion', body)
                                     .contentType(HttpClient.CONTENTTYPE_FORM)
                                     .submit();
        this.refreshToken = String.valueOf(result.get('refresh_token'));
        return String.valueOf(result.get('access_token'));
    }

    private string genBody(Map<String, String> setting, integer expirationInMinues) {
        JwtSigner signer = new JwtSigner();
        return signer
               .setTokenURL(setting.get('tokenUrl'))
               .setUserId(setting.get('userId'))
               .setExpirationInMinutes(expirationInMinues)
               .setPrivateKey(setting.get('privateKey'))
               .sign();
    }

    global static Map<String, String> getAiSettingMap() {
        Map<String, String> setting = new Map<String, String>();
        AISettings__mdt ai = [select UserId__c, ServiceUrl__c, Einsteinpem__c, TokenUrl__c, TokenValidForInMinutes__c, BatchSize__c from AISettings__mdt LIMIT 1];
        setting.put('userId', ai.UserId__c);
        setting.put('serviceUrl', ai.ServiceUrl__c);
        setting.put('tokenUrl', ai.TokenUrl__c);
        setting.put('privateKey', ai.Einsteinpem__c);
        setting.put('batchSize', String.valueOf(ai.BatchSize__c));
        setting.put('tokenInMinutes', String.valueOf(ai.TokenValidForInMinutes__c));

        return setting;
    }

    global static Integer getBatchSize() {
        try {
            Map<String, String> setting = AIAccessTokenProvider.getAiSettingMap();
            return Integer.valueOf(setting.get('batchSize'));
        } catch (Exception ex) {
            return 500;
        }
    }

    global static Integer getTokenInMinutes() {
        try {
            Map<String, String> setting = AIAccessTokenProvider.getAiSettingMap();
            return Integer.valueOf(setting.get('tokenInMinutes'));
        } catch (Exception ex) {
            return 3600;
        }
    }
}