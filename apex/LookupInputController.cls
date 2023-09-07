public with sharing class LookupInputController {
    @AuraEnabled
    public static List<RecordsData> fetchRecords(String conditionString, String objectName, String filterField, String searchString, String value) {
        try {
            List<RecordsData> recordsDataList = new List<RecordsData>();
            String query = 'SELECT Id, ' + filterField + ' FROM ' + objectName;
            if(String.isNotBlank(value)) {
                query += ' WHERE Id = \''+ value + '\'';
            } else {
                query += ' WHERE '+filterField+
                		' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\'';
                if(String.isNotBlank(conditionString))
                {
                    List<SearchCondition> conditions = 
                    (List<SearchCondition>)JSON.deserialize(conditionString,
                    List<SearchCondition>.class);
                    for(Integer i = 0; i < conditions.size(); ++i){
                        query += ' AND ' + conditions[i].field + ' = \''+
                        String.escapeSingleQuotes(conditions[i].value) + '\'';
                    }
                }    
            }
            query += ' LIMIT 49999';
	        for(SObject s : Database.query(query)) {
	            recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('id')) );
	        }
            return recordsDataList;
	    } catch (Exception err) {
	    	if ( String.isNotBlank( err.getMessage() ) && err.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
	    }
    }
 
    public class RecordsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class SearchCondition{
        @AuraEnabled public String field{get;set;}
        @AuraEnabled public String value{get;set;}

        public SearchCondition(String field, String value){
            this.field = field;
            this.value = value;
        }
    }
}