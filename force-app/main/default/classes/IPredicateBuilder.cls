public interface IPredicateBuilder {
    IPredicateBuilder groupStart();
    IPredicateBuilder groupEnd();
    IPredicateBuilder sqlAnd();
    IPredicateBuilder sqlOr();
    IPredicateBuilder addPredicate(String field, Integer dataType, String operator, Object value);
    IPredicateBuilder addPredicateBetween(String field, Integer dataType, Object startValue, Object endValue);
    String build();
}