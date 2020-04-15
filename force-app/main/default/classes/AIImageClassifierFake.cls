public without sharing class AIImageClassifierFake implements IAIImageClassifier {
    public Map<String, Double> predict(String imageUrl) {
        Map<String, Double> result = new Map<String, Double>();
        result.put('ShelfDisplay', 89.93);
        result.put('Other', 11.22);
        return result;
    }
}