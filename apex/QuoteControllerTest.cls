@isTest
public with sharing class QuoteControllerTest {
    static TestHelper helper = new TestHelper();

    @TestSetup
    static private void setupData(){
        Opportunity testOpp = helper.getOpportunity();
        insert testOpp;
        Quote testQuote = new Quote(OpportunityId = testOpp.Id,
         Name = 'Test quote', Pricebook2Id = helper.getStdPricebook().Id);
        insert testQuote;
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        List<PricebookEntry> priceBookEntries = helper.setupProducts();
        for(Integer i = 0; i < 500; ++i){
            quoteLineItems.add(new QuoteLineItem(QuoteId = testQuote.Id,
              PricebookEntryId = priceBookEntries[0].Id, Quantity = i + 1,
              UnitPrice = i + 1));
        }
        insert quoteLineItems;
    }

    @isTest
    static void getDataTC01(){
        List<QuoteLineItem> quoteLineItems = 
            [SELECT
                Id,
                QuoteId
            FROM
                QuoteLineItem];
        List<Quote> testQuote = 
            [SELECT 
                Id, 
                Pricebook2.Name, 
                CurrencyIsoCode 
            FROM 
                Quote 
            WHERE 
                Id = :quoteLineItems[0].QuoteId];
        Test.startTest();
            QuoteController.InitialData result =
             QuoteController.getData(testQuote[0].Id);
        Test.stopTest();
        System.assertEquals(500, result.quoteLineItems.size(),
         'method returns wrong number of records');
         System.assertEquals(testQuote[0].Pricebook2.Name, result.pricebookConditions[0].value,
         'wrong Pricebook name was returned');
        System.assertEquals(testQuote[0].CurrencyIsoCode, result.pricebookConditions[1].value,
         'wrong currency code was returned');
    }

    @isTest
    static void getQuoteLineItemsTC01(){
        List<QuoteLineItem> quoteLineItems =
            [SELECT
                Id,
                QuoteId
            FROM
                QuoteLineItem];
        Test.startTest();
            List<QuoteController.QuoteLineItemWrapper> result =
             QuoteController.getQuoteLineItems(quoteLineItems[0].QuoteId);
        Test.stopTest();
        System.assertEquals(500, result.size(), 'method returns wrong number of records');
    }

    @isTest
    static void dmlOnQuoteLineItemsUpdateTC01(){
        List<QuoteLineItem> quoteLineItems =
            [SELECT
                Id,
                QuoteId, 
                ServiceDate, 
                Discount, 
                Description, 
                ListPrice, 
                PricebookEntryId, 
                PricebookEntry.Name, 
                Quantity,
                UnitPrice, 
                Subtotal, 
                TotalPrice,
                UserRecordAccess.HasEditAccess,
                UserRecordAccess.HasDeleteAccess
            FROM 
                QuoteLineItem];
        Id quoteId = quoteLineItems[0].QuoteId;
        List<QuoteController.QuoteLineItemWrapper> wrappers =
            new List<QuoteController.QuoteLineItemWrapper>();
        for(Integer i = 0; i < quoteLineItems.size(); ++i){
            quoteLineItems[i].UnitPrice = 10;
            wrappers.add(new QuoteController.QuoteLineItemWrapper(quoteLineItems[i]));
        }
        String dataToUpdate = JSON.serialize(wrappers);
        Test.startTest();
            QuoteController.dmlOnQuoteLineItems(dataToUpdate, new List<Id>(), quoteId);
        Test.stopTest();
        quoteLineItems = [SELECT UnitPrice FROM QuoteLineItem];
        for(Integer i = 0; i < quoteLineItems.size(); ++i){
            System.assertEquals(10, quoteLineItems[i].UnitPrice, 'record was not updated properly');
        }
    }

    @isTest
    static void dmlOnQuoteLineItemsInsertTC01(){
        List<QuoteLineItem> quoteLineItems =
            [SELECT
                Id,
                QuoteId, 
                ServiceDate, 
                Discount, 
                Description, 
                ListPrice, 
                PricebookEntryId, 
                PricebookEntry.Name, 
                Quantity,
                UnitPrice, 
                Subtotal, 
                TotalPrice,
                UserRecordAccess.HasEditAccess,
                UserRecordAccess.HasDeleteAccess
            FROM 
                QuoteLineItem];
        Id quoteId = quoteLineItems[0].QuoteId;
        delete quoteLineItems;
        List<QuoteController.QuoteLineItemWrapper> wrappers =
            new List<QuoteController.QuoteLineItemWrapper>();
        for(Integer i = 0; i < quoteLineItems.size(); ++i){
            wrappers.add(new QuoteController.QuoteLineItemWrapper(quoteLineItems[i]));
            wrappers[i].isSaved = false;
        }
        String dataToInsert = JSON.serialize(wrappers);
        Test.startTest();
            QuoteController.dmlOnQuoteLineItems(dataToInsert, new List<Id>(), quoteId);
        Test.stopTest();
        quoteLineItems = [SELECT UnitPrice FROM QuoteLIneItem];
        System.assertEquals(quoteLineItems.size(), 500, 'record was not inserted properly');
    }

    @isTest
    static void dmlOnQuoteLineItemsDeleteTC01()
    {
        List<QuoteLineItem> quoteLineItems =
            [SELECT
                Id,
                QuoteId,
                UnitPrice
            FROM
                QuoteLineItem];
        Id quoteId = quoteLineItems[0].QuoteId;
        List<Id> dataToDelete = new List<Id>();
        for(Integer i = 0; i < quoteLineItems.size(); ++i){
            dataToDelete.add(quoteLineItems[i].Id);
        }
        Test.startTest();
            QuoteController.dmlOnQuoteLineItems('[]', dataToDelete, quoteId);
        Test.stopTest();
        quoteLineItems = [SELECT UnitPrice FROM QuoteLIneItem];
        System.assertEquals(quoteLineItems.size(), 0, 'record was not deleted properly');
    }

    @isTest
    static void getPriceBookConditionsTC01(){
        Quote testQuote = 
            [SELECT
                Id,
                CurrencyIsoCode
            FROM
                Quote
            LIMIT 1];
        Pricebook2 testPricebook = 
            [SELECT
                Id,
                Name
            FROM
                Pricebook2
            LIMIT 1];
        Test.startTest();
            String priceBookName = QuoteController.getPricebookEntryConditions(testQuote.Id)[0].value;
            String priceBookCurrency = QuoteController.getPricebookEntryConditions(testQuote.Id)[1].value;
        Test.stopTest();
        System.assertEquals(testPricebook.Name, priceBookName,
        'wrong Pricebook name was returned');
        System.assertEquals(testQuote.CurrencyIsoCode, priceBookCurrency,
        'wrong currency code was returned');
    }

    @isTest
    static void getPricebookEntryTC01(){
        List<PricebookEntry> priceBookEntries = 
            [SELECT 
                Id,
                UnitPrice
            FROM
                PriceBookEntry];
        Test.startTest();
            System.assertEquals(priceBookEntries[0].UnitPrice,
            QuoteController.getPricebookEntry(priceBookEntries[0].Id),
            'wrong Pricebook Entrie unit price was returned');
        Test.stopTest();
    }
}