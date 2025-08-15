trigger TaskTrigger on Task (after update, after insert) {
    if (!Trigger.isAfter) return;
    
    Set<Id> oliIds = new Set<Id>();
    
    if(Trigger.isInsert){
        List<Task_Change_Notification__e> events = new List<Task_Change_Notification__e>();

        for (Task t : Trigger.new) {
            if (t.Opportunity_Product__c != null ) { 
                events.add(new Task_Change_Notification__e(
                    OpportunityId__c = t.Opportunity_Product__c
                ));
            }
        }
    	// Refresh the component with new task creations
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
    
    if (Trigger.isUpdate) {
        // include old & new in case WhatId moved between OLIs
        oliIds.addAll(TaskRollupService.collectOliIdsFromTasks(Trigger.new));
    }

    if (!oliIds.isEmpty()) {
        TaskRollupService.recalculateCompletedValuePerOli(oliIds);
        Set<Id> oppIds = ProjectTrackerService.parentOppsFromOliIds(oliIds);
        if (!oppIds.isEmpty()) {
            ProjectTrackerService.recomputeFor(oppIds, 'Task Change',oliIds);
        }
    }
}