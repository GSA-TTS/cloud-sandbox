import express from 'express';
import { createBackendPlugin, coreServices } from '@backstage/backend-plugin-api';
import { InputError } from '@backstage/errors';

type CloudProvider = 'aws' | 'gcp' | 'azure';
type Plan = 'sandbox' | 'managed';
type OperationType = 'provision' | 'deprovision' | 'update' | 'scan';
type OperationState = 'queued' | 'in-progress' | 'succeeded' | 'failed';

export type ProvisionRequest = {
  provider: CloudProvider;
  accountName: string;
  owner: string;
  environment: 'sandbox' | 'dev' | 'test' | 'prod';
  costCenter?: string;
  ttlHours?: number;
  complianceProfile?: 'baseline' | 'moderate' | 'high';
};

export type BrokerOperation = {
  operationId: string;
  type: OperationType;
  state: OperationState;
  provider: CloudProvider;
  requestedAt: string;
  resourceRef: string;
  nextActions: string[];
};

type Instance = { plan: Plan; request: ProvisionRequest; operationId: string };
const providers: CloudProvider[] = ['aws', 'gcp', 'azure'];
const environments = ['sandbox', 'dev', 'test', 'prod'];
const profiles = ['baseline', 'moderate', 'high'];
const ownerRef = /^group:[a-z0-9][a-z0-9-]{0,62}\/[a-z0-9][a-z0-9-]{0,62}$/;
const safeName = /^[a-z0-9][a-z0-9-]{2,62}$/;
const safeCostCenter = /^[a-z0-9][a-z0-9-]{0,62}$/;

function inputError(message: string): never {
  throw new InputError(message);
}

function requireObject(value: unknown, message: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) inputError(message);
  return value as Record<string, unknown>;
}

function onlyKeys(input: Record<string, unknown>, keys: string[]): void {
  if (Object.keys(input).some(key => !keys.includes(key))) inputError('Request contains unsupported fields');
}

export function assertProvisionRequest(body: unknown, plan: Plan): ProvisionRequest {
  const request = requireObject(body, 'Request body is required');
  onlyKeys(request, [
    'provider',
    'accountName',
    'owner',
    'environment',
    'costCenter',
    'ttlHours',
    'complianceProfile',
  ]);
  if (typeof request.provider !== 'string' || !providers.includes(request.provider as CloudProvider))
    inputError('provider must be one of aws, gcp, azure');
  if (typeof request.accountName !== 'string' || !safeName.test(request.accountName))
    inputError('accountName must be a lowercase DNS-safe name');
  if (typeof request.owner !== 'string' || !ownerRef.test(request.owner))
    inputError('owner must be a lowercase group:<namespace>/<name> entity ref');
  if (typeof request.environment !== 'string' || !environments.includes(request.environment))
    inputError('environment must be sandbox, dev, test, or prod');
  if (request.costCenter !== undefined && (typeof request.costCenter !== 'string' || !safeCostCenter.test(request.costCenter)))
    inputError('costCenter must be a lowercase identifier');
  if (request.complianceProfile !== undefined && (typeof request.complianceProfile !== 'string' || !profiles.includes(request.complianceProfile)))
    inputError('complianceProfile must be baseline, moderate, or high');
  if (plan === 'sandbox') {
    if (request.environment !== 'sandbox') inputError('sandbox plan requires sandbox environment');
    if (request.ttlHours === undefined) request.ttlHours = 1;
    if (!Number.isInteger(request.ttlHours) || request.ttlHours < 1 || request.ttlHours > 8)
      inputError('sandbox ttlHours must be an integer from 1 through 8');
  } else {
    if (request.environment === 'sandbox') inputError('managed plan cannot use sandbox environment');
    if (request.ttlHours !== undefined) inputError('managed plan does not accept ttlHours');
  }
  return request as ProvisionRequest;
}

