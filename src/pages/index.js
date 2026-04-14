import React from 'react';
import { graphql, Link } from 'gatsby';

import Layout from '../components/layout';
import SEO from '../components/seo';
import Hero from '../components/hero';
import Tagline from '../components/tagline';
import Highlights from '../components/highlights';

const OSCAL_PAGES = [
  { path: '/oscal_ssp/', label: 'System Security Plan (SSP)' },
  { path: '/oscal_profile/', label: 'Profile' },
  { path: '/oscal_catalog/', label: 'Catalog' },
  { path: '/oscal_component/', label: 'Component Definition' },
  { path: '/oscal_poam/', label: 'Plan of Action & Milestones (POA&M)' },
  { path: '/oscal_assessment-plan/', label: 'Security Assessment Plan (SAP)' },
  { path: '/oscal_assessment-results/', label: 'Security Assessment Results (SAR)' },
];

const BROKERPAK_PROVIDERS = [
  {
    cloud: 'Amazon Web Services',
    badge: 'AWS',
    repo: 'https://github.com/GSA-TTS/csb-brokerpak-aws',
    description: 'S3, RDS PostgreSQL/MySQL (db.t3.micro), ElastiCache Redis (t2.micro), SQS standard queues.',
    note: 'Multi-AZ, read replicas, and large instance classes are disabled in the sandbox tier.',
  },
  {
    cloud: 'Google Cloud Platform',
    badge: 'GCP',
    repo: 'https://github.com/GSA-TTS/csb-brokerpak-gcp',
    description: 'BigQuery (on-demand), Cloud SQL Postgres (db-f1-micro), Pub/Sub, GCS (10-day lifecycle), Memorystore Redis (1 GB BASIC).',
    note: 'All resources deploy into a dedicated sandbox GCP project; HA and PITR are disabled.',
  },
  {
    cloud: 'Microsoft Azure',
    badge: 'Azure',
    repo: 'https://github.com/GSA-TTS/csb-brokerpak-azure',
    description: 'PostgreSQL Flexible Server (B1ms), Azure SQL (Basic 2 DTU), Redis Cache (C0), Storage (LRS), Event Hubs (Basic 1 TU).',
    note: 'Resources deploy into a dedicated resource group per CF space; zone redundancy is disabled.',
  },
];

const IndexPage = ({ data }) => {
  const docs = data?.allMarkdownRemark?.edges || [];

  return (
    <Layout>
      <SEO title="Home" />
      <Hero />
      <Tagline />
      <Highlights />

      <div className="grid-container usa-section">

        {/* ── Multi-Cloud Brokerpaks ── */}
        <h2>Multi-Cloud Brokerpaks</h2>
        <p className="usa-intro">
          Pre-approved service tiers across three clouds, provisioned via a single{' '}
          <code>cf create-service</code> command. Each brokerpak is an OpenTofu-backed
          OSBAPI service with built-in 8-hour TTL enforcement and mandatory resource tagging.
        </p>
        <div className="grid-row grid-gap-md">
          {BROKERPAK_PROVIDERS.map(({ cloud, badge, repo, description, note }) => (
            <div key={badge} className="tablet:grid-col-12 desktop:grid-col-4 margin-bottom-3">
              <div className="usa-card">
                <div className="usa-card__container">
                  <div className="usa-card__header">
                    <h3 className="usa-card__heading">
                      <span className="usa-tag margin-right-1">{badge}</span>
                      {cloud}
                    </h3>
                  </div>
                  <div className="usa-card__body">
                    <p className="font-body-xs">{description}</p>
                    <p className="font-body-2xs text-base-dark margin-top-1">
                      <em>{note}</em>
                    </p>
                  </div>
                  <div className="usa-card__footer">
                    <a
                      href={repo}
                      className="usa-button usa-button--outline"
                      target="_blank"
                      rel="noreferrer noopener"
                    >
                      View Brokerpak
                    </a>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* ── Service Approval ── */}
        <div className="usa-alert usa-alert--info margin-top-4 margin-bottom-4" role="region" aria-label="Service Approval">
          <div className="usa-alert__body">
            <h4 className="usa-alert__heading">Service Approval Policy</h4>
            <p className="usa-alert__text">
              Only pre-approved services can be provisioned. Unapproved service requests return{' '}
              <code>HTTP 503</code> and CI automatically opens a GitHub Issue tagged{' '}
              <code>service-approval-request</code>. TechOps reviews and merges approvals into the
              brokerpak catalog. Conditionally-approved services document usage restrictions inline.
            </p>
          </div>
        </div>

        {/* ── OSCAL Security Controls ── */}
        <h2 className="margin-top-5">OSCAL Security Controls</h2>
        <p className="font-body-sm text-base-dark margin-bottom-3">
          Machine-readable OSCAL content — SSP, catalog, component definitions, and POA&amp;M —
          is maintained for every service broker and resource type. Updated automatically when
          brokerpak catalogs change or Prowler findings require new POA&amp;M items.
        </p>
        <div className="grid-row grid-gap-md">
          {OSCAL_PAGES.map(({ path, label }) => (
            <div key={path} className="tablet:grid-col-6 desktop:grid-col-4 margin-bottom-3">
              <div className="usa-card">
                <div className="usa-card__container">
                  <div className="usa-card__header">
                    <h3 className="usa-card__heading">
                      <Link to={path}>{label}</Link>
                    </h3>
                  </div>
                  <div className="usa-card__body">
                    <p className="font-body-xs text-base-dark">
                      View metadata, roles, parties, and model sections for this OSCAL document.
                    </p>
                  </div>
                  <div className="usa-card__footer">
                    <Link to={path} className="usa-button usa-button--outline">
                      View
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* ── Security Scanning ── */}
        <h2 className="margin-top-5">Security Scanning — Prowler</h2>
        <div className="grid-row grid-gap-md">
          <div className="tablet:grid-col-8">
            <p>
              The <strong>Prowler</strong> submodule provides continuous third-party assessment
              across all three CSP accounts. Scans run CIS Benchmark and FedRAMP Moderate checks
              for AWS, GCP, and Azure. Findings are ingested into the OSCAL assessment results
              document and HIGH/CRITICAL issues are promoted to POA&amp;M items automatically.
            </p>
            <p className="font-body-xs text-base-dark">
              Scan results are exported to the TTS audit S3 bucket on each run.
            </p>
          </div>
          <div className="tablet:grid-col-4">
            <a
              href="https://github.com/GSA-TTS/prowler"
              className="usa-button margin-bottom-2 width-full"
              target="_blank"
              rel="noreferrer noopener"
            >
              Prowler Repository
            </a>
            <Link to="/oscal_assessment-results/" className="usa-button usa-button--outline width-full">
              Assessment Results (SAR)
            </Link>
          </div>
        </div>

        {/* ── Documentation Pages ── */}
        {docs.length > 0 && (
          <>
            <h2 className="margin-top-5">Documentation Pages</h2>
            <ul className="usa-list">
              {docs.map(({ node }) => (
                <li key={node.fields.name}>
                  <Link to={`/${node.fields.name}/`}>{node.frontmatter.title}</Link>
                </li>
              ))}
            </ul>
          </>
        )}

      </div>
    </Layout>
  );
};

export const pageQuery = graphql`
  query IndexDocumentationQuery {
    allMarkdownRemark(filter: { fields: { sourceName: { eq: "documentation" } } }) {
      edges {
        node {
          fields {
            name
          }
          frontmatter {
            title
          }
        }
      }
    }
  }
`;

export default IndexPage;
