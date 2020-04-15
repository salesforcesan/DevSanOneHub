global without sharing class JwtSigner {
    private String userId;
    private String tokenUrl;
    private Integer expirationInMinutes;
    private String privateKey;

    public String sign() {
        String payload = this.genPayload();
        String header = this.genHeader();
        String encodedHeader = this.base64URLencode(Blob.valueOf(header));
        String encodedPayload = this.base64URLencode(Blob.valueOf(payload));
        List<String> jwt = new List<String>();
        jwt.add(encodedHeader);
        jwt.add(encodedPayload);

        Blob decodedPrivateKey = EncodingUtil.base64Decode(this.privateKey);
        Blob signature = Crypto.sign('rsa-sha256', Blob.valueOf(String.join(jwt,'.')), decodedPrivateKey);
        jwt.add(this.base64URLencode(signature));

        return String.join(jwt,'.');
    }


    public JwtSigner setUserId(String email) {
        this.userId = email;
        return this;
    } 

    public JwtSigner setTokenURL(string url){
        this.tokenUrl = url;
        return this;
    }

    public JwtSigner setExpirationInMinutes(Integer minutes) {
        this.expirationInMinutes = minutes;
        return this;
    }

    public JwtSigner setPrivateKey(String key) {
        this.privateKey = key;
        return this;
    }

    private String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }

    private String genPayload() {
        Long rightNow = (dateTime.now().getTime()/1000)+1;
        Map<String,Object> payload = new Map<String,Object>();
        payload.put('sub', this.userId);
        payload.put('aud', this.tokenUrl);
        payload.put('exp', rightNow + 60 * this.expirationInMinutes);
        return JSON.serialize(payload);
    }

    private String genHeader() {
        Map<String,String> header = new Map<String,String>();
        header.put('alg', 'RS256');
        return JSON.serialize(header);                                                                                 
    }
}