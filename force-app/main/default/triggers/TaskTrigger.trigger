trigger TaskTrigger on Task (after update) {
    if (!Trigger.isAfter) return;
    
    Set<Id> oliIds = new Set<Id>();
    
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