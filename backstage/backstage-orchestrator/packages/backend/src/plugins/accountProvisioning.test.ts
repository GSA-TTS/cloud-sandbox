import { assertProvisionRequest, createInMemoryBroker } from './accountProvisioning';

const request = {
  provider: 'aws',
  accountName: 'demo-account',
  owner: 'group:platform/demo-team',
  environment: 'sandbox',
  costCenter: 'demo',
  complianceProfile: 'baseline',
};

describe('account provisioning skeleton', () => {
  it('enforces a bounded sandbox TTL and rejects unsafe input', () => {
    expect(assertProvisionRequest(request, 'sandbox').ttlHours).toBe(1);
    expect(() => assertProvisionRequest({ ...request, ttlHours: 9 }, 'sandbox')).toThrow('ttlHours');
    expect(() => assertProvisionRequest({ ...request, owner: 'person:default/admin' }, 'sandbox')).toThrow('owner');
    expect(() => assertProvisionRequest({ ...request, unexpected: true }, 'sandbox')).toThrow('unsupported');
    expect(() => assertProvisionRequest({ ...request, environment: 'prod' }, 'sandbox')).toThrow('sandbox plan');
    expect(() => assertProvisionRequest({ ...request, environment: 'dev', ttlHours: 1 }, 'managed')).toThrow('managed plan');
  });

  it('is idempotent only for an identical local request and fails closed otherwise', () => {
    const broker = createInMemoryBroker(() => new Date('2026-11-13T00:00:00Z'));
    const approved = assertProvisionRequest(request, 'sandbox');
    const first = broker.provision('demo-instance', 'sandbox', approved);
    expect(first.status).toBe(202);
    expect(broker.provision('demo-instance', 'sandbox', approved).status).toBe(200);
    expect(broker.provision('demo-instance', 'sandbox', { ...approved, accountName: 'other-account' }).status).toBe(409);
    expect(broker.operation(first.body.operation)?.state).toBe('in-progress');
    expect(broker.operation('unknown')).toBeNull();
  });

  it('limits updates and scans to existing local instances', () => {
    const broker = createInMemoryBroker();
    const approved = assertProvisionRequest(request, 'sandbox');
    expect(broker.update('missing', { ttlHours: 2 }).status).toBe(404);
    expect(broker.scan('missing').status).toBe(404);
    broker.provision('demo-instance', 'sandbox', approved);
    expect(broker.update('demo-instance', { ttlHours: 8 }).status).toBe(202);
    expect(broker.update('demo-instance', { ttlHours: 9 }).status).toBe(400);
    expect(broker.scan('demo-instance')).toMatchObject({ status: 202, body: { synthetic: true } });
    expect(broker.deprovision('demo-instance').status).toBe(202);
    expect(broker.deprovision('demo-instance').status).toBe(404);
  });
});
