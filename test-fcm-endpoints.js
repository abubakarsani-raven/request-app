#!/usr/bin/env node

/**
 * FCM Endpoint Test Script
 * 
 * This script:
 * 1. Logs in to get a JWT token
 * 2. Tests the FCM status endpoint
 * 3. Tests sending a test FCM notification
 */

const http = require('http');

const API_BASE_URL = 'http://192.168.1.172:4000';

// Available seed users (choose one to test with):
const SEED_USERS = {
  admin: { email: 'admin@example.com', password: '12345678', name: 'Admin User' },
  administrator: { email: 'administrator@example.com', password: 'Admin@2024', name: 'System Administrator' },
  driver: { email: 'driver@example.com', password: 'Driver@2024', name: 'John Driver' },
  supervisor: { email: 'supervisor@example.com', password: 'Supervisor@2024', name: 'Jane Supervisor' },
  ddict: { email: 'ddict@example.com', password: 'DDICT@2024', name: 'ICT Director' },
  storeofficer: { email: 'storeofficer@example.com', password: 'SO@2024', name: 'Store Officer' },
  ddgs: { email: 'ddgs@example.com', password: 'DDGS@2024', name: 'Deputy Director General Services' },
  adgs: { email: 'adgs@example.com', password: 'ADGS@2024', name: 'Assistant Director General Services' },
  transportofficer: { email: 'transportofficer@example.com', password: 'TO@2024', name: 'Transport Officer' },
};

// Use DDGS user (most likely to have FCM token if they've used the mobile app)
const TEST_USER = SEED_USERS.ddgs;
const TEST_EMAIL = TEST_USER.email;
const TEST_PASSWORD = TEST_USER.password;

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function makeRequest(method, path, token = null, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port || 4000,
      path: url.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({ status: res.statusCode, data: jsonData });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

async function testFCMEndpoints() {
  log('\n🧪 FCM Endpoint Test Script\n', 'cyan');
  log('='.repeat(60), 'cyan');

  try {
    // Step 1: Login
    log('\n📝 Step 1: Logging in...', 'blue');
    const loginResponse = await makeRequest('POST', '/auth/login', null, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    });

    if (loginResponse.status !== 200) {
      log(`❌ Login failed: ${loginResponse.status}`, 'red');
      log(`Response: ${JSON.stringify(loginResponse.data, null, 2)}`, 'red');
      return;
    }

    const token = loginResponse.data.access_token;
    const user = loginResponse.data.user;
    
    log(`✅ Login successful!`, 'green');
    log(`   User: ${user.name} (${user.email})`, 'green');
    log(`   Roles: ${user.roles?.join(', ') || 'None'}`, 'green');
    log(`   Level: ${user.level || 'N/A'}`, 'green');
    log(`   Token: ${token.substring(0, 20)}...`, 'green');

    // Step 2: Check FCM Status
    log('\n📊 Step 2: Checking FCM Status...', 'blue');
    const statusResponse = await makeRequest('GET', '/notifications/fcm-status', token);

    if (statusResponse.status === 200) {
      const status = statusResponse.data;
      log(`✅ FCM Status retrieved`, 'green');
      log(`   FCM Configured: ${status.fcmConfigured ? '✅ Yes' : '❌ No'}`, status.fcmConfigured ? 'green' : 'red');
      log(`   User Has Token: ${status.userHasToken ? '✅ Yes' : '❌ No'}`, status.userHasToken ? 'green' : 'yellow');
      if (status.tokenPreview) {
        log(`   Token Preview: ${status.tokenPreview}`, 'cyan');
      }
      log(`   Message: ${status.message}`, 'cyan');
    } else {
      log(`❌ Failed to get FCM status: ${statusResponse.status}`, 'red');
      log(`Response: ${JSON.stringify(statusResponse.data, null, 2)}`, 'red');
    }

    // Step 3: Send Test Notification
    log('\n📤 Step 3: Sending Test FCM Notification...', 'blue');
    const testResponse = await makeRequest('POST', '/notifications/test-fcm', token);

    if (testResponse.status === 200) {
      const result = testResponse.data;
      log(`✅ Test notification request completed`, 'green');
      log(`   Success: ${result.success ? '✅ Yes' : '❌ No'}`, result.success ? 'green' : 'red');
      log(`   FCM Configured: ${result.fcmConfigured ? '✅ Yes' : '❌ No'}`, result.fcmConfigured ? 'green' : 'red');
      log(`   User Has Token: ${result.userHasToken ? '✅ Yes' : '❌ No'}`, result.userHasToken ? 'green' : 'yellow');
      
      if (result.success) {
        log(`\n   🎉 ${result.message}`, 'green');
        log(`   Check your mobile device for the test notification!`, 'cyan');
      } else {
        log(`\n   ⚠️  ${result.message}`, 'yellow');
        if (result.error) {
          log(`   Error: ${result.error}`, 'red');
        }
      }
    } else {
      log(`❌ Failed to send test notification: ${testResponse.status}`, 'red');
      log(`Response: ${JSON.stringify(testResponse.data, null, 2)}`, 'red');
    }

    log('\n' + '='.repeat(60), 'cyan');
    log('✅ Test completed!', 'green');

  } catch (error) {
    log(`\n❌ Error: ${error.message}`, 'red');
    if (error.code === 'ECONNREFUSED') {
      log('   Make sure the backend server is running on http://192.168.1.172:4000', 'yellow');
    }
    log(`\nStack trace: ${error.stack}`, 'red');
  }
}

// Run the test
testFCMEndpoints();
