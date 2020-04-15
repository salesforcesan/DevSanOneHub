public with sharing class ErrorLog {
	 public String Message {get;set;}
        public Integer Severity {get;set;}
        public Datetime LogDate {get;set;}

		public ErrorLog(String msg, Integer severity) {
            this.Message = msg;
            this.Severity = severity;
            this.LogDate = Datetime.now();
        }

		public static final Integer SEVERITY_INFO = 0;
		public static final Integer SEVERITY_DEBUG = 1;
		public static final Integer SEVERITY_WARN = 2;
		public static final Integer SEVERITY_ERROR = 3;

		public static final Map<Integer, String> SEVERITY_MAP {get; private set;}

		static {
			SEVERITY_MAP = new Map<Integer, String>();
			SEVERITY_MAP.put(SEVERITY_INFO, 'INFO');
			SEVERITY_MAP.put(SEVERITY_DEBUG, 'DEBUG');
			SEVERITY_MAP.put(SEVERITY_WARN, 'WARN');
			SEVERITY_MAP.put(SEVERITY_ERROR, 'ERROR');
		}


        public override String toString() {
            return String.join(new String[]{
                '[',
            	SEVERITY_MAP.get(this.Severity),
                '][',
                String.valueOf(this.LogDate),
                ']:',
                this.Message
                }, '');
        }

}