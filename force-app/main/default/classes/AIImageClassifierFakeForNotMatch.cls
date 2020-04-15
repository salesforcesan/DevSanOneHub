global without sharing class AIImageClassifierFakeForNotMatch implements IAIImageClassifier {
    public Map<String, Double> predict(String imageUrl) {
       throw new CustomException('NotMatch');
    }
}