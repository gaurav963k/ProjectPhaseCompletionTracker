trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete) {
    Set<Id> oppIds = new Set<Id>();
    Set<Id> oliIds = new Set<Id>();
    String taskAction;
    if (Trigger.isInsert) {
        for (OpportunityLineItem oli : Trigger.new){
            oppIds.add(oli.OpportunityId);
            oliIds.add(oli.Id);
        }
        taskAction = 'Insert';
    }
    if (Trigger.isUpdate) {
        for (OpportunityLineItem oli : Trigger.new){
            oppIds.add(oli.OpportunityId);
            oliIds.add(oli.Id);
        }
        taskAction = 'Update';
    }
    
    if (!oppIds.isEmpty()) {
        ProjectTrackerService.recomputeForOpportunityLineItem(oppIds, 'OLI value change',oliIds, taskAction);
    }
}