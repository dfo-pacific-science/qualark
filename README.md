# Qualark

Tracking work, code, etc needed to house the Qualark data system in DFO.

## Additional Resources
Project documents are also available on the [PSC-DFO Species Composition Review SharePoint site](https://psconline.sharepoint.com/sites/FRP_365/Species%20Composition%20Review/Forms/AllItems.aspx)


# Qualark Species Composition Reproducible Data Product Team Charter

**Title:** [Insert Data Product Name] Reproducible Task Team  
**Date Initiated:** [Insert Date]  
**Lead Proposer:** [Insert Name, e.g., Brett Johnson]  
**Supporting Units:**  
- Data Stewardship Unit (DSU)  
- PSSI Strategic Data Policy & Analytics Team  
- Office of the Chief Data Steward (OCDS)  
- Pacific Salmon Data Community of Practice (PSDCoP)

---

## 1. Purpose

To create a reproducible data product that fulfills a clear operational need using transparent, automated, and interoperable processes. This product will serve as a flagship case study, demonstrating end-to-end stewardship from data ingestion through public dissemination.

---

## 2. Problem Statement

Currently, producing this data product involves redundant and error-prone manual work—collating, reformatting, and syncing disparate datasets across programs and systems. There is a lack of clear authority on standards, and version control issues delay decision-making and reduce trust in outputs.

---

## 3. Objectives

- Deliver a **reproducible** version of [Insert Data Product Name], updated on a regular cadence.
- Use this case to **formalize governance structures**—assigning roles and decision authority for data formatting, pipelines, and publication.
- Leverage **cloud platforms** (Azure Lakehouse, Databricks) and **open code practices** (e.g., GitHub workflows).
- Demonstrate interoperability by mapping variables to standards such as **Darwin Core**, **CF Conventions**, and the **NCEAS Salmon Ontology**.
- Publish results to the **Pacific Salmon Data Portal**, **Open Government Portal**, and **Enterprise Data Hub**.

---

## 4. Deliverables

- A working, documented ETL pipeline for the data product
- A published code repository (e.g., GitHub or Azure Repos)
- Governance documentation: Data Owner, Trustee, Steward roles and escalation paths
- Data schema aligned with DFO and international standards
- Reproducibility documentation (data source manifest, lineage, version history)
- Public-facing product: dashboards, tables, or downloads

---

## 5. Team Roles

| Role                 | Name           | Responsibilities                                           |
|----------------------|----------------|------------------------------------------------------------|
| Task Team Lead       | [Insert Name]  | Oversees project delivery, coordinates cross-unit support  |
| Data Product Steward | [Insert Name]  | Owns the product lifecycle and ensures documentation       |
| Data Engineer        | [Insert Name]  | Builds ETL pipeline and manages Azure/DataBricks infra     |
| Domain Expert (Area) | [Insert Name]  | Defines product requirements and validates outputs         |
| Governance Liaison   | [Insert Name]  | Coordinates with OCDS and RDC for approvals and alignment  |

---

## 6. Timeline (Proposed)

| Phase                            | Duration     | Milestone                                           |
|----------------------------------|--------------|-----------------------------------------------------|
| Kickoff and Scoping              | 2 weeks      | Charter signed off, roles confirmed                |
| Infrastructure Setup             | 2–4 weeks    | Azure workspace, data storage, GitHub repo ready   |
| Pipeline Development             | 4–6 weeks    | First reproducible version created                 |
| Governance and Standards Review  | Concurrent   | Schema and roles approved                          |
| Final Publication & Reporting    | 2–3 weeks    | Output published, lessons learned shared           |

---

## 7. Success Criteria

- Output is reproducible end-to-end using only the shared codebase and cloud resources
- The product is trusted and adopted by Area staff
- Time to update the product is reduced by >50%
- Clear governance structure established and documented
- Published product receives endorsement by PSDCoP or RDC

---

## 8. Dependencies

- Technical: Integration of Microsoft Purview with Azure Lakehouse
- People: Engagement from regional subject-matter experts and data contributors
- Process: Coordination with governance units to endorse decisions

---

## 9. Risks & Mitigation

| Risk                   | Mitigation Strategy                                        |
|------------------------|------------------------------------------------------------|
| Staff bandwidth        | Scope narrowly and provide flexible contribution paths     |
| Data access delays     | Formalize data sharing agreements early                    |
| Cloud complexity       | Use DSU support and standard infrastructure templates      |
| Governance ambiguity   | Escalate unclear decisions to RDC or OCDS early            |

---

## 10. Contact

For more information or to get involved, contact:  
**[Task Team Lead Name]**, [email@example.com]  
Or reach out to **Brett Johnson**, Data Stewardship Unit: Brett.Johnson@dfo-mpo.gc.ca
