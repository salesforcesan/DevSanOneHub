global class Reflection {
	public static final String AppNameSpace {get; set;}
  static {
    AppNameSpace = CONSTANTS.CURRENTNAMESPACE;
  }

  global static Object newInstance(String namespace, String className) {
    if (String.isBlank(className)) {
      throw new AuraHandledException('The apex class name are missing.');
    }
    String ns = String.isNotBlank(namespace) ? namespace : AppNameSpace;
    Type classType = Type.forName(ns, className);
    return classType.newInstance();
  }

  global static Object newInstance(String className) {
    return newInstance(AppNameSpace, className);
  }

}