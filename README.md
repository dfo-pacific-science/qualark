Project documents are also available on the [PSC-DFO Species Composition Review SharePoint site](https://psconline.sharepoint.com/sites/FRP_365/Species%20Composition%20Review/Forms/AllItems.aspx)

# Qualark Species Composition Reproducible Data Product Team Charter

Title: Qualark Species Composition Data System

Date Initiated: 2025-04-02

Stakeholders:

Daniel Doutaz: Lead operational biologist, but can use R. Mid-August Daniel will be very busy. Early Phases Daniel is available.

Michael Arbeider

Brian Smith: Moving in to Marissa's Position

Kaitlynn Dionne:

------------------------------------------------------------------------

## 1. Purpose

To recreate the Qualark Species Composition Database that, Pacific Salmon Commission (PSC) Staff are prototyping in the PSC's Azure environment, in the DFO cloud environment to fulfill a clear operational need using transparent, automated, and interoperable processes. The database aims to consolidate counts, recorded sonar lengths, test fishing catch and biological data, and the results of the Qualark species composition model into a single, accessible platform. This product will serve as a flagship case study, demonstrating end-to-end stewardship from data ingestion through public dissemination and support Fraser Interior Area Staff.

## 2. Problem Statement

-   Data scattered in multiple Excel files & text exports (DIDSON/ARIS).

-   Manual data entry → prone to errors, delays.

-   Limited QA/QC checks before data is used for analysis.

-   Data not centralized → difficulty consolidating for in in-season or post-season analysis.

------------------------------------------------------------------------

## 3. Objectives

-   Streamline data processing and storage, improve data management efficiency, enhance data analysis capabilities in order to support species composition assessments.
-   **Development of a Centralized Database:** Create a centralized database for Qualark hydroacoustic and test fishing data, consolidating data from multiple sources into one unified repository.
-   **Integration with R:** Enable seamless integration with R for data querying, analysis, and visualization.
-   **Data Backup and Recovery Mechanisms:** Establish robust data backup procedures and recovery mechanisms to prevent data loss and ensure data availability.
-   **Data Management Workflow:** Define workflows where administrators manage data uploads, receive updates from crew members through Excel files. This maintains familiar processes, ensuring smooth collaboration and minimal disruptions.
-   **Potential for Future Integration:** Design the system to allow for future integration via APIs or with other databases.
-   Use this case to **formalize governance structures**—assigning roles and decision authority for data formatting, pipelines, and publication.

------------------------------------------------------------------------

## 4. Deliverables

-   A working, documented ETL pipeline that implements QA/QC and serves the data in a SQL database
-   A published code repository (e.g., GitHub or Azure Repos)
-   Governance documentation: Data Owner, Trustee, Steward roles and escalation paths
-   Data output from the SQL database that can be shared with the Pacific Salmon Commission staff with daily updates.

------------------------------------------------------------------------

## 5. Team Roles

+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Role               | Name                                                           | Responsibilities                                                                                                                                                                                                                                                                                                                                                       |
+====================+================================================================+========================================================================================================================================================================================================================================================================================================================================================================+
| Task Team Leads    | Brett Johnson, Eric Taylor                                     | Oversees project delivery, coordinates cross organizational collaboration and support                                                                                                                                                                                                                                                                                  |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Data Trustee       | Catarina Wor (Brooke?)                                         | Data Trustees ensure the strategic management of assigned data assets as well as compliance with departmental and enterprise data-related strategies, regulations, policies, directives and standards. Chairs the Data Product Governance Team. Usually a section head or higher. Coordinates with Salmon Data Domain Governance Team and the Regional Data Committee. |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Data Steward       | -   Daniel Doutaz (DFO FIA, Long-term maintainer)              | Data Stewards maximize the quality and reusability of their assigned data asset by enforcing data management business rules. Owns the product lifecycle and ensures documentation.                                                                                                                                                                                     |
|                    |                                                                |                                                                                                                                                                                                                                                                                                                                                                        |
|                    | -   Zhipeng Wu (DFO DSU, Initial development and transfer)     |                                                                                                                                                                                                                                                                                                                                                                        |
|                    |                                                                |                                                                                                                                                                                                                                                                                                                                                                        |
|                    | -   Albury C (DFO DSU, Initial development and transfer)       |                                                                                                                                                                                                                                                                                                                                                                        |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Data Custodians    | -   Brian Smith (DFO, Long term maintenance)                   | Data Custodians ensure the safe custody and integrity of hosted data, and safeguarding data repositories, including the design and implementation of technical solutions.                                                                                                                                                                                              |
|                    |                                                                |                                                                                                                                                                                                                                                                                                                                                                        |
|                    | <!-- -->                                                       |                                                                                                                                                                                                                                                                                                                                                                        |
|                    |                                                                |                                                                                                                                                                                                                                                                                                                                                                        |
|                    | -   Sai Chandra (Initial development and prototyping with PSC) |                                                                                                                                                                                                                                                                                                                                                                        |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Data Contributors  | Michael Arbeider                                               | Data Contributors ensure that the data they provide to the Department (including data sourced from third-parties) aligns with all technical and business policies, procedures and standards, including those defined by data stewards.                                                                                                                                 |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Data Consumers     | -   Paul Van Dam Bates (DFO Post Doc)                          | Data Consumers ensure that their usage of data supports departmental and government objectives and mandate, including communicating regularly with data stewards on their data needs.                                                                                                                                                                                  |
|                    |                                                                |                                                                                                                                                                                                                                                                                                                                                                        |
|                    | -   Pacific Salmon Commission Fraser River Panel               |                                                                                                                                                                                                                                                                                                                                                                        |
+--------------------+----------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

------------------------------------------------------------------------

## 7. Timeline (Proposed)

+---------------------------------+----------------------+--------------------------------------------------+
| Phase                           | Duration             | Milestone                                        |
+=================================+======================+==================================================+
| Kickoff and Scoping             | 2 weeks              | Charter signed off, roles confirmed              |
+---------------------------------+----------------------+--------------------------------------------------+
| Infrastructure Setup            | 2–4 weeks            | Azure workspace, data storage, GitHub repo ready |
+---------------------------------+----------------------+--------------------------------------------------+
| Pipeline Development            | 4–6 weeks            | First reproducible version created               |
+---------------------------------+----------------------+--------------------------------------------------+
| Governance and Standards Review | Concurrent           | Schema and roles approved                        |
+---------------------------------+----------------------+--------------------------------------------------+
| Final Publication & Reporting   | 2–3 weeks            | Output published, lessons learned shared         |
+---------------------------------+----------------------+--------------------------------------------------+

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

+----------------------------------+--------------------------------------------------------+
| Risk                             | Mitigation Strategy                                    |
+==================================+========================================================+
| Staff bandwidth                  | Scope narrowly and provide flexible contribution paths |
+----------------------------------+--------------------------------------------------------+
| Data access delays               | Formalize data sharing agreements early                |
+----------------------------------+--------------------------------------------------------+
| Cloud complexity                 | Use DSU support and standard infrastructure templates  |
+----------------------------------+--------------------------------------------------------+
| Governance ambiguity             | Escalate unclear decisions to RDC or OCDS early        |
+----------------------------------+--------------------------------------------------------+

------------------------------------------------------------------------

## 11. Contact

For more information or to get involved, contact:\
**[Task Team Lead Name]**, [[email\@example.com](mailto:email@example.com){.email}]\
Or reach out to **Brett Johnson**, Data Stewardship Unit: [Brett.Johnson\@dfo-mpo.gc.ca](mailto:Brett.Johnson@dfo-mpo.gc.ca){.email}
