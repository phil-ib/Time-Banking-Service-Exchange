# Time Banking Service Exchange (TBSE)

A decentralized platform built on Stacks blockchain for community members to exchange services based on time contributions. Users can offer skills, request services, and earn time credits through community participation.

## 🐛 Recent Bug Fix

### Issue Resolved
The contract had several Clarity language compliance issues that were preventing successful compilation:

1. **Invalid `when` function usage**: The contract was using `when` statements which are not part of the Clarity language specification
2. **Missing `min` function**: Attempted to use a non-existent `min` function for reputation score calculations
3. **Type mismatches in conditional statements**: Mixed return types in `if` statements

### Fixes Applied
- **Replaced `when` with `if`**: All instances of `when` were replaced with proper `if` conditional statements
- **Implemented custom min logic**: Replaced `min()` function with conditional expression: `(if (> value max) max value)`
- **Fixed type consistency**: Ensured all conditional branches return the same type

### Code Changes
```clarity
;; Before (Invalid)
(when (> refund-amount u0)
  (map-set users ...)
)

;; After (Valid)
(if (> refund-amount u0)
  (map-set users ...)
  true
)
```

```clarity
;; Before (Invalid)
reputation-score: (min (+ (get reputation-score endorsed-user) u2) u100)

;; After (Valid)
reputation-score: (if (> (+ (get reputation-score endorsed-user) u2) u100) 
                   u100 
                   (+ (get reputation-score endorsed-user) u2))
```

## 🚀 Features

### Core Functionality
- **User Registration**: Create profiles with time credit balances
- **Skill Management**: Register and offer skills as services
- **Service Exchange**: Request, provide, and complete services
- **Time Banking**: Earn and spend time credits
- **Reputation System**: Build trust through ratings and endorsements
- **Dispute Resolution**: Community-driven conflict resolution
- **Community Fund**: Pool for community initiatives

### Service Lifecycle
1. **Request**: User requests service from provider
2. **Start**: Provider begins the service
3. **Complete**: Provider marks service as finished
4. **Verify**: Receiver confirms completion
5. **Feedback**: Both parties can leave ratings

## 📊 System Overview

### Time Credits
- New users start with 60 minutes (1 hour) of time credit
- Time is measured in minutes for precision
- 1% of verified service time goes to community fund
- Credits can be donated to community initiatives

### Reputation System
- Scores range from 0-100
- Based on feedback ratings and endorsements
- Affects service matching and trust

### Dispute Resolution
- Community arbiters resolve conflicts
- Time adjustments can be made
- Community fund provides backup for adjustments

## 🔧 Technical Details

### Smart Contract
- **Language**: Clarity
- **Platform**: Stacks blockchain
- **Status**: ✅ Compilation successful
- **Compliance**: Full Clarity language compliance

### Data Structures
- **Users**: Profiles with time balances and reputation
- **Skills**: Service categories and provider registrations
- **Services**: Exchange records with status tracking
- **Disputes**: Conflict resolution records
- **Feedback**: Ratings and comments system

## 🛠️ Installation & Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/smart-contracts/clarinet) installed
- Stacks development environment

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd Time-Banking-Service-Exchange

# Check contract compliance
clarinet check

# Run tests
clarinet test

# Deploy to devnet
clarinet deploy
```

## 📋 API Reference

### User Management
- `register-user`: Create new user profile
- `update-profile`: Update profile information
- `make-arbiter`: (Admin) Designate dispute arbiter

### Skill Management
- `add-skill-category`: (Admin) Add new skill category
- `register-as-provider`: Offer skill as service
- `update-provider-details`: Update service offering
- `endorse-skill`: Endorse another user's skill

### Service Exchange
- `request-service`: Request service from provider
- `start-service`: Provider starts requested service
- `complete-service`: Provider marks service complete
- `verify-service`: Receiver verifies completed service
- `cancel-service`: Cancel pending or started service
- `leave-feedback`: Provide feedback on completed service

### Dispute Resolution
- `raise-dispute`: Raise dispute about service
- `assign-arbiter`: (Admin) Assign arbiter to dispute
- `resolve-dispute`: Arbiter resolves open dispute

### Community Features
- `donate-to-community`: Donate time credits to community fund
- `allocate-from-community`: (Admin) Allocate time from community fund

## 🎯 Error Codes

| Code | Description |
|------|-------------|
| ERR-NOT-AUTHORIZED | User lacks required permissions |
| ERR-USER-NOT-FOUND | User does not exist |
| ERR-SKILL-NOT-FOUND | Skill category does not exist |
| ERR-SERVICE-NOT-FOUND | Service does not exist |
| ERR-INVALID-PARAMETERS | Invalid input parameters |
| ERR-INSUFFICIENT-BALANCE | Insufficient time credits |
| ERR-ALREADY-EXISTS | Resource already exists |
| ERR-NOT-SERVICE-PROVIDER | User is not a service provider |
| ERR-NOT-SERVICE-RECEIVER | User is not the service receiver |
| ERR-ALREADY-VERIFIED | Service already verified |
| ERR-ALREADY-COMPLETED | Service already completed |
| ERR-SERVICE-NOT-COMPLETED | Service not yet completed |
| ERR-FEEDBACK-ALREADY-GIVEN | Feedback already provided |
| ERR-ENDORSEMENT-ALREADY-EXISTS | Endorsement already exists |
| ERR-SELF-ACTION-NOT-ALLOWED | Cannot perform action on self |
| ERR-SERVICE-ALREADY-STARTED | Service already started |
| ERR-SERVICE-NOT-STARTED | Service not yet started |
| ERR-SERVICE-ALREADY-CANCELED | Service already canceled |
| ERR-DISPUTE-ALREADY-EXISTS | Dispute already exists |
| ERR-DISPUTE-NOT-FOUND | Dispute does not exist |
| ERR-NOT-DISPUTE-PARTICIPANT | User not involved in dispute |
| ERR-NOT-ARBITER | User is not an arbiter |
| ERR-DISPUTE-ALREADY-RESOLVED | Dispute already resolved |

## 🔄 Service Status Flow

| Status | Description |
|--------|-------------|
| PENDING | Service requested, waiting to start |
| STARTED | Service in progress |
| COMPLETED | Service finished, awaiting verification |
| VERIFIED | Service confirmed and time transferred |
| DISPUTED | Service under dispute resolution |
| CANCELED | Service canceled |

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/TBSE-contract_test.ts
```

## 📈 Usage Examples

### Register as User
```clarity
(register-user "Alice" "Community organizer and gardener")
```

### Register as Service Provider
```clarity
(register-as-provider 1 60 "expert" "Available weekends")
```

### Request Service
```clarity
(request-service 2 1 "Need help with garden maintenance" 120 "Backyard needs weeding")
```

### Complete and Verify Service
```clarity
(complete-service 1 90)
(verify-service 1)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `clarinet check` to ensure compliance
5. Run `clarinet test` to verify functionality
6. Submit a pull request

## 📄 License

This project is open-source and available under the MIT License.

## 🔗 Links

- [Clarity Language Documentation](https://docs.stacks.co/write-smart-contracts/overview)
- [Clarinet Documentation](https://docs.hiro.so/smart-contracts/clarinet)
- [Stacks Documentation](https://docs.stacks.co/)

---

**Status**: ✅ Production Ready  
**Last Updated**: December 2024  
**Version**: 1.0.0