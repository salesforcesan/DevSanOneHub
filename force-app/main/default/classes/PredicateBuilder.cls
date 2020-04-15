global without sharing class PredicateBuilder implements IPredicateBuilder{
    private List<String> sqlWhere;

    private PredicateBuilder() {
        this.sqlWhere = new List<String>();
    }

    public static IPredicateBuilder newBuilder(){
        return new PredicateBuilder();
    }

    public IPredicateBuilder groupStart(){
        this.sqlWhere.add('(');
        return this;
    }   

    public IPredicateBuilder groupEnd(){
        this.sqlWhere.add(')');
        return this;
    }

    public IPredicateBuilder sqlAnd() {
        this.sqlWhere.add('AND');
        return this;
    }
    public IPredicateBuilder sqlOr() {
        this.sqlWhere.add('OR');
        return this;
    }

    public IPredicateBuilder addPredicate(String field, Integer dataType, String operator, Object value) {
        if (dataType == SQLDataType.sqlString){
            this.sqlWhere.add('(' + namify(field) + operator + '\'' + value + '\')');
        } else {
            this.sqlWhere.add('(' + namify(field) + operator + value + ')');
        }
        
        return this;
    }

    public IPredicateBuilder addPredicateBetween(String field, Integer dataType, Object startValue, Object endValue) {
        string fieldName = namify(field);
        if (dataType == SQLDataType.sqlString){
            this.sqlWhere.add('(' + fieldName + '>=\'' + startValue);
            this.sqlWhere.add('\' AND '+ fieldName + '<=\'' + endValue + '\')');
        }
        else {
            this.sqlWhere.add('(' + fieldName + '>=' + startValue);
            this.sqlWhere.add(' AND ' + fieldName + '<=' + endValue + ')');
        }
        return this;
    }

    public String build() {
        return (this.sqlWhere.size() > 0) ? 'WHERE ' + String.join(this.sqlWhere,' ') : '';
    }

    static String namify(String name){
        string key = name.toLowerCase();
        return (key != 'id' && key != 'name') ? (CONSTANTS.CURRENTNAMESPACEPREFIX + name) : name;
    }
}