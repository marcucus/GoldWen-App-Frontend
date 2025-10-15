/**
 * Demo script showing how the GDPR compliance endpoints work
 * This demonstrates the three main GDPR features:
 * 1. Consent Management (POST /users/consent, GET /users/consent)
 * 2. Data Export/Portability (GET /users/me/export)
 * 3. Right to Deletion (DELETE /users/me)
 * 
 * To run this demo:
 * 1. Start the API server: npm run start:dev
 * 2. Create a user account and get auth token
 * 3. Update the authToken variable below
 * 4. Run: node demo-gdpr-endpoints.js
 */

const baseURL = 'http://localhost:3000';

// Replace with actual JWT token from login
const authToken = 'Bearer your-jwt-token-here';

async function demoGdprEndpoints() {
  console.log('🔒 GoldWen GDPR Compliance API Demo\n');

  try {
    // 1. Record User Consent
    console.log('📝 1. Recording user consent for GDPR compliance...');
    const consentData = {
      dataProcessing: true,
      marketing: false,
      analytics: true,
      consentedAt: new Date().toISOString()
    };

    console.log('POST /users/consent');
    console.log('Request body:', JSON.stringify(consentData, null, 2));
    console.log('Expected response:');
    console.log(JSON.stringify({
      success: true,
      message: 'Consent recorded successfully',
      data: {
        id: 'consent-uuid',
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: consentData.consentedAt,
        createdAt: new Date().toISOString()
      }
    }, null, 2));
    console.log('');

    // 2. Get Current Consent Status
    console.log('📋 2. Checking current consent status...');
    console.log('GET /users/consent');
    console.log('Expected response for user with active consent:');
    console.log(JSON.stringify({
      success: true,
      data: {
        id: 'consent-uuid',
        dataProcessing: true,
        marketing: false,
        analytics: true,
        consentedAt: consentData.consentedAt,
        isActive: true,
        createdAt: new Date().toISOString()
      }
    }, null, 2));
    console.log('');

    // 3. Export User Data (Data Portability)
    console.log('📤 3. Exporting user data for GDPR compliance...');
    console.log('GET /users/me/export?format=json');
    console.log('Expected response structure:');
    console.log(JSON.stringify({
      success: true,
      message: 'User data exported successfully in json format',
      data: {
        exportedAt: new Date().toISOString(),
        userId: 'user-uuid',
        data: {
          user: {
            id: 'user-uuid',
            email: 'user@example.com',
            status: 'ACTIVE',
            isEmailVerified: true,
            createdAt: '2024-01-01T00:00:00Z'
          },
          profile: {
            id: 'profile-uuid',
            firstName: 'John',
            birthDate: '1990-01-01',
            location: 'Paris, France',
            bio: 'Love traveling and meeting new people',
            interests: ['travel', 'photography']
          },
          matches: [
            {
              id: 'match-uuid',
              matchedWith: 'other-user-uuid',
              matchedAt: '2024-01-15T10:00:00Z',
              status: 'ACTIVE'
            }
          ],
          messages: [
            {
              id: 'message-uuid',
              content: 'Hello there!',
              sentAt: '2024-01-15T10:30:00Z',
              chatId: 'chat-uuid'
            }
          ],
          consents: [
            {
              id: 'consent-uuid',
              dataProcessing: true,
              marketing: false,
              analytics: true,
              consentedAt: consentData.consentedAt,
              isActive: true
            }
          ],
          subscriptions: [],
          notifications: [],
          reports: []
        }
      }
    }, null, 2));
    console.log('');

    // 4. PDF Export Option
    console.log('📄 4. PDF export option...');
    console.log('GET /users/me/export?format=pdf');
    console.log('Note: PDF export returns JSON format with note about PDF implementation');
    console.log('In production, this would generate a downloadable PDF file');
    console.log('');

    // 5. Account Deletion with Anonymization
    console.log('🗑️  5. Complete account deletion with GDPR anonymization...');
    console.log('DELETE /users/me');
    console.log('⚠️  WARNING: This permanently deletes the user account!');
    console.log('Expected response:');
    console.log(JSON.stringify({
      success: true,
      message: 'Account deleted successfully with complete anonymization'
    }, null, 2));
    console.log('');
    console.log('What happens during deletion:');
    console.log('✅ User account permanently deleted');
    console.log('✅ Profile data completely removed');
    console.log('✅ Personal messages anonymized (sender ID replaced)');
    console.log('✅ Match history anonymized (user ID replaced)');
    console.log('✅ Reports anonymized to preserve moderation history');
    console.log('✅ Logs anonymized (implementation depends on logging system)');
    console.log('✅ Push tokens and notifications deleted');
    console.log('✅ Subscriptions and payment data deleted');
    console.log('');

    // 6. GDPR Compliance Summary
    console.log('📊 6. GDPR Compliance Summary');
    console.log('✅ Right to Consent: Users can grant/revoke consent for data processing');
    console.log('✅ Right to Portability: Users can export all their data in readable format');
    console.log('✅ Right to Erasure: Users can delete their account with proper anonymization');
    console.log('✅ Data Minimization: Only necessary data is collected and exported');
    console.log('✅ Consent History: All consent changes are tracked with timestamps');
    console.log('✅ Secure Deletion: Sensitive data is completely removed, anonymized references preserved');
    console.log('');

  } catch (error) {
    console.error('Demo error:', error.message);
    console.log('\n⚠️  Note: This demo shows expected API behavior.');
    console.log('To test with real API calls, start the server and provide a valid auth token.');
  }
}

// Additional helper function to demonstrate API usage
async function makeApiCall(method, endpoint, data = null) {
  const url = `${baseURL}${endpoint}`;
  const options = {
    method,
    headers: {
      'Authorization': authToken,
      'Content-Type': 'application/json',
    },
  };

  if (data) {
    options.body = JSON.stringify(data);
  }

  try {
    const response = await fetch(url, options);
    const result = await response.json();
    return result;
  } catch (error) {
    console.error(`API call failed: ${method} ${endpoint}`, error);
    throw error;
  }
}

// Export for potential use as module
module.exports = { 
  demoGdprEndpoints, 
  makeApiCall 
};

// Run the demo if this file is executed directly
if (require.main === module) {
  demoGdprEndpoints().catch(console.error);
}