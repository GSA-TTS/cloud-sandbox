import React from "react";

/*
  Homepage tagline — one-liner on the left, expanded detail on the right.
*/

const Tagline = () => (
  <section className="grid-container usa-section usa-prose">
    <div className="grid-row grid-gap">
      <div className="tablet:grid-col-4">
        <h2 className="font-heading-xl margin-top-0 tablet:margin-bottom-0">
          Provision. Govern. Deprovision.
        </h2>
      </div>
      <div className="tablet:grid-col-8 usa-prose">
        <p>
          The TTS sandbox platform uses the Cloud Foundry Cloud Service Broker (CSB) and
          OpenTofu-backed brokerpaks to give engineers single-command access to pre-approved AWS,
          GCP, and Azure services. Every instance carries a built-in 8-hour TTL, enforced tagging,
          and a hard $500/month budget ceiling.
        </p>
        <p>
          Security controls for every provisioned resource are captured as OSCAL component
          definitions, continuously assessed by Prowler across all three cloud accounts, and
          surfaced here alongside the live FedRAMP Moderate profile.
        </p>
      </div>
    </div>
  </section>
);

export default Tagline;
