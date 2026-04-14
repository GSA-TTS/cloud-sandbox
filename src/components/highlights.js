import React from 'react';
import circle from '../../node_modules/uswds/dist/img/circle-124.png';

/*
  Four key outcomes from the CSB sandbox lifecycle proposal.
*/

const Highlights = () => (
  <section className="usa-graphic-list usa-section usa-section--dark">
    <div className="grid-container">
      <div className="usa-graphic-list__row grid-row grid-gap">
        <div className="usa-media-block tablet:grid-col">
          <img className="usa-media-block__img" src={circle} alt="" />
          <div className="usa-media-block__body">
            <h3 className="usa-graphic-list__heading">Zero idle cloud spend.</h3>
            <p>
              Every sandbox instance carries an 8-hour TTL. The TTL controller
              auto-deprovisions on expiry with a single 4-hour renewal allowed.
              No manual cleanup, no forgotten resources.
            </p>
          </div>
        </div>
        <div className="usa-media-block tablet:grid-col">
          <img className="usa-media-block__img" src={circle} alt="" />
          <div className="usa-media-block__body">
            <h3 className="usa-graphic-list__heading">Hard budget guardrails.</h3>
            <p>
              A $500/month ceiling is enforced across AWS, GCP, and Azure.
              Alerts fire at 80%; sandbox provisioning suspends at 100%.
              Anomaly spikes trigger automatic instance termination.
            </p>
          </div>
        </div>
      </div>
      <div className="usa-graphic-list__row grid-row grid-gap">
        <div className="usa-media-block tablet:grid-col">
          <img className="usa-media-block__img" src={circle} alt="" />
          <div className="usa-media-block__body">
            <h3 className="usa-graphic-list__heading">OSCAL-maintained controls.</h3>
            <p>
              Every service broker and resource type has a machine-readable OSCAL
              component definition. The SSP, catalog, and POA&amp;M stay current
              alongside the brokerpak catalog and Prowler scan results.
            </p>
          </div>
        </div>
        <div className="usa-media-block tablet:grid-col">
          <img className="usa-media-block__img" src={circle} alt="" />
          <div className="usa-media-block__body">
            <h3 className="usa-graphic-list__heading">Continuous security scanning.</h3>
            <p>
              Prowler runs CIS and FedRAMP Moderate checks across all three CSP
              accounts. HIGH and CRITICAL findings are promoted automatically to
              POA&amp;M items in the OSCAL assessment results.
            </p>
          </div>
        </div>
      </div>
    </div>
  </section>
);

export default Highlights;