export function createInMemoryBroker(now = () => new Date()) {
  const instances = new Map<string, Instance>();
  const operations = new Map<string, BrokerOperation>();
  let sequence = 0;
  const createOperation = (type: OperationType, provider: CloudProvider, resourceRef: string) => {
    const operation: BrokerOperation = {
      operationId: `${type}-${provider}-${++sequence}`,
      type,
      state: 'queued',
      provider,
      requestedAt: now().toISOString(),
      resourceRef,
      nextActions: [
        'local mock only: no provider workflow submitted',
        'no account, project, subscription, catalog entity, or Prowler scan was created',
      ],
    };
    operations.set(operation.operationId, operation);
    return operation;
  };
  return {
    provision(instanceId: string, plan: Plan, request: ProvisionRequest) {
      const existing = instances.get(instanceId);
      if (existing) {
        if (existing.plan !== plan || JSON.stringify(existing.request) !== JSON.stringify(request))
          return { status: 409, body: { error: 'instance ID conflicts with an existing request' } };
        return { status: 200, body: { operation: existing.operationId, dashboard_url: null } };
      }
      const operation = createOperation('provision', request.provider, `resource:default/${request.provider}-${request.accountName}`);
      instances.set(instanceId, { plan, request: structuredClone(request), operationId: operation.operationId });
      return { status: 202, body: { operation: operation.operationId, dashboard_url: null } };
    },
    update(instanceId: string, input: unknown) {
      const instance = instances.get(instanceId);
      if (!instance) return { status: 404, body: { error: 'instance not found' } };
      const update = requireObject(input, 'Update body is required');
      onlyKeys(update, ['ttlHours']);
      if (instance.plan !== 'sandbox') return { status: 409, body: { error: 'managed lifecycle updates are not implemented' } };
      if (!Number.isInteger(update.ttlHours) || (update.ttlHours as number) < 1 || (update.ttlHours as number) > 8)
        return { status: 400, body: { error: 'sandbox ttlHours must be an integer from 1 through 8' } };
      instance.request.ttlHours = update.ttlHours as number;
      const operation = createOperation('update', instance.request.provider, `resource:default/${instance.request.provider}-${instance.request.accountName}`);
      return { status: 202, body: { operation: operation.operationId } };
    },
    deprovision(instanceId: string) {
      const instance = instances.get(instanceId);
      if (!instance) return { status: 404, body: { error: 'instance not found' } };
      const operation = createOperation('deprovision', instance.request.provider, `resource:default/${instance.request.provider}-${instance.request.accountName}`);
      instances.delete(instanceId);
      return { status: 202, body: { operation: operation.operationId } };
    },
    operation(operationId: string) {
      const operation = operations.get(operationId);
      if (!operation) return null;
      operation.state = operation.state === 'queued' ? 'in-progress' : operation.state;
      return structuredClone(operation);
    },
    scan(instanceId: string) {
      const instance = instances.get(instanceId);
      if (!instance) return { status: 404, body: { error: 'instance not found' } };
      const operation = createOperation('scan', instance.request.provider, `resource:default/${instance.request.provider}-${instance.request.accountName}`);
      return { status: 202, body: { scanId: operation.operationId, state: 'queued', synthetic: true } };
    },
  };
}

export function createAccountProvisioningRouter(broker = createInMemoryBroker()) {
  const router = express.Router();
  router.use(express.json({ limit: '8kb' }));
  router.get('/v2/catalog', (_req, res) => {
    res.json({ services: [{ id: 'platform-cloud-account', name: 'platform-cloud-account', description: 'Local account broker skeleton; no cloud provisioning.', bindable: false, plan_updateable: true, plans: [{ id: 'sandbox', name: 'sandbox', description: 'Local synthetic request with a 1-8 hour TTL policy.' }, { id: 'managed', name: 'managed', description: 'Local synthetic request; provider lifecycle is not implemented.' }] }] });
  });
  router.put('/v2/service_instances/:instanceId', (req, res) => {
    const input = requireObject(req.body, 'Request body is required');
    onlyKeys(input, ['service_id', 'plan_id', 'parameters']);
    if (input.service_id !== 'platform-cloud-account' || !['sandbox', 'managed'].includes(input.plan_id as string))
      throw new InputError('service_id and plan_id must select a documented account plan');
    const request = assertProvisionRequest(input.parameters, input.plan_id as Plan);
    const result = broker.provision(req.params.instanceId, input.plan_id as Plan, request);
    res.status(result.status).json(result.body);
  });
  router.patch('/v2/service_instances/:instanceId', (req, res) => {
    const input = requireObject(req.body, 'Update body is required');
    onlyKeys(input, ['parameters']);
    const result = broker.update(req.params.instanceId, input.parameters);
    res.status(result.status).json(result.body);
  });
  router.delete('/v2/service_instances/:instanceId', (req, res) => {
    const result = broker.deprovision(req.params.instanceId);
    res.status(result.status).json(result.body);
  });
  router.get('/v2/service_instances/:instanceId/last_operation', (req, res) => {
    const operationId = typeof req.query.operation === 'string' ? req.query.operation : '';
    const operation = broker.operation(operationId);
    if (!operation) return res.status(404).json({ error: 'operation not found' });
    res.json({ state: operation.state, description: operation.nextActions.join('; ') });
  });
  router.post('/instances/:instanceId/prowler/scans', (req, res) => {
    const result = broker.scan(req.params.instanceId);
    res.status(result.status).json(result.body);
  });
  return router;
}

export default createBackendPlugin({
  pluginId: 'account-provisioning',
  register(env) {
    env.registerInit({
      deps: { httpRouter: coreServices.httpRouter, logger: coreServices.logger },
      async init({ httpRouter, logger }) {
        logger.info('Registering local-only account provisioning skeleton routes');
        httpRouter.use(createAccountProvisioningRouter());
      },
    });
  },
});
