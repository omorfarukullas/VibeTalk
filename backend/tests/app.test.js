/**
 * Basic health check test for the VibeTalk backend.
 */

describe('Backend Smoke Tests', () => {
  beforeAll(() => {
    // Mock environment variables for test
    process.env.PORT = '3001';
    process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
    process.env.REDIS_URL = 'redis://localhost:6379';
    process.env.JWT_SECRET = 'test_jwt_secret_minimum_32_chars!!';
    process.env.JWT_REFRESH_SECRET = 'test_jwt_refresh_secret_min_32_chars!!';
    process.env.FIREBASE_PROJECT_ID = 'test-project';
    process.env.FIREBASE_PRIVATE_KEY = 'test-key';
    process.env.FIREBASE_CLIENT_EMAIL = 'test@test.iam.gserviceaccount.com';
    process.env.CLOUDFLARE_R2_BUCKET = 'test-bucket';
    process.env.CLOUDFLARE_R2_ACCESS_KEY = 'test-access-key';
    process.env.CLOUDFLARE_R2_SECRET_KEY = 'test-secret-key';
    process.env.CLOUDFLARE_R2_ENDPOINT = 'https://test.r2.cloudflarestorage.com';
    process.env.SENTRY_DSN = 'https://test@sentry.io/1';
  });

  test('app module loads without errors', () => {
    const app = require('../src/app');
    expect(app).toBeDefined();
    expect(typeof app).toBe('function');
  });

  test('app responds to health check', async () => {
    const http = require('http');
    const app = require('../src/app');

    const server = http.createServer(app);

    await new Promise((resolve) => server.listen(0, resolve));
    const { port } = server.address();

    const response = await fetch(`http://localhost:${port}/api/health`);
    const body = await response.json();

    expect(body.success).toBe(true);
    expect(body.data.status).toBe('healthy');
    expect(body.data.services.server).toBe('running');

    await new Promise((resolve) => server.close(resolve));
  });

  test('404 handler returns proper error', async () => {
    const http = require('http');
    const app = require('../src/app');

    const server = http.createServer(app);

    await new Promise((resolve) => server.listen(0, resolve));
    const { port } = server.address();

    const response = await fetch(`http://localhost:${port}/api/nonexistent`);
    const body = await response.json();

    expect(response.status).toBe(404);
    expect(body.success).toBe(false);
    expect(body.error.code).toBe('NOT_FOUND');

    await new Promise((resolve) => server.close(resolve));
  });
});
