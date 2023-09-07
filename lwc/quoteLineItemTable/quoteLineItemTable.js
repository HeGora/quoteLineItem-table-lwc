import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getQuoteLineItems from '@salesforce/apex/QuoteController.getQuoteLineItems';
import getData from '@salesforce/apex/QuoteController.getData';
import dmlOnQuoteLineItems from '@salesforce/apex/QuoteController.dmlOnQuoteLineItems';
import getPricebookEntry from '@salesforce/apex/QuoteController.getPricebookEntry';


import discountLabel from '@salesforce/label/c.QuoteLineItemDiscount';
import subtotalLabel from '@salesforce/label/c.QuoteLineItemSubtotal';
import listPriceLabel from '@salesforce/label/c.QuoteLineItemListPrice';
import descriptionLabel from '@salesforce/label/c.QuoteLineItemDescription';
import dateLabel from '@salesforce/label/c.QuoteLineItemDate';
import productLabel from '@salesforce/label/c.QuoteLineItemProduct';
import quantityLabel from '@salesforce/label/c.QuoteLineItemQuantity';
import salesPriceLabel from '@salesforce/label/c.QuoteLineItemSalesPrice';
import totalPriceLabel from '@salesforce/label/c.QuoteLineItemTotalPrice';
import saveLabel from '@salesforce/label/c.Save';
import cancelLabel from '@salesforce/label/c.Cancel';
import addProductLabel from '@salesforce/label/c.AddProduct';
import quoteSubtotalLabel from '@salesforce/label/c.QuoteSubtotal';
import quoteTotalPriceLabel from '@salesforce/label/c.QuoteTotalPrice';
import PRICEBOOK_ENTRY from '@salesforce/schema/PricebookEntry';
import PRICEBOOK_ENTRY_NAME from '@salesforce/schema/PricebookEntry.Name';
import PRICEBOOK_ENTRY_LIST_PRICE from '@salesforce/schema/PricebookEntry.UnitPrice';
import PRICEBOOK_NAME from '@salesforce/schema/Pricebook2.Name';


export default class QuoteLineItemTable extends LightningElement {

    PRICEBOOK_ENTRY_OBJECT = {
        object: PRICEBOOK_ENTRY.objectApiName,
        name: PRICEBOOK_ENTRY_NAME.fieldApiName,
        listPrice: PRICEBOOK_ENTRY_LIST_PRICE.fieldApiName
    };

    labels = {
        discount: discountLabel,
        subtotal: subtotalLabel,
        listPrice: listPriceLabel,
        description: descriptionLabel,
        date: dateLabel,
        product: productLabel,
        quantity: quantityLabel,
        salesPrice: salesPriceLabel,
        totalPrice: totalPriceLabel,
        save: saveLabel,
        cancel: cancelLabel,
        addProduct: addProductLabel,
        quoteSubtotal: quoteSubtotalLabel,
        quoteTotalPrice: quoteTotalPriceLabel
    };

    @api pricebookEntryConditions; //conditions for pricebookEntry lookup input component
    @api recordId; //id of the Quote
    @api isSaveButtonDisabled = false;
    @api quoteSubtotal;
    @api quoteTotalPrice;
    @track quoteLineItemList = []; //Quote Line Items related to Quote
    deleteRecordList = []; //Quote Line Items to delete on save;
    lastFakeRowNumber = 0;
    
