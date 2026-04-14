# GCP Approved Service Conditions

Generated from in-house tracking list on 2026-04-14.

For each approved service, document usage caveats, configuration requirements, protocols, and settings.

## App Engine (Standard and Flexible)

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Compute Engine

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## BigQuery

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Dataflow

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Dataproc

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Pub/Sub

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Bigtable

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Firestore

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Memorystore

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud spanner

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud SQL

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Container Registry

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud DNS

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Virtual Private cloud (VPC)

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud HSM

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Key Management Service

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Identity & Access Management (IAM)

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Storage

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Persistent Disk

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Google Kubernetes Engine

- In-house status: `FedRAMP Authorized - High & Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AutoML Natural Language

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes:
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AutoML Tables

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AutoML Translation

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AutoML Video

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AutoML Vision

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Natural Language API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Translation

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Vision

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Dialogflow Essentials

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes:
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Dialogflow Customer Experience Edition (CX)

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Speech-to-Text

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Text-to-Speech

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Video Intelligence API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Talent Solution

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Apigee

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Endpoints

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Healthcare

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Composer

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Data Fusion

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Life Sciences (Genomics)

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Data Catalog

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Datalab

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Datastore

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Build

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Source Repositories

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Console App

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Deployment Manager

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Shell

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Service Management API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Service Consumer Management API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Service Control API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## BigQuery Data Transfer Service

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Storage Transfer Service

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud CDN

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Interconnect

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Load Balancing

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud NAT (Network Address Translation)

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Router

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud VPN

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Google Cloud Armor

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Network Service Tiers

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Access Transparency

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Data Loss Prevention

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Security Command Center

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## VPC Service Controls

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Web Security Scanner

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Access Context Manager

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Google Cloud Identity-Aware Proxy

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Identity Platform

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Resource Manager API

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Filestore

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Debugger

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Logging

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Monitoring

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Profiler

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Trace

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## AI Platform Training and Prediction

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Notebooks

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Run

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Functions

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## IoT Core

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Google Cloud Platform Marketplace

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: No explicit caveats in source list; apply baseline controls from SSP/OSCAL, least privilege IAM, private networking, encryption in transit/at rest, and required sandbox tags.
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Cloud Asset Inventory

- In-house status: `GSA OCISO Approved`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Event Threat Detection

- In-house status: `GSA OCISO Approved`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.

## Secret Manager

- In-house status: `FedRAMP Authorized - Moderate`
- Conditions / notes: Ancillary support services that do not directly store or process data or provide security support realted functions. Service complement existing approved services and whose security is provided by GCP and/or GCP environment of operation
- Required baseline configuration:
  - Use non-production sandbox plans only (no HA / multi-AZ unless explicitly approved).
  - Enforce tagging: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Restrict public exposure; prefer private endpoints/network controls where available.
  - Log all access and changes for audit traceability.
