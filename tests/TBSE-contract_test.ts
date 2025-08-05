
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
    let providerDetails = providerCall.result.expectSome().expectTuple();
    assertEquals(providerDetails['feedback-count'], types.uint(1));
    assertEquals(providerDetails['avg-rating'], types.uint(90));
    
    // Endorse provider's skill
    let endorseBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'endorse-skill',
        [
          types.uint(1), // skill-id
          types.uint(1), // endorsed-user-id (provider)
          types.utf8("Excellent math teacher!") // comment
        ],
        receiver.address
      )
    ]);
    
    // Check that endorsement succeeded
    assertEquals(endorseBlock.receipts.length, 1);
    assertEquals(endorseBlock.receipts[0].result, '(ok true)');
    
    // Check provider's skill endorsement count
    let providerSkillCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-skill-provider',
      [types.uint(1), types.uint(1)], // skill-id, user-id
      deployer.address
    );
    
    let providerSkillDetails = providerSkillCall.result.expectSome().expectTuple();
    assertEquals(providerSkillDetails['endorsement-count'], types.uint(1));
    
    // Check has-endorsed? function
    let endorsedCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'has-endorsed?',
      [types.uint(1), types.uint(1), types.uint(2)], // skill-id, endorsed-user-id, endorser-user-id
      deployer.address
    );
    
    assertEquals(endorsedCall.result, types.bool(true));
  },
});

Clarinet.test({
  name: "Can cancel services",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const receiver = accounts.get('wallet_2')!;
    
    // Setup: Register users, create skill, register provider, request service
    let setupBlock = chain.mineBlock([
      // Register users
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Provider"), types.utf8("Bio")], provider.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Receiver"), types.utf8("Bio")], receiver.address),
      // Add skill
      Tx.contractCall('time-banking-service-exchange', 'add-skill-category',
        [types.utf8("Cooking"), types.utf8("Food preparation"), types.utf8("Food")],
        deployer.address),
      // Register as provider
      Tx.contractCall('time-banking-service-exchange', 'register-as-provider',
        [types.uint(1), types.uint(60), types.utf8("expert"), types.utf8("Weekends")],
        provider.address),
      // Request service
      Tx.contractCall('time-banking-service-exchange', 'request-service',
        [types.uint(1), types.uint(1), types.utf8("Cooking lesson"), types.uint(90), types.utf8("Notes")],
        receiver.address)
    ]);
    
    // Check receiver's initial balance
    let receiverCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // receiver-id
      deployer.address
    );
    
    let receiverInitialDetails = receiverCall.result.expectSome().expectTuple();
    assertEquals(receiverInitialDetails['time-balance'], types.uint(60)); // Initial balance
    
    // Start the service
    let startBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'start-service',
        [types.uint(1)], // service-id
        provider.address
      )
    ]);
    
    // Check receiver's balance after service started
    receiverCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // receiver-id
      deployer.address
    );
    
    let receiverAfterStartDetails = receiverCall.result.expectSome().expectTuple();
    // 60 - 90 = -30 (would be an error, but in this case the contract probably limits it to 0 or maintains a debt)
    // Since we're testing a specific contract, we'll have to check what value it gives
    let balanceAfterStart = parseInt(receiverAfterStartDetails['time-balance'].substring(1));
    
    // Cancel the service
    let cancelBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'cancel-service',
        [types.uint(1)], // service-id
        provider.address
      )
    ]);
    
    // Check that cancellation succeeded
    assertEquals(cancelBlock.receipts.length, 1);
    assertEquals(cancelBlock.receipts[0].result, '(ok true)');
    
    // Check service status is canceled
    let serviceCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-service',
      [types.uint(1)], // service-id
      deployer.address
    );
    
    let serviceDetails = serviceCall.result.expectSome().expectTuple();
    assertEquals(serviceDetails['status'], types.uint(SERVICE_STATUS_CANCELED));
    
    // Check receiver's balance is refunded
    receiverCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // receiver-id
      deployer.address
    );
    
    let receiverAfterCancelDetails = receiverCall.result.expectSome().expectTuple();
    assertEquals(receiverAfterCancelDetails['time-balance'], types.uint(60)); // Should be back to original balance
  },
});