    connectedCallback(){
        getData({quoteId: this.recordId})
        .then(result => {
            this.pricebookEntryConditions = result.pricebookConditions;
            this.quoteLineItemList = JSON.parse(JSON.stringify(result.quoteLineItems));
            this.calculateQuoteTotals();
            this.applyFakeRowNumbers();
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error reading quote line items',
            error.body.message, 'Error', 'dismissable');
        })
    }

    loadData(){
        this.isSaveButtonDisabled = true;
        getQuoteLineItems({quoteId: this.recordId})
        .then(result => {
                this.quoteLineItemList = JSON.parse(JSON.stringify(result));
                this.calculateQuoteTotals();
                this.applyFakeRowNumbers();
        })
        .catch(error => {
            console.error(JSON.stringify(error.body.message));
            this.showToast('Error reading quote line items',
            error.body.message, 'Error', 'dismissable');
        });
        this.isSaveButtonDisabled = false;
    }

    handleStandardInputChange(event){
        const item = this.quoteLineItemList[this.findItemIndexByEventTarget(event)];
        item[event.target.name] = event.detail.value;
        this.recalculateItemTotals(item);
    }

    handleDescriptionChange(event){
        const item = this.quoteLineItemList[this.findItemIndexByEventTarget(event)];
        item[event.target.name] = event.target.innerText;
    }

    handleProductChange(event)
    {
        const item = this.quoteLineItemList[this.findItemIndexByEventTarget(event)];
        if(event.detail.objectId){
            getPricebookEntry({pricebookEntryId: event.detail.objectId})
            .then(result => {
                item.pricebookEntryId = event.detail.objectId;
                item.listPrice = result;
                item.salesPrice = result;
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                return;
            })
        }
        else{
            item.listPrice = 0;
            item.salesPrice = 0;
        }
        item.pricebookEntryId = event.detail.objectId;
        item.date = '';
        item.description = '';
        item.quantity = 0;
        item.discount = 0;
        this.recalculateItemTotals(item);
    }

    handleDelete(event){
        const deleteId = event.target.dataset.id;
        const item = this.quoteLineItemList[this.findItemIndexByEventTarget(event)];
        if(item.isSaved){
            this.deleteRecordList = [...this.deleteRecordList, deleteId]; 
        }
        this.quoteLineItemList = this.quoteLineItemList.filter(row => {
            return row.id != deleteId
        });
        this.applyFakeRowNumbers();
    }

    handleSave(event){
        if(this.validateData()){
            this.isSaveButtonDisabled = true;
            dmlOnQuoteLineItems({itemsToSave: JSON.stringify(this.quoteLineItemList),
                itemsToDelete: this.deleteRecordList, quoteId: this.recordId})
            .then(() => {
                this.showToast('Success', 'Changes are saved', 'Success', 'dismissable');
                this.loadData();
                this.deleteRecordList = [];
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.showToast('Error updating or refreshing records',
                        error.body.message, 'Error', 'dismissable');
                this.isSaveButtonDisabled = false;
            })
        }
        else{
            this.showToast('Please, complete the table properly before saving',
            '', 'Warning', 'dismissible');
        }
    }

    handleCancel(event){
        this.dispatchEvent(new CustomEvent('close'));
        this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
    }

    handleAddProduct(event){
        let randomId = Math.random() * 16;
        this.lastFakeRowNumber++;
        let newItem = {
            id: randomId,
            quoteId: this.recordId,
            isSaved: false,
            listPrice: 0,
            salesPrice: 0,
            totalPrice: 0,
            subtotal: 0,
            date: '',
            description: '',
            quantity: 0,
            discount: 0,
            fakeRowNumber: this.lastFakeRowNumber,
            isDiscountEditable: true,
            isSalesPriceEditable: true,
            isQuantityEditable: true,
            isDescriptionEditable: true,
            isDateEditable: true,
            isDeletable: true,
        }
        this.quoteLineItemList = [...this.quoteLineItemList, newItem];
    }

    validateData(){
        let result = true;
        this.quoteLineItemList.forEach(item =>{
            if(item.quantity <= 0 || item.discount < 0 || !item.pricebookEntryId)
                result = false
        });
        return result;
    }

    recalculateItemTotals(item)
    {
        this.quoteSubtotal -= item.subtotal;
        this.quoteTotalPrice -= item.totalPrice;
        item.subtotal = item.quantity*item.salesPrice;
        item.totalPrice = item.subtotal*(100 - item.discount)/100;
        this.quoteSubtotal += item.subtotal;
        this.quoteSubtotal = this.quoteSubtotal ? this.quoteSubtotal.toFixed(2) : 0;
        this.quoteTotalPrice += item.totalPrice;
        this.quoteTotalPrice = this.quoteTotalPrice ? this.quoteTotalPrice.toFixed(2) : 0;
    }

    calculateQuoteTotals(){
        let newSubtotal = 0;
        let newTotalPrice = 0;
        this.quoteLineItemList.forEach((item) =>{
            newSubtotal += item.subtotal;
            newTotalPrice += item.totalPrice;
        })
        this.quoteSubtotal = newSubtotal ? newSubtotal.toFixed(2) : newSubtotal;
        this.quoteTotalPrice = newTotalPrice ? newTotalPrice.toFixed(2) : newTotalPrice;
    }

    applyFakeRowNumbers(){
        let fakeRowNumber = 0;
        this.quoteLineItemList.forEach((item) => {
            ++fakeRowNumber;
            item.fakeRowNumber = fakeRowNumber;
        });
        this.lastFakeRowNumber = fakeRowNumber;
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    findItemIndexByEventTarget(event) {
        return this.quoteLineItemList.findIndex(row => row.id == event.target.dataset.id);
    }
}