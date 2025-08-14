import { LightningElement, api, wire, track } from 'lwc';
import getTasksForOpportunity from '@salesforce/apex/ProjectTaskController.getTasksForOpportunity';
import updateTasks from '@salesforce/apex/ProjectTaskController.updateTasks';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe, onError } from 'lightning/empApi';

export default class ProjectTaskManager extends LightningElement {
    channelName = '/event/Task_Change_Notification__e';

    @api recordId;
    wiredOpportunitiesResult; // store wired result here
    @track rows = [];
    @track filteredRows = [];
    @track draftValues = [];
    @track loading = true;

    progressPercent = 0;
    numerator = 0;
    denominator = 0;
    stamped = false;
    stampDateTime;

    searchKey = '';
    selectedIds = new Set();

    columns = [
        { label: 'Subject', fieldName: 'subject', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text'},
        { label: 'Due Date', fieldName: 'dueDate', type: 'date'},
        { label: 'Contributed Value', fieldName: 'contributedValue', type: 'number', editable: true, cellAttributes: { alignment: 'left' } },
        { label: 'Internal?', fieldName: 'isInternal', type: 'boolean'}
    ];

    get disableMarkCompleted() {
        return this.selectedIds.size === 0;
    }

    connectedCallback() {
        console.log('called Connected callback');
        this.handleSubscribe();
    }

    handleSubscribe() {
        subscribe(this.channelName, -1, (message) => {
            const payload = message.data.payload;
            console.log('Inside event');
            if (payload.OpportunityId__c) {
                console.log('Refresh Wire');
                refreshApex(this.wiredOpportunitiesResult);
            }
        });

        onError(error => {
            console.error('Subscription error: ', error);
        });
    }

    @wire(getTasksForOpportunity, { opportunityId: '$recordId' })
    wiredData(result) {
        this.loading = false;
        this.wiredOpportunitiesResult = result; // save reference
        if (result.data) {
            this.rows = result.data.rows || [];
            this.applySearch();
            const p = result.data.progress || {};
            this.numerator = p.numerator || 0;
            this.denominator = p.denominator || 0;
            this.progressPercent = p.percent || 0;
            this.stamped = !!p.stamped;
            this.stampDateTime = p.stampDate ? new Date(p.stampDate).toLocaleString() : '';
        } else if (result.error) {
            this.showToast('Error', this.reduceError(result.error), 'error');
        }
    }

    handleSearchChange(e) {
        this.searchKey = e.target.value || '';
        this.applySearch();
    }

    applySearch() {
        const key = (this.searchKey || '').toLowerCase();
        this.filteredRows = key
        ? this.rows.filter(r => (r.subject || '').toLowerCase().includes(key))
        : this.rows;
    }

    handleRowSelection(event){
        this.selectedIds = new Set((event.detail.selectedRows || []).map(r => r.id));
    }

    async handleMarkCompleted() {
        if (this.selectedIds.size === 0) return;
        try {
        this.loading = true;
        const updates = Array.from(this.selectedIds).map(id => ({ Id: id, Status: 'Completed' }));
        await updateTasks({ tasks: updates });
        this.showToast('Success', 'Selected tasks marked Completed', 'success');
        await this.refreshWire();
        refreshApex(this.wiredOpportunitiesResult);
        } catch (err) {
        this.showToast('Error', this.reduceError(err), 'error');
        } finally {
        this.loading = false;
        }
    }

    async handleSave(event) {
        const drafts = event.detail.draftValues;
        if (!drafts || drafts.length === 0) return;
        try {
            this.loading = true;
            // Only pass editable fields we support
            const updates = drafts.map(d => {
                const u = { Id: d.id };
                if (d.status !== undefined) u.Status = d.status;
                if (d.dueDate !== undefined) u.ActivityDate = d.dueDate;
                if (d.contributedValue !== undefined) u.Contributed_Value__c = d.contributedValue;
                if (d.isInternal !== undefined) u.Is_Internal_Task__c = d.isInternal;
                if (d.oliId !== undefined) u.Opportunity_Product__c = d.oliId; 
                return u;
            });
            console.log('Update called',JSON.stringify(updates))
            await updateTasks({ tasks: updates });
            this.draftValues = [];
            this.showToast('Success', 'Tasks updated', 'success');
            await this.refreshWire();
            refreshApex(this.wiredOpportunitiesResult);
        } catch (err) {
            this.showToast('Error', this.reduceError(err), 'error');
        } finally {
            this.loading = false;
        }
    }

    handleCancel() {
        this.draftValues = [];
    }

    async refreshWire() {
        // Simple way: re-invoke the wire by toggling a param (or use refreshApex with a wired value)
        this.loading = true;
        const res = await getTasksForOpportunity({ opportunityId: this.recordId });
        this.rows = res.rows || [];
        this.applySearch();
        const p = res.progress || {};
        this.numerator = p.numerator || 0;
        this.denominator = p.denominator || 0;
        this.progressPercent = p.percent || 0;
        this.stamped = !!p.stamped;
        this.stampDateTime = p.stampDate ? new Date(p.stampDate).toLocaleString() : '';
        this.loading = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
        return error.body.map(e => e.message).join(', ');
        } else if (typeof error?.body?.message === 'string') {
        return error.body.message;
        }
        return 'Unexpected error';
    }
}
