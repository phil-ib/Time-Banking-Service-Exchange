import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Error constants for better test readability
const ERR_NOT_AUTHORIZED = 1;
const ERR_USER_NOT_FOUND = 2;
const ERR_SKILL_NOT_FOUND = 3;
const ERR_SERVICE_NOT_FOUND = 4;
const ERR_INVALID_PARAMETERS = 5;
const ERR_INSUFFICIENT_BALANCE = 6;
const ERR_ALREADY_EXISTS = 7;
const ERR_NOT_SERVICE_PROVIDER = 8;
const ERR_NOT_SERVICE_RECEIVER = 9;
const ERR_ALREADY_VERIFIED = 10;
const ERR_ALREADY_COMPLETED = 11;
const ERR_SERVICE_NOT_COMPLETED = 12;
const ERR_FEEDBACK_ALREADY_GIVEN = 13;
const ERR_ENDORSEMENT_ALREADY_EXISTS = 14;
const ERR_SELF_ACTION_NOT_ALLOWED = 15;
const ERR_SERVICE_ALREADY_STARTED = 16;
const ERR_SERVICE_NOT_STARTED = 17;
const ERR_SERVICE_ALREADY_CANCELED = 18;
const ERR_DISPUTE_ALREADY_EXISTS = 19;
const ERR_DISPUTE_NOT_FOUND = 20;
const ERR_NOT_DISPUTE_PARTICIPANT = 21;
const ERR_NOT_ARBITER = 22;
const ERR_DISPUTE_ALREADY_RESOLVED = 23;

// Service status constants
const SERVICE_STATUS_PENDING = 1;
const SERVICE_STATUS_STARTED = 2;
const SERVICE_STATUS_COMPLETED = 3;
const SERVICE_STATUS_VERIFIED = 4;
const SERVICE_STATUS_DISPUTED = 5;
const SERVICE_STATUS_CANCELED = 6;

// Dispute status constants
const DISPUTE_STATUS_OPEN = 1;
const DISPUTE_STATUS_RESOLVED = 2;

Clarinet.test({
  name: "Can register users and get their details",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;
    
    // Register two users
    let block = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'register-user',
        [
          types.utf8("Alice"),
          types.utf8("A skilled web developer with 5 years of experience")
        ],
        user1.address
      ),
      Tx.contractCall(
        'time-banking-service-exchange',
        'register-user',
        [
          types.utf8("Bob"),
          types.utf8("A passionate gardener who loves to teach others")
        ],
        user2.address
      )
    ]);
    
    // Check that registrations succeeded
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[0].result, '(ok u1)'); // First user ID is 1
    assertEquals(block.receipts[1].result, '(ok u2)'); // Second user ID is 2
    
    // Get user 1 details
    let user1Call = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(1)],
      deployer.address
    );
    
    let user1Details = user1Call.result.expectSome().expectTuple();
    assertEquals(user1Details.principal, user1.address);
    assertEquals(user1Details.name, types.utf8("Alice"));
    assertEquals(user1Details.bio, types.utf8("A skilled web developer with 5 years of experience"));
    assertEquals(user1Details['time-balance'], types.uint(60)); // Start with 1 hour
    assertEquals(user1Details['is-active'], types.bool(true));
    assertEquals(user1Details['is-arbiter'], types.bool(false));
    
    // Get user 2 details
    let user2Call = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)],
      deployer.address
    );
    
    let user2Details = user2Call.result.expectSome().expectTuple();
    assertEquals(user2Details.principal, user2.address);
    assertEquals(user2Details.name, types.utf8("Bob"));
  },
});

Clarinet.test({
  name: "Can add skill categories and register as provider",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // Register user first
    let setupBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'register-user',
        [
          types.utf8("Alice"),
          types.utf8("A skilled web developer")
        ],
        user1.address
      )
    ]);
    
    // Add a skill category (only contract owner can do this)
    let skillBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'add-skill-category',
        [
          types.utf8("Web Development"),
          types.utf8("Building and maintaining websites"),
          types.utf8("Technology")
        ],
        deployer.address
      )
    ]);
    
    // Check that skill addition succeeded
    assertEquals(skillBlock.receipts.length, 1);
    assertEquals(skillBlock.receipts[0].result, '(ok u1)'); // First skill ID is 1
    
    // Register user1 as a provider for web development
    let providerBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'register-as-provider',
        [
          types.uint(1), // skill-id
          types.uint(60), // hourly-rate (60 minutes = 1 hour)
          types.utf8("expert"), // experience-level
          types.utf8("Available weekends and evenings") // availability
        ],
        user1.address
      )
    ]);
    
    // Check that provider registration succeeded
    assertEquals(providerBlock.receipts.length, 1);
    assertEquals(providerBlock.receipts[0].result, '(ok true)');
    
    // Check skill provider details
    let providerCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-skill-provider',
      [types.uint(1), types.uint(1)], // skill-id, user-id
      deployer.address
    );
    
    let providerDetails = providerCall.result.expectSome().expectTuple();
    assertEquals(providerDetails['hourly-rate'], types.uint(60));
    assertEquals(providerDetails['experience-level'], types.utf8("expert"));
    assertEquals(providerDetails['endorsement-count'], types.uint(0));
    
    // Verify that offers-skill? returns true
    let offersSkillCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'offers-skill?',
      [types.uint(1), types.uint(1)], // user-id, skill-id
      deployer.address
    );
    
    assertEquals(offersSkillCall.result, types.bool(true));
  },
});

