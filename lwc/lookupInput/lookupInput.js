import { LightningElement, api, track } from 'lwc';
import fetchRecords from '@salesforce/apex/LookupInputController.fetchRecords';

export default class LookupInput extends LightningElement {
    @api objectName;
    @api fieldName;
    @api value;
    @api iconName;
    @api label;
    @api placeholder;
    @api className;
    @api required = false;
    @api conditions;
    @track searchString;
    @track selectedRecord;
    @track recordsList;
    @track message;
    @track showPill = false;
    @track showSpinner = false;
    @track showDropdown = false;
 
    connectedCallback() {
        if(this.value)
            this.fetchData();
    }
 
    searchRecords(event) {
        this.searchString = event.target.value;
        if(this.searchString) {
            this.fetchData();
        } else {
            this.showDropdown = false;
        }
    }
 
    selectItem(event) {
        if(event.currentTarget.dataset.key) {
    		var index = this.recordsList.findIndex(x => x.value === event.currentTarget.dataset.key)
            if(index != -1) {
                this.selectedRecord = this.recordsList[index];
                this.value = this.selectedRecord.value;
                this.showDropdown = false;
                this.showPill = true;
                this.dispatchEvent(new CustomEvent("objectchange", {detail: {objectId: this.selectedRecord.value}}));
            }
        }
    }
 
    removeItem() {
        this.showPill = false;
        this.value = '';
        this.selectedRecord = '';
        this.searchString = '';
        this.dispatchEvent(new CustomEvent("objectchange", {detail: {objectId: false}}));
    }
 
    showRecords() {
        if(this.recordsList && this.searchString) {
            this.showDropdown = true;
        }
    }
 
    blurEvent() {
        this.showDropdown = false;
    }
 
    fetchData() {
        this.showSpinner = true;
        this.message = '';
        this.recordsList = [];
        fetchRecords({
            objectName : this.objectName,
            filterField : this.fieldName,
            searchString : this.searchString,
            value : this.value,
            conditionString: JSON.stringify(this.conditions)
        })
        .then(result => {
            if(result && result.length > 0) {
                if(this.value) {
                    this.selectedRecord = result[0];
                    this.showPill = true;
                } else {
                    this.recordsList = result;
                }
            } else {
                this.message = "No Records Found for '" + this.searchString + "'";
            }
            this.showSpinner = false;
        }).catch(error => {
            this.message = error.message;
            this.showSpinner = false;
        })
        if(!this.value) {
            this.showDropdown = true;
        }
    }
}