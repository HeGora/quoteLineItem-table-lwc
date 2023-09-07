public with sharing class QuoteController {

    @AuraEnabled
    public static InitialData getData(Id quoteId){
        try {
            List<QuoteLineItemWrapper> quoteLineItems = getQuoteLineItems(quoteId);
            List<LookupInputController.SearchCondition> conditions = getPricebookEntryConditions(quoteId);
            InitialData result = new InitialData(quoteLineItems, conditions);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<QuoteLineItemWrapper> getQuoteLineItems(Id quoteId){
        try{
            List<QuoteLineItemWrapper> result = new List<QuoteLineItemWrapper>();
            for(QuoteLineItem tempQuoteLineItem : queryQuoteLineItems(quoteId)){
                result.add(new QuoteLineItemWrapper(tempQuoteLineItem));
            }
            return result;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }

    public static List<LookupInputController.SearchCondition> getPricebookEntryConditions(Id quoteId){
        List<Quote> quoteData = 
            [SELECT 
                Pricebook2.Name,
                CurrencyIsoCode 
            FROM 
                Quote 
            WHERE 
                Id = :quoteId 
            WITH USER_MODE];
        List<LookupInputController.SearchCondition> result = new List<LookupInputController.SearchCondition>();
        result.add(new LookupInputController.SearchCondition('Pricebook2.Name', quoteData[0].Pricebook2.Name));
        result.add(new LookupInputController.SearchCondition('CurrencyIsoCode', quoteData[0].CurrencyIsoCode));
        return result;
    }

    @AuraEnabled
    public static Decimal getPricebookEntry(Id pricebookEntryId){
        try {
            List<PricebookEntry> result = 
                [SELECT 
                    UnitPrice 
                FROM 
                    PricebookEntry
                WHERE 
                    Id = :pricebookentryId
                WITH USER_MODE];
            return result[0].UnitPrice;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void dmlOnQuoteLineItems(String itemsToSave, List<Id> itemsToDelete, Id quoteId){
        try{
            upsertQuoteLineItems(itemsToSave, quoteId);
            deleteQuoteLineItems(itemsToDelete);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void deleteQuoteLineItems(List<Id> itemsToDelete){
        if(itemsToDelete.size() == 0){
            return;
        }
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        for(Integer i = 0; i < itemsToDelete.size(); ++i){
            quoteLineItems.add(new QuoteLineItem(Id = itemsToDelete[i]));
        }
        if(Schema.sObjectType.QuoteLineItem.isDeletable()){
            delete quoteLineItems;
        }
    }

    private static void upsertQuoteLineItems(String itemsToSave, Id quoteId){
        List<QuoteLineItemWrapper> wrapperList = 
             (List<QuoteLineItemWrapper>)JSON.deserialize(itemsToSave,
        List<QuoteLineItemWrapper>.class);
        if(wrapperList.size() == 0){
            return;
        }
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        for(Integer i = 0; i < wrapperList.size(); ++i){
            quoteLineItems.add(wrapperList[i].convertToQuoteLineItem(quoteId));
        }
        if(Schema.sObjectType.QuoteLineItem.isUpdateable() &&
            Schema.sObjectType.QuoteLineItem.isCreateable()){
            upsert quoteLineItems;
        }
    }

    private static List<QuoteLineItem> queryQuoteLineItems(Id quoteId)
    {
        return [
            SELECT
                Id, 
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
                QuoteLineItem
            WHERE 
                QuoteId = :quoteId 
            WITH USER_MODE
        ];
    }

    public class InitialData{
        @AuraEnabled
        public List<QuoteLineItemWrapper> quoteLineItems{get;set;}
        @AuraEnabled 
        public List<LookupInputController.SearchCondition> pricebookConditions{get;set;}

        public InitialData(List<QuoteLineItemWrapper> quoteLineItems, 
            List<LookupInputController.SearchCondition> conditions){
            this.quoteLineItems = quoteLineItems;
            this.pricebookConditions = conditions;
        }
    }

    public class QuoteLineItemWrapper{
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public Date serviceDate{get;set;}
        @AuraEnabled
        public Id pricebookEntryId{get;set;}
        @AuraEnabled 
        public String productName{get;set;}
        @AuraEnabled
        public Decimal quantity{get;set;}
        @AuraEnabled
        public Decimal listPrice{get;set;}
        @AuraEnabled
        public Decimal salesPrice{get;set;}
        @AuraEnabled
        public Decimal totalPrice{get;set;}
        @AuraEnabled
        public Decimal subtotal{get;set;}
        @AuraEnabled
        public Decimal discount{get;set;}
        @AuraEnabled
        public String description{get;set;}
        @AuraEnabled
        public Boolean isSaved{get;set;}
        @AuraEnabled 
        public Boolean isDateEditable{get;set;}
        @AuraEnabled 
        public Boolean isDescriptionEditable{get;set;}
        @AuraEnabled 
        public Boolean isQuantityEditable{get;set;}
        @AuraEnabled 
        public Boolean isSalesPriceEditable{get;set;}
        @AuraEnabled
        public Boolean isDiscountEditable{get;set;}
        @AuraEnabled
        public Boolean isDeletable{get;set;}

        public QuoteLineItemWrapper(QuoteLineItem tempQuoteLineItem){
            this.id = tempQuoteLineItem.id;
            this.serviceDate = tempQuoteLineItem.ServiceDate;
            this.pricebookEntryId = tempQuoteLineItem.PricebookEntryId;
            this.productName = tempQuoteLineItem.PricebookEntry.Name;
            this.quantity = tempQuoteLineItem.Quantity; 
            this.listPrice = tempQuoteLineItem.ListPrice;
            this.salesPrice = tempQuoteLineItem.UnitPrice;
            this.totalPrice = tempQuoteLineItem.TotalPrice;
            this.subtotal = tempQuoteLineItem.Subtotal;
            this.discount = tempQuoteLineItem.Discount;
            this.description = tempQuoteLineItem.Description;
            this.isSaved = true;
            this.isDeletable = tempQuoteLineItem.UserRecordAccess.HasDeleteAccess;
            this.isDiscountEditable = tempQuoteLineItem.UserRecordAccess.HasEditAccess &&
                Schema.sObjectType.QuoteLineItem.fields.Discount.isUpdateable();
            this.isSalesPriceEditable = tempQuoteLineItem.UserRecordAccess.HasEditAccess &&
                Schema.sObjectType.QuoteLineItem.fields.UnitPrice.isUpdateable();
            this.isQuantityEditable = tempQuoteLineItem.UserRecordAccess.HasEditAccess &&
                Schema.sObjectType.QuoteLineItem.fields.Quantity.isUpdateable();
            this.isDescriptionEditable = tempQuoteLineItem.UserRecordAccess.HasEditAccess &&
                Schema.sObjectType.QuoteLineItem.fields.Description.isUpdateable();
            this.isDateEditable = tempQuoteLineItem.UserRecordAccess.HasEditAccess &&
                Schema.sObjectType.QuoteLineItem.fields.ServiceDate.isUpdateable();
        }

        public QuoteLineItem convertToQuoteLineItem(Id quoteId){
            QuoteLineItem result = new QuoteLineItem(ServiceDate = this.serviceDate, QuoteId = quoteId,
            PricebookEntryId = this.pricebookEntryId, Quantity = this.Quantity, UnitPrice = this.salesPrice,
            Discount = this.discount, Description = this.description);
            if(this.isSaved)
            {
                result.Id = this.id;
            }
            return result;
        }
    }
}