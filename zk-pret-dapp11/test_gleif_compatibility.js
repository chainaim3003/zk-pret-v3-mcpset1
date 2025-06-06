// Quick GLEIF verification test to ensure backward compatibility
const axios = require('axios');

async function testGLEIFBackwardCompatibility() {
  console.log('=== Testing GLEIF Backward Compatibility ===');
  
  try {
    // Test with the exact same parameters that worked before
    const response = await axios.post('http://localhost:3000/api/v1/tools/execute', {
      toolName: 'get-GLEIF-verification-with-sign',
      parameters: {
        companyName: 'SREE PALANI ANDAVAR AGROS PRIVATE LIMITED',
        typeOfNet: 'TESTNET'
      }
    });
    
    console.log('✅ GLEIF verification SUCCESSFUL!');
    console.log('Result:', response.data.success ? 'ZK Proof Generated' : 'Failed');
    console.log('Execution Time:', response.data.executionTime);
    
    if (response.data.result && response.data.result.output) {
      console.log('Output contains expected data:', 
        response.data.result.output.includes('SREE PALANI ANDAVAR') ? '✅ Yes' : '❌ No'
      );
    }
    
  } catch (error) {
    console.log('❌ GLEIF verification FAILED!');
    console.log('Error:', error.response?.data?.message || error.message);
  }
}

testGLEIFBackwardCompatibility().catch(console.error);
