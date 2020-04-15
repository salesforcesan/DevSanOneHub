public without sharing class MapResultBuilder {
    Map<String,Object> mapResult {get; private set;}
    private MapResultBuilder() {
        this.mapResult = new Map<String,Object>();
    }

    public static MapResultBuilder newInstance() {
        return new MapResultBuilder();
    }

    public MapResultBuilder add(String key,Object value) {
        this.mapResult.put(key, value);
        return this;
    }

    public Map<String,Object> build() {
        return this.mapResult;
    }

    public String buildToJson() {
        return JSON.serialize(this.mapResult);
    }
}