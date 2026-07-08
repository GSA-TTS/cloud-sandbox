import { Content, Header, InfoCard, Page } from '@backstage/core-components';
import { OAuth2 } from '@backstage/core-app-api';
import {
  configApiRef,
  createFrontendModule,
  discoveryApiRef,
  oauthRequestApiRef,
  useApi,
  type IdentityApi,
} from '@backstage/frontend-plugin-api';
import { createApp } from '@backstage/frontend-defaults';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import notificationsPlugin from '@backstage/plugin-notifications/alpha';
import Button from '@material-ui/core/Button';
import Grid from '@material-ui/core/Grid';
import Typography from '@material-ui/core/Typography';
import { useEffect, useState, type ReactNode } from 'react';
import { navModule } from './modules/nav';

type CloudGovSignInPageProps = {
  onSignInSuccess(identityApi: IdentityApi): void;
  children?: ReactNode;
};

function CloudGovSignInPage({ onSignInSuccess }: CloudGovSignInPageProps) {
  const configApi = useApi(configApiRef);
  const discoveryApi = useApi(discoveryApiRef);
  const oauthRequestApi = useApi(oauthRequestApiRef);
  const [error, setError] = useState<string>();

  const authApi = OAuth2.create({
    discoveryApi,
    oauthRequestApi,
    configApi,
    provider: {
      id: 'oidc',
      title: 'cloud.gov',
      icon: () => null,
    },
    defaultScopes: ['openid'],
    environment: 'production',
  });

  const completeSignIn = async (options?: { instantPopup?: boolean }) => {
    setError(undefined);

    const backstageIdentity = await authApi.getBackstageIdentity({
      ...options,
      optional: !options?.instantPopup,
    });

    if (!backstageIdentity) {
      return;
    }

    const profile = await authApi.getProfile();
    const identityApi: IdentityApi & {
      getUserId(): string;
      getIdToken(): Promise<string | undefined>;
      getProfile(): typeof profile;
    } = {
      getUserId() {
        const match = /^([^:/]+:)?([^:/]+\/)?([^:/]+)$/.exec(
          backstageIdentity.identity.userEntityRef,
        );
        return match?.[3] ?? backstageIdentity.identity.userEntityRef;
      },
      async getIdToken() {
        const identity = await authApi.getBackstageIdentity();
        return identity.token;
      },
      getProfile() {
        return profile;
      },
      async getProfileInfo() {
        return authApi.getProfile();
      },
      async getBackstageIdentity() {
        return backstageIdentity.identity;
      },
      async getCredentials() {
        const identity = await authApi.getBackstageIdentity();
        return { token: identity.token };
      },
      async signOut() {
        await authApi.signOut();
      },
    };

    onSignInSuccess(identityApi);
  };

  useEffect(() => {
    completeSignIn().catch(err => setError(String(err)));
  }, []);

  return (
    <Page themeId="home">
      <Header title={configApi.getString('app.title')} />
      <Content>
        <Grid container justifyContent="center" spacing={2} component="ul">
          <Grid item xs={12} sm={6} md={4} component="li">
            <InfoCard
              title="cloud.gov"
              variant="fullHeight"
              actions={
                <Button
                  color="primary"
                  variant="outlined"
                  onClick={() =>
                    completeSignIn({ instantPopup: true }).catch(err =>
                      setError(String(err)),
                    )
                  }
                >
                  Sign In
                </Button>
              }
            >
              <Typography variant="body1">Sign in with cloud.gov</Typography>
              {error && (
                <Typography variant="body1" color="error">
                  {error}
                </Typography>
              )}
            </InfoCard>
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
}

const oidcSignInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => CloudGovSignInPage,
  },
});

const oidcSignInModule = createFrontendModule({
  pluginId: 'app',
  extensions: [oidcSignInPage],
});

export default createApp({
  features: [
    catalogPlugin,
    notificationsPlugin,
    navModule,
    oidcSignInModule,
  ],
});
