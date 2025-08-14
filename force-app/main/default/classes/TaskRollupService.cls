public class TaskRollupService {

    public static Set<Id> collectOliIdsFromTasks(List<Task> tasks){
        Set<Id> oliIds = new Set<Id>();
        for (Task t : tasks) {
            if (t.Opportunity_Product__c != null && t.Status =='Completed' && t.Is_Internal_Task__c==false) {
                oliIds.add(t.Opportunity_Product__c);
            }
        } 
        return oliIds;
    }

    public static void recalculateCompletedValuePerOli(Set<Id> oliIds){
        if (oliIds == null || oliIds.isEmpty()) return;

        Map<Id, Decimal> sums = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Opportunity_Product__c w, SUM(Contributed_Value__c) s
            FROM Task
            WHERE Opportunity_Product__c IN :oliIds
              AND Status = 'Completed'
              AND Is_Internal_Task__c = false
            GROUP BY Opportunity_Product__c
        ]) {
            sums.put((Id)ar.get('w'), (Decimal)ar.get('s'));
        }

        List<OpportunityLineItem> updatesOLI = new List<OpportunityLineItem>();
        for (Id oliId : oliIds) {
            Decimal sum = sums.containsKey(oliId) ? sums.get(oliId) : 0;
            updatesOLI.add(new OpportunityLineItem(Id = oliId, Completed_Phase_Value__c = sum));
        }
        if (!updatesOLI.isEmpty()) update updatesOLI;
    }
}