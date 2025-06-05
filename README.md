Project documents are also available on the [PSC-DFO Species Composition Review SharePoint site](https://psconline.sharepoint.com/sites/FRP_365/Species%20Composition%20Review/Forms/AllItems.aspx)

# Qualark Species Composition Reproducible Data Product Team Charter

**Title:** Qualark Species Composition Reproducible Task Team\
**Date Initiated:** [Insert Date]

**Stakeholders:**

Daniel Doutaz: Lead operational biologist, but can use R. Mid-August Daniel will be very busy. Early Phases Daniel is available.

Michael

Brian Smith: Moving in to Marissa's Position

Kaitlynn Dionne:

------------------------------------------------------------------------

## 1. Purpose

To recreate the Qualark Species Composition Database that, Pacific Salmon Commission Staff are prototyping, in the DFO cloud environment to fulfill a clear operational need using transparent, automated, and interoperable processes. This product will serve as a flagship case study, demonstrating end-to-end stewardship from data ingestion through public dissemination and support Fraser Interior Area Staff.

## 2. Problem Statement

------------------------------------------------------------------------

## 3. Objectives

-   Deliver a **reproducible** version of [Insert Data Product Name], updated on a regular cadence.
-   Use this case to **formalize governance structures**—assigning roles and decision authority for data formatting, pipelines, and publication.
-   Leverage **cloud platforms** (Azure Lakehouse, Databricks) and **open code practices** (e.g., GitHub workflows).
-   Demonstrate interoperability by mapping variables to standards such as **Darwin Core**, **CF Conventions**, and the **NCEAS Salmon Ontology**.
-   Publish results to the **Pacific Salmon Data Portal**, **Open Government Portal**, and **Enterprise Data Hub**.

------------------------------------------------------------------------

## 4. Deliverables

-   A working, documented ETL pipeline for the data product
-   A published code repository (e.g., GitHub or Azure Repos)
-   Governance documentation: Data Owner, Trustee, Steward roles and escalation paths
-   Data schema aligned with DFO and international standards
-   Reproducibility documentation (data source manifest, lineage, version history)
-   Public-facing product: dashboards, tables, or downloads

------------------------------------------------------------------------

## 5. Team Roles

| Role | Name | Responsibilities |
|----|----|----|
| Task Team Leads | Catarina Wor (Brooke once back from Mat Leave), Brett Johnson, Eric Taylor | Oversees project delivery, coordinates cross support |
| Data Trustee | ? | Chairs the Data Product Governance Team. Usually a section head or higher. Coordinates with Salmon Data Domain Governance Team and the Regional Data Committee. |
| Data Steward | Daniel | Owns the product lifecycle and ensures documentation. Typically someone with field and data skills. |
| Data Custodian | Michael Gauthier? | Someone responsible for the data system. Will eventually manage Azure/Databricks infrastructure |
| Data Engineers | Sai (PSC), DSU Staff | Builds ETL pipeline and manages Azure/DataBricks infrastructure |
| Domain Experts | Paul Van Dam Bates, Anna Potapova | Defines product requirements and validates outputs |
| Governance Liaison(s) | Brett Johnson | Coordinates with Office of the Chieft Data Steward and RegionaDC for approvals and alignment |

## 6. Data Product Governance Team

| Role | Name | Responsibilities |
|----|----|----|
| Data Owner | [Insert Name] | Owns the data and its quality |
| Data Trustee | Catarina Wor? Brooke? | Chairs the Data Product Governance Team |
| Data Steward | [Insert Name] | Owns the product lifecycle and ensures documentation |

------------------------------------------------------------------------

## 7. Timeline (Proposed)

| Phase | Duration | Milestone |
|----|----|----|
| Kickoff and Scoping | 2 weeks | Charter signed off, roles confirmed |
| Infrastructure Setup | 2–4 weeks | Azure workspace, data storage, GitHub repo ready |
| Pipeline Development | 4–6 weeks | First reproducible version created |
| Governance and Standards Review | Concurrent | Schema and roles approved |
| Final Publication & Reporting | 2–3 weeks | Output published, lessons learned shared |

------------------------------------------------------------------------

## 8. Success Criteria

-   Output is reproducible end-to-end using only the shared codebase and cloud resources
-   The product is trusted and adopted by Area staff
-   Time to update the product is reduced by \>50%
-   Clear governance structure established and documented
-   Published product receives endorsement by PSDCoP or RDC

------------------------------------------------------------------------

## 9. Dependencies

-   Technical: Integration of Microsoft Purview with Azure Lakehouse
-   People: Engagement from regional subject-matter experts and data contributors
-   Process: Coordination with governance units to endorse decisions

------------------------------------------------------------------------

## 10. Risks & Mitigation

| Risk | Mitigation Strategy |
|----|----|
| Staff bandwidth | Scope narrowly and provide flexible contribution paths |
| Data access delays | Formalize data sharing agreements early |
| Cloud complexity | Use DSU support and standard infrastructure templates |
| Governance ambiguity | Escalate unclear decisions to RDC or OCDS early |

------------------------------------------------------------------------

## 11. Contact

For more information or to get involved, contact:\
**[Task Team Lead Name]**, [[email\@example.com](mailto:email@example.com){.email}]\
Or reach out to **Brett Johnson**, Data Stewardship Unit: [Brett.Johnson\@dfo-mpo.gc.ca](mailto:Brett.Johnson@dfo-mpo.gc.ca){.email}
