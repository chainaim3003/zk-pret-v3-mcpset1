// Test script to verify all three verification types work
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';

async function testVerification(toolName, parameters) {
  console.log(`\n=== Testing ${toolName} ===`);
  console.log('Parameters:', JSON.stringify(parameters, null, 2));
  
  try {
    const response = await axios.post(`${BASE_URL}/tools/execute`, {
      toolName,
      parameters
    });
    
    console.log('✅ Success!');
    console.log('Result:', response.data.success ? 'ZK Proof Generated' : 'Failed');
    console.log('Execution Time:', response.data.executionTime);
    
    if (response.data.result && response.data.result.output) {
      console.log('Output preview:', response.data.result.output.substring(0, 200) + '...');
    }
    
  } catch (error) {
    console.log('❌ Failed!');
    console.log('Error:', error.response?.data?.message || error.message);
  }
}

async function runAllTests() {
  console.log('Testing all ZK-PRET verification types...');
  
  // Test GLEIF verification (exact same format as before)
  await testVerification('get-GLEIF-verification-with-sign', {
    companyName: 'SREE PALANI ANDAVAR AGROS PRIVATE LIMITED',
    typeOfNet: 'TESTNET'
  });
  
  // Test Corporate Registration verification (exact same format as data file)
  await testVerification('get-Corporate-Registration-verification-with-sign', {
    cin: 'U01112TZ2022PTC039493',
    typeOfNet: 'TESTNET'
  });
  
  // Test EXIM verification (exact same format as data file)
  await testVerification('get-EXIM-verification-with-sign', {
    companyName: 'SREE PALANI ANDAVAR AGROS PRIVATE LIMITED',
    typeOfNet: 'TESTNET'
  });
  
  console.log('\n=== All tests completed ===');
}

runAllTests().catch(console.error);
