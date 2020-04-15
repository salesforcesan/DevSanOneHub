global without sharing class JsonContentParser {

    global static Map<String, Object> parse(String content) {
        Map<String, Object> result = new Map<String, Object>();
        String key;
        Object value;
        JSONToken currentToken;

        System.JSONParser parser = JSON.createParser(content);
        while (parser.nextToken() != null) {
            if ( parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                key = parser.getText();
                parser.nextToken();
                currentToken = parser.getCurrentToken();
                value = getTokenValue(currentToken, parser);
                result.put(key, value);
            }
        }

        return result;
    }

    private static List<Object> getArrayTokenValue(System.JSONParser parser) {
        Object value;
        Map<String, Object> valueMap;
        String key;
        List<Object> results = new List<Object>();
        JSONToken token;
        JSONToken valueToken;

        while (parser.nextToken() != JSONToken.END_ARRAY) {
            token = parser.getCurrentToken();
            if (token == JSONToken.START_OBJECT) {
                valueMap = getObjectTokenValue(parser);
                results.add(valueMap);
            } else {
                value = getTokenValue(token, parser);
                results.add(value);
            }
        }
        return results;
    }

    private static Map<String, Object> getObjectTokenValue(System.JSONParser parser) {
        String key;
        JSONToken valueToken;
        Map<String, Object> valueMap = new Map<String, Object>();

        while (parser.nextToken() != JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                key = parser.getText();
                parser.nextToken();
                valueToken = parser.getCurrentToken();
                valueMap.put(key, getTokenValue(valueToken, parser));
            }
        }

        return valueMap;
    }

    private static List<Object> getArrayTypedTokenValue(System.Type dataType, System.JSONParser parser) {
        Object value;
        List<Object> results = new List<Object>();
        JSONToken token;

        while (parser.nextToken() != JSONToken.END_ARRAY) {
            token = parser.getCurrentToken();
            if (token == JSONToken.START_OBJECT) {
                results.add(parser.readValueAs(dataType));
                parser.skipChildren();
            } else {
                value = getTokenValue(token, parser);
                results.add(value);
            }
        }
        return results;
    }

    private static Object getTokenValue(JSONToken token, System.JSONParser parser) {
        if (token == JSONToken.VALUE_NULL) {
            return null;
        }

        if (token == JSONToken.VALUE_FALSE || token == JSONToken.VALUE_TRUE) {
            return parser.getBooleanValue();
        }

        if (token == JSONToken.VALUE_NUMBER_FLOAT) {
            return parser.getDoubleValue();
        }

        if (token == JSONToken.VALUE_NUMBER_INT) {
            return parser.getIntegerValue();
        }

        if (token == JSONToken.START_ARRAY) {
            return getArrayTokenValue(parser);
        }

        if (token == JSONToken.START_OBJECT) {
            return getObjectTokenValue(parser);
        }

        return parser.getText();
    }

    global static Map<String, Object> parseWithTypes(
        String content, Map<String, System.Type> types) {
        Map<String, Object> result = new Map<String, Object>();
        String key;
        Object value;
        System.Type thisType;

        System.JSONParser parser = JSON.createParser(content);
        while (parser.nextToken() != null) {
            if ( parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                key = parser.getText();
                parser.nextToken();
                if (types.containsKey(key)) {
                    thisType = (System.Type) types.get(key);
                    value = parseValue(thisType, parser);
                } else {
                    value = parser.getText();
                }
                result.put(key, value);
            }
        }

        return result;
    }

    private static Object parseValue(System.Type valueType, System.JSONParser parser) {
        Object value;
        List<Map<String, Object>> valueMaps = new List<Map<String, Object>>();
        Map<String, Object> valueMap;
        JSONToken currentToken = parser.getCurrentToken();

        if (currentToken == JSONToken.START_ARRAY) {
            List<Object> arrValue = new List<Object>();
            while (parser.nextToken() != JSONToken.END_ARRAY) {
                value = parseSimpleTypedValue(valueType, parser);
                if (value != null){
                    arrValue.add(value);
                }
            }
            return arrValue;
        }

        return parseSimpleTypedValue(valueType, parser);
    }

    private static Object parseSimpleTypedValue(System.Type valueType, System.JSONParser parser) {
        JSONToken currentToken = parser.getCurrentToken();
        if (currentToken == JSONToken.VALUE_NULL) {
            return null;
        }

        if (currentToken == JSONToken.START_OBJECT) {
            Object value = parser.readValueAs(valueType);
            parser.skipChildren();
            return value;
        }

        if (valueType == String.class) {
            return parser.getText();
        }

        if (valueType == Integer.class) {
            return parser.getIntegerValue();
        }

        if (valueType == Boolean.class) {
            return parser.getBooleanValue();
        }

        if (valueType == Date.class) {
            return parser.getDateValue();
        }

        if (valueType == Decimal.class) {
            return parser.getDecimalValue();
        }

        if (valueType == DateTime.class) {
            return parser.getDateTimeValue();
        }

        if (valueType == Double.class) {
            return parser.getDoubleValue();
        }

        if (valueType == Long.class) {
            return parser.getLongValue();
        }

        if (valueType == Time.class) {
            return parser.getTimeValue();
        }

        if (valueType == ID.class) {
            return parser.getIdValue();
        }

        if (valueType == Blob.class) {
            return parser.getBlobValue();
        }

        return parser.getText();
    }
}