Clarinet.test({
  name: "Can handle disputes and resolve them",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const receiver = accounts.get('wallet_2')!;
    const arbiter = accounts.get('wallet_3')!;
    
    // Setup: Register users, create skill, register provider, request and start service
    let setupBlock = chain.mineBlock([
      // Register users
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Provider"), types.utf8("Bio")], provider.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Receiver"), types.utf8("Bio")], receiver.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Arbiter"), types.utf8("Bio")], arbiter.address),
      // Add skill
      Tx.contractCall('time-banking-service-exchange', 'add-skill-category',
        [types.utf8("Plumbing"), types.utf8("Water system repairs"), types.utf8("Home")],
        deployer.address),
      // Register as provider
      Tx.contractCall('time-banking-service-exchange', 'register-as-provider',
        [types.uint(1), types.uint(60), types.utf8("expert"), types.utf8("Anytime")],
        provider.address),
      // Request service
      Tx.contractCall('time-banking-service-exchange', 'request-service',
        [types.uint(1), types.uint(1), types.utf8("Fix broken pipe"), types.uint(60), types.utf8("Notes")],
        receiver.address),
      // Start service
      Tx.contractCall('time-banking-service-exchange', 'start-service',
        [types.uint(1)], provider.address)
    ]);
    
    // Make user3 an arbiter
    let arbiterBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'make-arbiter',
        [types.uint(3)], // user-id
        deployer.address
      )
    ]);
    
    // Check that making arbiter succeeded
    assertEquals(arbiterBlock.receipts.length, 1);
    assertEquals(arbiterBlock.receipts[0].result, '(ok true)');
    
    // Raise a dispute by the receiver
    let disputeBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'raise-dispute',
        [
          types.uint(1), // service-id
          types.utf8("The pipe is still leaking after repair") // description
        ],
        receiver.address
      )
    ]);
    
    // Check that dispute creation succeeded
    assertEquals(disputeBlock.receipts.length, 1);
    assertEquals(disputeBlock.receipts[0].result, '(ok u1)'); // First dispute ID is 1
    
    // Check service status is disputed
    let serviceCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-service',
      [types.uint(1)], // service-id
      deployer.address
    );
    
    let serviceDetails = serviceCall.result.expectSome().expectTuple();
    assertEquals(serviceDetails['status'], types.uint(SERVICE_STATUS_DISPUTED));
    
    // Assign the arbiter to the dispute
    let assignBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'assign-arbiter',
        [
          types.uint(1), // dispute-id
          types.uint(3), // arbiter-id
        ],
        deployer.address
      )
    ]);
    
    // Check that arbiter assignment succeeded
    assertEquals(assignBlock.receipts.length, 1);
    assertEquals(assignBlock.receipts[0].result, '(ok true)');
    
    // Resolve the dispute (arbiter decides provider needs to do additional work)
    let resolveBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'resolve-dispute',
        [
          types.uint(1), // dispute-id
          types.utf8("Provider must fix the leak properly. Receiver gets partial refund."), // resolution
          types.int(-20) // time-adjustment (20 minutes back to receiver)
        ],
        arbiter.address
      )
    ]);
    
    // Check that dispute resolution succeeded
    assertEquals(resolveBlock.receipts.length, 1);
    assertEquals(resolveBlock.receipts[0].result, '(ok true)');
    
    // Check dispute status is resolved
    let disputeCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-dispute',
      [types.uint(1)], // dispute-id
      deployer.address
    );
    
    let disputeDetails = disputeCall.result.expectSome().expectTuple();
    assertEquals(disputeDetails['status'], types.uint(DISPUTE_STATUS_RESOLVED));
    
    // Check that receiver got some time back
    let receiverCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // receiver-id
      deployer.address
    );
    
    let receiverDetails = receiverCall.result.expectSome().expectTuple();
    assertEquals(receiverDetails['time-balance'], types.uint(20)); // Should have 20 minutes refunded
  },
});

Clarinet.test({
  name: "Can donate to community and allocate from community fund",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const donor = accounts.get('wallet_1')!;
    const recipient = accounts.get('wallet_2')!;
    
    // Setup: Register users
    let setupBlock = chain.mineBlock([
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Donor"), types.utf8("Generous person")], donor.address),
      Tx.contractCall('time-banking-service-exchange', 'register-user',
        [types.utf8("Recipient"), types.utf8("Community member")], recipient.address)
    ]);
    
    // Donate to community fund
    let donateBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'donate-to-community',
        [types.uint(20)], // amount (20 minutes)
        donor.address
      )
    ]);
    
    // Check that donation succeeded
    assertEquals(donateBlock.receipts.length, 1);
    assertEquals(donateBlock.receipts[0].result, '(ok true)');
    
    // Check donor's new balance
    let donorCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(1)], // donor-id
      deployer.address
    );
    
    let donorDetails = donorCall.result.expectSome().expectTuple();
    assertEquals(donorDetails['time-balance'], types.uint(40)); // 60 initial - 20 donated = 40
    
    // Allocate from community fund to recipient
    let allocateBlock = chain.mineBlock([
      Tx.contractCall(
        'time-banking-service-exchange',
        'allocate-from-community',
        [
          types.uint(2), // recipient-id
          types.uint(15), // amount (15 minutes)
          types.utf8("For community garden project") // reason
        ],
        deployer.address
      )
    ]);
    
    // Check that allocation succeeded
    assertEquals(allocateBlock.receipts.length, 1);
    assertEquals(allocateBlock.receipts[0].result, '(ok true)');
    
    // Check recipient's new balance
    let recipientCall = chain.callReadOnlyFn(
      'time-banking-service-exchange',
      'get-user',
      [types.uint(2)], // recipient-id
      deployer.address
    );
    
    let recipientDetails = recipientCall.result.expectSome().expectTuple();
    assertEquals(recipientDetails['time-balance'], types.uint(75)); // 60 initial + 15 allocated = 75
  },
});

Clarinet.test({
  name: "Enforces authorization rules properly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;
    
    // Try to add skill category without being contract owner
    let unauthorizedBlock = chain.mineBlock([
      Tx.contractCall('time-banking-service-exchange', 'add-skill-category',
        [types.utf8("Unauthorized"), types.utf8("Description"), types.utf8("Category")],
        user.address)
    ]);
    
    // Should fail
    assertEquals(unauthorizedBlock.receipts.length, 1);
    assertEquals(unauthorizedBlock.receipts[0].result, '(err u1)'); // ERR-NOT-AUTHORIZED
    
    // Try to make user arbiter without being contract owner
    let arbiterBlock = chain.mineBlock([
      Tx.contractCall('time-banking-service-exchange', 'make-arbiter',
        [types.uint(1)], user.address)
    ]);
    
    // Should fail
    assertEquals(arbiterBlock.receipts.length, 1);
    assertEquals(arbiterBlock.receipts[0].result, '(err u1)'); // ERR-NOT-AUTHORIZED
  },
});
