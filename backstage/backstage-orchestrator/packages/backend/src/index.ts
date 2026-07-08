/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import crypto from 'node:crypto';
import { createBackend } from '@backstage/backend-defaults';
import { createBackendModule } from '@backstage/backend-plugin-api';
import {
  authProvidersExtensionPoint,
  createOAuthProviderFactory,
  type OAuthAuthenticatorResult,
  type SignInResolver,
} from '@backstage/plugin-auth-node';
import {
  oidcAuthenticator,
  oidcSignInResolvers,
  type OidcAuthResult,
} from '@backstage/plugin-auth-backend-module-oidc-provider';

const backend = createBackend();

backend.add(import('@backstage/plugin-app-backend'));
backend.add(import('@backstage/plugin-proxy-backend'));

// scaffolder plugin
backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
backend.add(
  import('@backstage/plugin-scaffolder-backend-module-notifications'),
);

// techdocs plugin
backend.add(import('@backstage/plugin-techdocs-backend'));

// auth plugin
backend.add(import('@backstage/plugin-auth-backend'));

const cloudGovOidcAuthenticator = {
  ...oidcAuthenticator,
  scopes: {
    ...oidcAuthenticator.scopes,
    required: ['openid'],
  },
};

const cloudGovSignInResolver: SignInResolver<
  OAuthAuthenticatorResult<OidcAuthResult>
> = async ({ result }, ctx) => {
  const subject = result.fullProfile.tokenset.claims().sub;
  if (!subject) {
    throw new Error('cloud.gov OIDC token is missing a subject claim');
  }

  const userEntityRef = `user:default/cloudgov-${crypto
    .createHash('sha256')
    .update(subject)
    .digest('hex')
    .slice(0, 16)}`;

  return ctx.issueToken({
    claims: {
      sub: userEntityRef,
      ent: [userEntityRef],
    },
  });
};

backend.add(
  createBackendModule({
    pluginId: 'auth',
    moduleId: 'cloudgov-oidc-provider',
    register(reg) {
      reg.registerInit({
        deps: {
          providers: authProvidersExtensionPoint,
        },
        async init({ providers }) {
          providers.registerProvider({
            providerId: 'oidc',
            factory: createOAuthProviderFactory({
              authenticator: cloudGovOidcAuthenticator,
              signInResolver: cloudGovSignInResolver,
              signInResolverFactories: {
                ...oidcSignInResolvers,
              },
            }),
          });
        },
      });
    },
  }),
);

// catalog plugin
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);

// See https://backstage.io/docs/features/software-catalog/configuration#subscribing-to-catalog-errors
backend.add(import('@backstage/plugin-catalog-backend-module-logs'));

// permission plugin
backend.add(import('@backstage/plugin-permission-backend'));
// See https://backstage.io/docs/permissions/getting-started for how to create your own permission policy
import { policyExtensionPoint } from '@backstage/plugin-permission-node/alpha';
import {
  PermissionPolicy,
  PolicyQuery,
  PolicyQueryUser,
} from '@backstage/plugin-permission-node';
import {
  AuthorizeResult,
  PolicyDecision,
} from '@backstage/plugin-permission-common';

class RequireAuthPermissionPolicy implements PermissionPolicy {
  async handle(
    _request: PolicyQuery,
    user?: PolicyQueryUser,
  ): Promise<PolicyDecision> {
    if (user) {
      return { result: AuthorizeResult.ALLOW };
    }
    return { result: AuthorizeResult.DENY };
  }
}

backend.add(
  createBackendModule({
    pluginId: 'permission',
    moduleId: 'custom-policy',
    register(reg) {
      reg.registerInit({
        deps: { policy: policyExtensionPoint },
        async init({ policy }) {
          policy.setPolicy(new RequireAuthPermissionPolicy());
        },
      });
    },
  }),
);

// search plugin
backend.add(import('@backstage/plugin-search-backend'));

// search engine
// See https://backstage.io/docs/features/search/search-engines
backend.add(import('@backstage/plugin-search-backend-module-pg'));

// search collators
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));

// kubernetes plugin
backend.add(import('@backstage/plugin-kubernetes-backend'));

// notifications and signals plugins
backend.add(import('@backstage/plugin-notifications-backend'));
backend.add(import('@backstage/plugin-signals-backend'));

// mcp actions plugin
backend.add(import('@backstage/plugin-mcp-actions-backend'));

backend.start();
