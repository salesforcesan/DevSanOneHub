global without sharing class AIImageClassifier implements IAIImageClassifier {
    public String AccessToken {get; private set;}
    public String ModelId {get; private set;}
    public String serviceUrl {get; private set;}

    public AIImageClassifier(Integer tokenValidForInMinutes) {
        AIAccessTokenProvider provider = new AIAccessTokenProvider();
        this.AccessToken = provider.getAccessToken(tokenValidForInMinutes);
        this.ModelId = this.getModelId();
        this.serviceUrl = AIAccessTokenProvider.getAiSettingMap().get('serviceUrl');
    }

    private String getModelId() {
        Map<String,String> setting = new Map<String,String>();
        AISettings__mdt ai = [select PhotoModelName__c from AISettings__mdt LIMIT 1];
        AIModel__c model = [SELECT ModelId__c from AIModel__c WHERE Name = :ai.PhotoModelName__c LIMIT 1];
        return model.ModelId__c;
    }

    public Map<String,Double> predict(String imageUrl){
        Map<String, Double> result = new Map<String, Double>();
        Map<String, System.Type> types = new Map<String, System.Type>();
        types.put('probabilities', AIImageProbability.class);

        HttpClient client = new HttpClient();
        client.method(HttpClient.HTTP_METHOD_POST)
            .url(this.serviceUrl + '/predict')
            .header('Authorization', 'Bearer ' + this.AccessToken)
            .header('Cache-Control', 'no-cache')
            .contentType(HttpClient.CONTENTTYPE_FORMDATA)
            .field('modelId',this.ModelId)
            .field('sampleLocation', imageUrl);
        Map<String, Object> data = JsonContentParser.parseWithTypes(client.submitToResponse().getBody(), types);

        if (data.get('object') != 'predictresponse') {
            throw new CustomException(JSON.serialize(data));
        }
        List<Object> values = (List<Object>) data.get('probabilities');
        for(Object value: values){
            AIImageProbability prop = (AIImageProbability) value;
            result.put(prop.label, prop.probability);
        }
        return result;
    }
}