Clarinet.test({
  name: "Can request, start, complete, and verify a service",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const receiver = accounts.get('wallet_2')!;
    
    // Setup: Register users, add skill category, register provider
    let setupBlock = chain.mineBlock([
      // Register users
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Provider"), types.utf8("Service provider")], provider.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Receiver"), types.utf8("Service receiver")], receiver.address),
      // Add skill
      Tx.contractCall('time-banking-service-exchange', 'add-skill-category',
        [types.utf8("Home Repair"), types.utf8("Fixing things around the house"), types.utf8("Household")],
        deployer.address),
      // Register as provider
      Tx.contractCall('time-banking-service-exchange', 'register-as-provider',
        [types.uint(1), types.uint(60), types.utf8("intermediate"), types.utf8("Weekends")],
        provider.address)
    ]);
    
    // Request a service
    let requestBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'request-service',
        [
          types.uint(1), // provider-id
          types.uint(1), // skill-id
          types.utf8("Fix a leaky faucet"), // description
          types.uint(30), // estimated-minutes (30 minutes)
          types.utf8("Please bring your own tools") // notes
        ],
        receiver.address
      )
    ]);
    
    // Check that request succeeded
    assertEquals(requestBlock.receipts.length, 1);
    assertEquals(requestBlock.receipts[0].result, '(ok u1)'); // First service ID is 1
    
    // Verify service details
    let serviceCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-service',
      [types.uint(1)], // service-id
      deployer.address
    );
    
    let serviceDetails = serviceCall.result.expectSome().expectTuple();
    assertEquals(serviceDetails['provider-id'], types.uint(1));
    assertEquals(serviceDetails['receiver-id'], types.uint(2));
    assertEquals(serviceDetails['status'], types.uint(SERVICE_STATUS_PENDING));
    
    // Start the service
    let startBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'start-service',
        [types.uint(1)], // service-id
        provider.address
      )
    ]);
    
    // Check that service start succeeded
    assertEquals(startBlock.receipts.length, 1);
    assertEquals(startBlock.receipts[0].result, '(ok true)');
    
    // Check receiver's balance reduced by estimated time
    let receiverCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // receiver-id
      deployer.address
    );
    
    let receiverDetails = receiverCall.result.expectSome().expectTuple();
    // Original 60 minutes - 30 minutes (estimated time) = 30 minutes remaining
    assertEquals(receiverDetails['time-balance'], types.uint(30));
    
    // Complete the service
    let completeBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'complete-service',
        [
          types.uint(1), // service-id
          types.uint(45) // actual-minutes (45 minutes)
        ],
        provider.address
      )
    ]);
    
    // Check that service completion succeeded
    assertEquals(completeBlock.receipts.length, 1);
    assertEquals(completeBlock.receipts[0].result, '(ok true)');
    
    // Verify the service
    let verifyBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'verify-service',
        [types.uint(1)], // service-id
        receiver.address
      )
    ]);
    
    // Check that verification succeeded
    assertEquals(verifyBlock.receipts.length, 1);
    assertEquals(verifyBlock.receipts[0].result, '(ok true)');
    
    // Check provider's balance increased by actual time
    let providerCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(1)], // provider-id
      deployer.address
    );
    
    let providerDetails = providerCall.result.expectSome().expectTuple();
    // Original 60 minutes + 45 minutes (actual time) = 105 minutes
    assertEquals(providerDetails['time-balance'], types.uint(105));
    assertEquals(providerDetails['time-contributed'], types.uint(45));
    
    // Check that service status is verified
    let serviceStatusCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-service',
      [types.uint(1)], // service-id
      deployer.address
    );
    
    let serviceStatusDetails = serviceStatusCall.result.expectSome().expectTuple();
    assertEquals(serviceStatusDetails['status'], types.uint(SERVICE_STATUS_VERIFIED));
    assertEquals(serviceStatusDetails['actual-minutes'], types.some(types.uint(45)));
  },
});

Clarinet.test({
  name: "Can leave feedback and endorse skills",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const receiver = accounts.get('wallet_2')!;
    
    // Complete setup including a verified service
    let setupBlock = chain.mineBlock([
      // Register users
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Provider"), types.utf8("Bio")], provider.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Receiver"), types.utf8("Bio")], receiver.address),
      // Add skill
      Tx.contractCall('time-banking-service-exchange', 'add-skill-category',
        [types.utf8("Teaching"), types.utf8("Educational services"), types.utf8("Education")],
        deployer.address),
      // Register as provider
      Tx.contractCall('time-banking-service-exchange', 'register-as-provider',
        [types.uint(1), types.uint(60), types.utf8("expert"), types.utf8("Weekdays")],
        provider.address),
      // Request service
      Tx.contractCall('time-banking-service-exchange', 'request-service',
        [types.uint(1), types.uint(1), types.utf8("Math tutoring"), types.uint(60), types.utf8("Notes")],
        receiver.address),
      // Start service
      Tx.contractCall('time-banking-service-exchange', 'start-service',
        [types.uint(1)], provider.address),
      // Complete service
      Tx.contractCall('time-banking-service-exchange', 'complete-service',
        [types.uint(1), types.uint(60)], provider.address),
      // Verify service
      Tx.contractCall('time-banking-service-exchange', 'verify-service',
        [types.uint(1)], receiver.address)
    ]);
    
    // Leave feedback from receiver to provider
    let feedbackBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'leave-feedback',
        [
          types.uint(1), // service-id
          types.uint(90), // rating (90/100)
          types.utf8("Great teaching, very patient!") // comment
        ],
        receiver.address
      )
    ]);
    
    // Check that feedback succeeded
    assertEquals(feedbackBlock.receipts.length, 1);
    assertEquals(feedbackBlock.receipts[0].result, '(ok true)');
    
    // Check provider's updated rating and reputation
    let providerCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(1)], // provider-id
      deployer.address
    );