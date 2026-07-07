import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import notificationsPlugin from '@backstage/plugin-notifications/alpha';
import { navModule } from './modules/nav';

export default createApp({
  features: [catalogPlugin, notificationsPlugin, navModule],
});
