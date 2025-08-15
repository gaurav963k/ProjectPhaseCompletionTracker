# Project Phase Completion Tracker &amp; Task Manager

## 📌 Overview
This Salesforce solution automates project phase completion tracking and provides an intuitive interface for managing tasks linked to project phases.

- **Projects** → Represented by **Opportunity** records.
- **Phases** → Represented by **Opportunity Line Items (OLIs)**.
- **Milestones / Sub-tasks** → Represented by **Task** records linked to OLIs.

The system automatically stamps the **Project 80% Complete Date** on the Opportunity when completed task values reach **80% of total project value** and enforces a **one-time update rule**.  
Additionally, a custom **Lightning Web Component (LWC)** enables users to view and update related tasks directly from the Opportunity page.

---

## 🎯 Problem Statement
The business needs:
1. **Automated 80% Completion Tracking**
   - When cumulative completed task values across all OLIs reach 80% of the total OLI values for an Opportunity.
   - Stamp the date/time and mark as complete — **only once**.
   - Ignore internal tasks from completion calculations.
   - Log completion progress in history.

2. **User-Friendly Task Management**
   - Display all related tasks for an Opportunity in a single interface.
   - Enable inline status updates.
   - Provide a clean, intuitive UI.

---

## Getting Started
1.	Take a look at the [component](https://github.com/gaurav963k/ProjectPhaseCompletionTracker/wiki/Component-Overview) overview.
2.	[Data Model](https://github.com/gaurav963k/ProjectPhaseCompletionTracker/wiki/Data-Model) Impelemted
3.	Screenshot of project 
<img width="966" height="416" alt="Screenshot 2025-08-15 at 9 23 27 PM" src="https://github.com/user-attachments/assets/50582340-4b6d-4ea6-9e7f-fb8699206f61" />
<img width="960" height="348" alt="image" src="https://github.com/user-attachments/assets/6f5f9c5b-36e8-42fa-a195-da9dbff09bb8" />




---

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
