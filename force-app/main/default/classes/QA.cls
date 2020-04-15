@isTest
public class QA {
	 //--- I am too lazy to type System.assert ----
    public static void EQ(Object expected, Object result, String behavior){
        System.assertEquals(expected,result, behavior);
    }

    public static void NEQ(Object expected, Object result, String behavior){
        System.assertNotEquals(expected, result, behavior);
    }    

    public static void isTrue(Boolean status, String behavior){
        System.assert(status, behavior);
    }

    public static void NotNull(Object result, String behavior){
        NEQ(null, result, behavior);
    }
}