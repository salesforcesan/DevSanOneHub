public class DateUtil{
    
    
    
    public static String ToString(Date Value,String format)  {
        /* string representation if a Date value with formatting */
        Datetime temp = Datetime.newInstance(Value.year(), Value.month(), Value.day());
        return temp.format(format);
    }
    
    public static Date ToDate(String datestring)
    {
        
        try
        {
            return Date.parse(datestring);
        }
        catch(Exception ex)
        {
            return Date.ValueOf(datestring);    
        }
        
    }
    
    public static DateTime ToDateTime(String datetimestring)
    {
        
        try
        {
            return DateTime.parse(datetimestring);
        }
        catch(Exception ex)
        {
           	return DateTime.ValueOf(datetimestring);    
        }
        
    }
    
    
}