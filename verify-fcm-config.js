#!/usr/bin/env node

/**
 * FCM Configuration Verification Script
 * 
 * This script verifies that Firebase Cloud Messaging (FCM) is properly
 * configured for both backend and mobile app.
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 FCM Configuration Verification\n');
console.log('=' .repeat(60));

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function logSuccess(message) {
  console.log(`${colors.green}✅${colors.reset} ${message}`);
}

function logError(message) {
  console.log(`${colors.red}❌${colors.reset} ${message}`);
}

function logWarning(message) {
  console.log(`${colors.yellow}⚠️${colors.reset} ${message}`);
}

function logInfo(message) {
  console.log(`${colors.blue}ℹ️${colors.reset} ${message}`);
}

// Check Backend Configuration
console.log('\n📦 BACKEND CONFIGURATION');
console.log('-'.repeat(60));

const backendEnvPath = path.join(__dirname, 'backend', '.env');
let backendConfig = {
  hasEnvFile: false,
  hasProjectId: false,
  hasPrivateKey: false,
  hasClientEmail: false,
  projectId: null,
  clientEmail: null,
};

if (fs.existsSync(backendEnvPath)) {
  backendConfig.hasEnvFile = true;
  logSuccess('Backend .env file exists');
  
  try {
    const envContent = fs.readFileSync(backendEnvPath, 'utf8');
    
    // Check for Firebase variables
    const projectIdMatch = envContent.match(/FIREBASE_PROJECT_ID=(.+)/);
    const privateKeyMatch = envContent.match(/FIREBASE_PRIVATE_KEY=(.+)/);
    const clientEmailMatch = envContent.match(/FIREBASE_CLIENT_EMAIL=(.+)/);
    
    if (projectIdMatch) {
      backendConfig.hasProjectId = true;
      backendConfig.projectId = projectIdMatch[1].trim().replace(/^["']|["']$/g, '');
      logSuccess(`FIREBASE_PROJECT_ID is set: ${backendConfig.projectId}`);
    } else {
      logError('FIREBASE_PROJECT_ID is missing');
    }
    
    if (privateKeyMatch) {
      backendConfig.hasPrivateKey = true;
      const key = privateKeyMatch[1].trim();
      if (key.includes('BEGIN PRIVATE KEY') && key.includes('END PRIVATE KEY')) {
        logSuccess('FIREBASE_PRIVATE_KEY is set and appears valid');
      } else {
        logWarning('FIREBASE_PRIVATE_KEY is set but format may be incorrect');
      }
    } else {
      logError('FIREBASE_PRIVATE_KEY is missing');
    }
    
    if (clientEmailMatch) {
      backendConfig.hasClientEmail = true;
      backendConfig.clientEmail = clientEmailMatch[1].trim().replace(/^["']|["']$/g, '');
      logSuccess(`FIREBASE_CLIENT_EMAIL is set: ${backendConfig.clientEmail}`);
    } else {
      logError('FIREBASE_CLIENT_EMAIL is missing');
    }
    
  } catch (error) {
    logError(`Cannot read .env file: ${error.message}`);
  }
} else {
  logError('Backend .env file not found');
  logInfo('Expected location: backend/.env');
}

const backendConfigured = backendConfig.hasProjectId && 
                          backendConfig.hasPrivateKey && 
                          backendConfig.hasClientEmail;

// Check Mobile Configuration
console.log('\n📱 MOBILE APP CONFIGURATION');
console.log('-'.repeat(60));

const mobileFirebaseOptionsPath = path.join(__dirname, 'mobile', 'lib', 'firebase_options.dart');
let mobileConfig = {
  hasFirebaseOptions: false,
  projectId: null,
  androidConfigured: false,
  iosConfigured: false,
};

if (fs.existsSync(mobileFirebaseOptionsPath)) {
  mobileConfig.hasFirebaseOptions = true;
  logSuccess('firebase_options.dart file exists');
  
  try {
    const optionsContent = fs.readFileSync(mobileFirebaseOptionsPath, 'utf8');
    
    // Extract project ID
    const projectIdMatch = optionsContent.match(/projectId:\s*['"]([^'"]+)['"]/);
    if (projectIdMatch) {
      mobileConfig.projectId = projectIdMatch[1];
      logSuccess(`Project ID found: ${mobileConfig.projectId}`);
    }
    
    // Check Android configuration
    if (optionsContent.includes('static const FirebaseOptions android')) {
      const androidApiKey = optionsContent.match(/apiKey:\s*['"]([^'"]+)['"]/);
      const androidAppId = optionsContent.match(/appId:\s*['"]([^'"]+)['"]/);
      if (androidApiKey && androidAppId) {
        mobileConfig.androidConfigured = true;
        logSuccess('Android Firebase configuration is present');
      }
    }
    
    // Check iOS configuration
    if (optionsContent.includes('static const FirebaseOptions ios')) {
      const iosApiKey = optionsContent.match(/apiKey:\s*['"]([^'"]+)['"]/);
      const iosAppId = optionsContent.match(/appId:\s*['"]([^'"]+)['"]/);
      if (iosApiKey && iosAppId) {
        mobileConfig.iosConfigured = true;
        logSuccess('iOS Firebase configuration is present');
      }
    }
    
  } catch (error) {
    logError(`Cannot read firebase_options.dart: ${error.message}`);
  }
} else {
  logError('firebase_options.dart file not found');
  logInfo('Run: cd mobile && flutterfire configure');
}

// Check Project ID Match
console.log('\n🔗 PROJECT ID MATCH');
console.log('-'.repeat(60));

if (backendConfig.projectId && mobileConfig.projectId) {
  if (backendConfig.projectId === mobileConfig.projectId) {
    logSuccess(`Project IDs match: ${backendConfig.projectId}`);
  } else {
    logError(`Project IDs do not match!`);
    logWarning(`Backend: ${backendConfig.projectId}`);
    logWarning(`Mobile: ${mobileConfig.projectId}`);
  }
} else {
  logWarning('Cannot compare project IDs - one or both are missing');
}

// Summary
console.log('\n📊 SUMMARY');
console.log('='.repeat(60));

const issues = [];

if (!backendConfigured) {
  issues.push('Backend FCM credentials are not fully configured');
  logError('Backend: NOT CONFIGURED');
  console.log('\n  To fix:');
  console.log('  1. Go to Firebase Console > Project Settings > Service Accounts');
  console.log('  2. Generate new private key and download JSON');
  console.log('  3. Add to backend/.env:');
  console.log('     FIREBASE_PROJECT_ID=your-project-id');
  console.log('     FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"');
  console.log('     FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com');
} else {
  logSuccess('Backend: CONFIGURED');
}

if (!mobileConfig.hasFirebaseOptions) {
  issues.push('Mobile Firebase options file is missing');
  logError('Mobile: NOT CONFIGURED');
  console.log('\n  To fix:');
  console.log('  1. cd mobile');
  console.log('  2. dart pub global activate flutterfire_cli');
  console.log('  3. flutterfire configure');
} else {
  logSuccess('Mobile: CONFIGURED');
}

if (issues.length === 0) {
  console.log(`\n${colors.green}🎉 All FCM configurations are properly set up!${colors.reset}`);
  console.log('\nNext steps:');
  console.log('  1. Restart backend server');
  console.log('  2. Check backend logs for: "Firebase Admin SDK initialized successfully"');
  console.log('  3. Test push notifications from the app');
} else {
  console.log(`\n${colors.red}⚠️  ${issues.length} issue(s) found${colors.reset}`);
  console.log('\nPlease fix the issues above before deploying to production.');
}

console.log('\n' + '='.repeat(60));
