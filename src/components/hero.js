import React from "react";
import { Link } from "gatsby";

/*
  Homepage hero — summarises the CSB sandbox lifecycle platform.
*/

const Hero = () => (
  <section className="usa-hero">
    <div className="grid-container">
      <div className="usa-hero__callout">
        <h2 className="usa-hero__heading">
          <span className="usa-hero__heading--alt">CSB Sandbox</span>
          Lifecycle &amp; Cost Governance
        </h2>
        <p>
          Self-service multi-cloud provisioning for AWS, GCP, and Azure with automatic 8-hour
          deprovisioning, a $500/mo budget ceiling, OSCAL-maintained security controls, and
          continuous Prowler scanning — all on cloud.gov.
        </p>
        <Link className="usa-button" to="/oscal_ssp/">
          View Security Plan
        </Link>
        <Link className="usa-button usa-button--outline margin-left-1" to="/oscal_component/">
          OSCAL Components
        </Link>
      </div>
    </div>
  </section>
);

export default Hero;
