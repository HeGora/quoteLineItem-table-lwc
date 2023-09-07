@isTest
public with sharing class LookupInputControllerTest {
    static TestHelper helper = new TestHelper();

    @isTest
    static private void fetchRecordsNoValueTC01(){
        Contact testContact = helper.getContact();
        insert testContact;
        String conditions = '[{"field":"LastName","value":"'+
                            testContact.LastName + '"}]';
        Test.startTest();
        List<LookupInputController.RecordsData> result = 
            LookupInputController.fetchRecords(conditions,
            'Contact', 'FirstName', testContact.FirstName, '');
        Test.stopTest();
        System.assertEquals(result.size(), 1, 'incorrect number of records was returned');
        System.assertEquals(result[0].label, testContact.FirstName, 'incorrect label');
        System.assertEquals(result[0].value, testContact.Id, 'incorrect value');
    }

    @isTest
    static private void fetchRecordsWithValueTC01(){
        Contact testContact = helper.getContact();
        insert testContact;
        Test.startTest();
        List<LookupInputController.RecordsData> result = 
            LookupInputController.fetchRecords('',
            'Contact', 'FirstName', '', testContact.Id);
        Test.stopTest();
        System.assertEquals(result.size(), 1, 'incorrect number of records was returned');
        System.assertEquals(result[0].label, testContact.FirstName, 'incorrect label');
        System.assertEquals(result[0].value, testContact.Id, 'incorrect value');
    }
}