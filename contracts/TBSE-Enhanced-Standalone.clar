;; Time-Banking Service Exchange - Enhanced Standalone Version
;; Complete enhanced contract with governance and certifications

;; Base error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-USER-NOT-FOUND u2)
(define-constant ERR-SKILL-NOT-FOUND u3)
(define-constant ERR-SERVICE-NOT-FOUND u4)
(define-constant ERR-INVALID-PARAMETERS u5)
(define-constant ERR-INSUFFICIENT-BALANCE u6)
(define-constant ERR-ALREADY-EXISTS u7)
(define-constant ERR-NOT-SERVICE-PROVIDER u8)
(define-constant ERR-NOT-SERVICE-RECEIVER u9)
(define-constant ERR-ALREADY-VERIFIED u10)
(define-constant ERR-ALREADY-COMPLETED u11)
(define-constant ERR-SERVICE-NOT-COMPLETED u12)
(define-constant ERR-FEEDBACK-ALREADY-GIVEN u13)
(define-constant ERR-ENDORSEMENT-ALREADY-EXISTS u14)
(define-constant ERR-SELF-ACTION-NOT-ALLOWED u15)
(define-constant ERR-SERVICE-ALREADY-STARTED u16)
(define-constant ERR-SERVICE-NOT-STARTED u17)
(define-constant ERR-SERVICE-ALREADY-CANCELED u18)
(define-constant ERR-DISPUTE-ALREADY-EXISTS u19)
(define-constant ERR-DISPUTE-NOT-FOUND u20)
(define-constant ERR-NOT-DISPUTE-PARTICIPANT u21)
(define-constant ERR-NOT-ARBITER u22)
(define-constant ERR-DISPUTE-ALREADY-RESOLVED u23)

;; Enhanced error codes
(define-constant ERR-CERTIFICATION-NOT-FOUND u30)
(define-constant ERR-GOVERNANCE-PROPOSAL-NOT-FOUND u31)
(define-constant ERR-VOTE-ALREADY-CAST u32)
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED u33)
(define-constant ERR-INSUFFICIENT-STAKE u34)
(define-constant ERR-REWARD-ALREADY-CLAIMED u35)

;; Service status constants
(define-constant SERVICE-STATUS-PENDING u1)
(define-constant SERVICE-STATUS-STARTED u2)
(define-constant SERVICE-STATUS-COMPLETED u3)
(define-constant SERVICE-STATUS-VERIFIED u4)
(define-constant SERVICE-STATUS-DISPUTED u5)
(define-constant SERVICE-STATUS-CANCELED u6)

;; Dispute status constants
(define-constant DISPUTE-STATUS-OPEN u1)
(define-constant DISPUTE-STATUS-RESOLVED u2)

;; Enhanced feature constants
(define-constant CERTIFICATION-STATUS-PENDING u1)
(define-constant CERTIFICATION-STATUS-APPROVED u2)
(define-constant CERTIFICATION-STATUS-REJECTED u3)

(define-constant PROPOSAL-STATUS-ACTIVE u1)
(define-constant PROPOSAL-STATUS-EXECUTED u2)
(define-constant PROPOSAL-STATUS-REJECTED u3)

(define-constant VOTE-YES u1)
(define-constant VOTE-NO u2)
(define-constant VOTE-ABSTAIN u3)

;; Base data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-user-id uint u1)
(define-data-var next-skill-id uint u1)
(define-data-var next-service-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var community-fund uint u0)

;; Enhanced data variables
(define-data-var next-certification-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var governance-token-balance uint u0)
(define-data-var total-stake uint u0)

;; Base maps
(define-map users
  { user-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    bio: (string-utf8 500),
    time-balance: uint,
    time-contributed: uint,
    time-received: uint,
    reputation-score: uint,
    feedback-count: uint,
    avg-rating: uint,
    join-block: uint,
    last-active-block: uint,
    is-active: bool,
    is-arbiter: bool
  }
)

(define-map principal-to-user-id
  { principal: principal }
  { user-id: uint }
)

(define-map skills
  { skill-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    category: (string-utf8 100),
    created-at: uint,
    provider-count: uint
  }
)

(define-map skill-providers
  { skill-id: uint, user-id: uint }
  {
    hourly-rate: uint,
    experience-level: (string-utf8 50),
    availability: (string-utf8 500),
    endorsement-count: uint,
    created-at: uint
  }
)

(define-map services
  { service-id: uint }
  {
    provider-id: uint,
    receiver-id: uint,
    skill-id: uint,
    description: (string-utf8 500),
    estimated-minutes: uint,
    actual-minutes: (optional uint),
    status: uint,
    created-at: uint,
    started-at: (optional uint),
    completed-at: (optional uint),
    verified-at: (optional uint),
    notes: (string-utf8 500)
  }
)

;; Enhanced maps
(define-map certifications
  { certification-id: uint }
  {
    skill-id: uint,
    user-id: uint,
    certifier-id: uint,
    level: (string-utf8 50),
    status: uint,
    evidence: (string-utf8 500),
    created-at: uint,
    approved-at: (optional uint),
    expires-at: (optional uint)
  }
)

(define-map user-certifications
  { user-id: uint, skill-id: uint }
  { certification-id: uint }
)

(define-map governance-proposals
  { proposal-id: uint }
  {
    title: (string-utf8 200),
    description: (string-utf8 1000),
    proposed-by: uint,
    action: (string-utf8 500),
    status: uint,
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint,
    required-stake: uint,
    created-at: uint,
    voting-deadline: uint,
    executed-at: (optional uint)
  }
)

(define-map user-votes
  { proposal-id: uint, user-id: uint }
  {
    vote: uint,
    stake-amount: uint,
    voted-at: uint
  }
)

(define-map enhanced-users
  { user-id: uint }
  {
    governance-stake: uint,
    total-certifications: uint,
    governance-participation: uint
  }
)

;; Base read-only functions
(define-read-only (get-user (user-id uint))
  (map-get? users { user-id: user-id })
)

(define-read-only (get-user-id-by-principal (user-principal principal))
  (map-get? principal-to-user-id { principal: user-principal })
)

(define-read-only (get-skill (skill-id uint))
  (map-get? skills { skill-id: skill-id })
)

(define-read-only (get-service (service-id uint))
  (map-get? services { service-id: service-id })
)

(define-read-only (get-skill-provider (skill-id uint) (user-id uint))
  (map-get? skill-providers { skill-id: skill-id, user-id: user-id })
)

(define-read-only (offers-skill? (user-id uint) (skill-id uint))
  (is-some (get-skill-provider skill-id user-id))
)

;; Enhanced read-only functions
(define-read-only (get-certification (certification-id uint))
  (map-get? certifications { certification-id: certification-id })
)

(define-read-only (get-user-certification (user-id uint) (skill-id uint))
  (map-get? user-certifications { user-id: user-id, skill-id: skill-id })
)

(define-read-only (get-governance-proposal (proposal-id uint))
  (map-get? governance-proposals { proposal-id: proposal-id })
)

(define-read-only (get-user-vote (proposal-id uint) (user-id uint))
  (map-get? user-votes { proposal-id: proposal-id, user-id: user-id })
)

(define-read-only (get-enhanced-user (user-id uint))
  (map-get? enhanced-users { user-id: user-id })
)

;; Base public functions (simplified for enhanced contract)

;; Register a new user
(define-public (register-user (name (string-utf8 100)) (bio (string-utf8 500)))
  (let
    (
      (user-id (var-get next-user-id))
    )
    ;; Check if principal is already registered
    (asserts! (is-none (get-user-id-by-principal tx-sender)) (err ERR-ALREADY-EXISTS))
    
    ;; Create user profile
    (map-set users
      { user-id: user-id }
      {
        principal: tx-sender,
        name: name,
        bio: bio,
        time-balance: u60, ;; Start with 1 hour credit
        time-contributed: u0,
        time-received: u0,
        reputation-score: u50, ;; Default starting reputation
        feedback-count: u0,
        avg-rating: u0,
        join-block: block-height,
        last-active-block: block-height,
        is-active: true,
        is-arbiter: false
      }
    )
    
    ;; Map principal to user ID
    (map-set principal-to-user-id
      { principal: tx-sender }
      { user-id: user-id }
    )
    
    ;; Initialize enhanced user profile
    (map-set enhanced-users
      { user-id: user-id }
      {
        governance-stake: u0,
        total-certifications: u0,
        governance-participation: u0
      }
    )
    
    ;; Increment user ID
    (var-set next-user-id (+ user-id u1))
    
    (ok user-id)
  )
)

;; Add a new skill category
(define-public (add-skill-category (name (string-utf8 100)) (description (string-utf8 500)) (category (string-utf8 100)))
  (let
    (
      (skill-id (var-get next-skill-id))
    )
    
    ;; Only contract owner can add skill categories
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Create skill
    (map-set skills
      { skill-id: skill-id }
      {
        name: name,
        description: description,
        category: category,
        created-at: block-height,
        provider-count: u0
      }
    )
    
    ;; Increment skill ID
    (var-set next-skill-id (+ skill-id u1))
    
    (ok skill-id)
  )
)

;; Register as a provider for a skill
(define-public (register-as-provider 
  (skill-id uint) 
  (hourly-rate uint) 
  (experience-level (string-utf8 50))
  (availability (string-utf8 500))
)
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (skill (unwrap! (get-skill skill-id) (err ERR-SKILL-NOT-FOUND)))
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if already registered for this skill
    (asserts! (is-none (get-skill-provider skill-id user-id)) (err ERR-ALREADY-EXISTS))
    
    ;; Register as provider
    (map-set skill-providers
      { skill-id: skill-id, user-id: user-id }
      {
        hourly-rate: hourly-rate,
        experience-level: experience-level,
        availability: availability,
        endorsement-count: u0,
        created-at: block-height
      }
    )
    
    ;; Update skill provider count
    (map-set skills
      { skill-id: skill-id }
      (merge skill {
        provider-count: (+ (get provider-count skill) u1)
      })
    )
    
    ;; Update user's last active block
    (map-set users
      { user-id: user-id }
      (merge user {
        last-active-block: block-height
      })
    )
    
    (ok true)
  )
)

;; Enhanced public functions

;; Request skill certification
(define-public (request-certification (skill-id uint) (level (string-utf8 50)) (evidence (string-utf8 500)))
  (let
    (
      (certification-id (var-get next-certification-id))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (skill (unwrap! (get-skill skill-id) (err ERR-SKILL-NOT-FOUND)))
    )
    
    ;; Check if user offers this skill
    (asserts! (offers-skill? user-id skill-id) (err ERR-NOT-SERVICE-PROVIDER))
    
    ;; Create certification request
    (map-set certifications
      { certification-id: certification-id }
      {
        skill-id: skill-id,
        user-id: user-id,
        certifier-id: u0, ;; Will be set when approved
        level: level,
        status: CERTIFICATION-STATUS-PENDING,
        evidence: evidence,
        created-at: block-height,
        approved-at: none,
        expires-at: none
      }
    )
    
    ;; Increment certification ID
    (var-set next-certification-id (+ certification-id u1))
    
    (ok certification-id)
  )
)

;; Approve certification (by arbiters or high-reputation users)
(define-public (approve-certification (certification-id uint) (certifier-id uint))
  (let
    (
      (certification (unwrap! (get-certification certification-id) (err ERR-CERTIFICATION-NOT-FOUND)))
      (certifier (unwrap! (get-user certifier-id) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id certification))
      (enhanced-user (default-to { governance-stake: u0, total-certifications: u0, governance-participation: u0 } 
                                (map-get? enhanced-users { user-id: user-id })))
    )
    
    ;; Check if certification is pending
    (asserts! (is-eq (get status certification) CERTIFICATION-STATUS-PENDING) (err ERR-CERTIFICATION-NOT-FOUND))
    
    ;; Check if certifier is qualified (arbiter or has high reputation)
    (asserts! (or (get is-arbiter certifier) (>= (get reputation-score certifier) u80)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update certification status
    (map-set certifications
      { certification-id: certification-id }
      (merge certification {
        status: CERTIFICATION-STATUS-APPROVED,
        certifier-id: certifier-id,
        approved-at: (some block-height),
        expires-at: (some (+ block-height (* u365 u1440))) ;; 1 year expiration
      })
    )
    
    ;; Add to user's certifications
    (map-set user-certifications
      { user-id: user-id, skill-id: (get skill-id certification) }
      { certification-id: certification-id }
    )
    
    ;; Update enhanced user stats
    (map-set enhanced-users
      { user-id: user-id }
      (merge enhanced-user {
        total-certifications: (+ (get total-certifications enhanced-user) u1)
      })
    )
    
    (ok true)
  )
)

;; Create governance proposal
(define-public (create-governance-proposal (title (string-utf8 200)) (description (string-utf8 1000)) (action (string-utf8 500)) (required-stake uint))
  (let
    (
      (proposal-id (var-get next-proposal-id))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (enhanced-user (default-to { governance-stake: u0, total-certifications: u0, governance-participation: u0 } 
                                (map-get? enhanced-users { user-id: user-id })))
    )
    
    ;; Check if user has sufficient stake
    (asserts! (>= (get governance-stake enhanced-user) required-stake) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Create proposal
    (map-set governance-proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        proposed-by: user-id,
        action: action,
        status: PROPOSAL-STATUS-ACTIVE,
        yes-votes: u0,
        no-votes: u0,
        abstain-votes: u0,
        required-stake: required-stake,
        created-at: block-height,
        voting-deadline: (+ block-height (* u7 u1440)), ;; 7 days voting period
        executed-at: none
      }
    )
    
    ;; Update user's governance participation
    (map-set enhanced-users
      { user-id: user-id }
      (merge enhanced-user {
        governance-participation: (+ (get governance-participation enhanced-user) u1)
      })
    )
    
    ;; Increment proposal ID
    (var-set next-proposal-id (+ proposal-id u1))
    
    (ok proposal-id)
  )
)

;; Vote on governance proposal
(define-public (vote-on-proposal (proposal-id uint) (vote uint) (stake-amount uint))
  (let
    (
      (proposal (unwrap! (get-governance-proposal proposal-id) (err ERR-GOVERNANCE-PROPOSAL-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (enhanced-user (default-to { governance-stake: u0, total-certifications: u0, governance-participation: u0 } 
                                (map-get? enhanced-users { user-id: user-id })))
    )
    
    ;; Check if proposal is active
    (asserts! (is-eq (get status proposal) PROPOSAL-STATUS-ACTIVE) (err ERR-PROPOSAL-ALREADY-EXECUTED))
    
    ;; Check if voting deadline hasn't passed
    (asserts! (< block-height (get voting-deadline proposal)) (err ERR-INVALID-PARAMETERS))
    
    ;; Check if user hasn't already voted
    (asserts! (is-none (get-user-vote proposal-id user-id)) (err ERR-VOTE-ALREADY-CAST))
    
    ;; Check if user has sufficient stake
    (asserts! (>= (get governance-stake enhanced-user) stake-amount) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Record vote
    (map-set user-votes
      { proposal-id: proposal-id, user-id: user-id }
      {
        vote: vote,
        stake-amount: stake-amount,
        voted-at: block-height
      }
    )
    
    ;; Update proposal vote counts
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        yes-votes: (if (is-eq vote VOTE-YES) (+ (get yes-votes proposal) stake-amount) (get yes-votes proposal)),
        no-votes: (if (is-eq vote VOTE-NO) (+ (get no-votes proposal) stake-amount) (get no-votes proposal)),
        abstain-votes: (if (is-eq vote VOTE-ABSTAIN) (+ (get abstain-votes proposal) stake-amount) (get abstain-votes proposal))
      })
    )
    
    (ok true)
  )
)

;; Execute governance proposal
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (get-governance-proposal proposal-id) (err ERR-GOVERNANCE-PROPOSAL-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
    )
    
    ;; Check if caller is contract owner or proposal creator
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) (is-eq user-id (get proposed-by proposal))) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if proposal is active
    (asserts! (is-eq (get status proposal) PROPOSAL-STATUS-ACTIVE) (err ERR-PROPOSAL-ALREADY-EXECUTED))
    
    ;; Check if voting deadline has passed
    (asserts! (>= block-height (get voting-deadline proposal)) (err ERR-INVALID-PARAMETERS))
    
    ;; Check if proposal passed (more yes votes than no votes)
    (let
      (
        (yes-votes (get yes-votes proposal))
        (no-votes (get no-votes proposal))
        (passed (> yes-votes no-votes))
      )
      
      ;; Update proposal status
      (map-set governance-proposals
        { proposal-id: proposal-id }
        (merge proposal {
          status: (if passed PROPOSAL-STATUS-EXECUTED PROPOSAL-STATUS-REJECTED),
          executed-at: (some block-height)
        })
      )
      
      (ok passed)
    )
  )
)

;; Stake governance tokens
(define-public (stake-governance-tokens (amount uint))
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
      (enhanced-user (default-to { governance-stake: u0, total-certifications: u0, governance-participation: u0 } 
                                (map-get? enhanced-users { user-id: user-id })))
    )
    
    ;; Check if user has enough time balance
    (asserts! (>= (get time-balance user) amount) (err ERR-INSUFFICIENT-BALANCE))
    
    ;; Deduct from user's time balance
    (map-set users
      { user-id: user-id }
      (merge user {
        time-balance: (- (get time-balance user) amount)
      })
    )
    
    ;; Add to user's governance stake
    (map-set enhanced-users
      { user-id: user-id }
      (merge enhanced-user {
        governance-stake: (+ (get governance-stake enhanced-user) amount)
      })
    )
    
    ;; Update total stake
    (var-set total-stake (+ (var-get total-stake) amount))
    
    ;; Update governance token balance
    (var-set governance-token-balance (+ (var-get governance-token-balance) amount))
    
    (ok true)
  )
)

;; Unstake governance tokens
(define-public (unstake-governance-tokens (amount uint))
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
      (enhanced-user (default-to { governance-stake: u0, total-certifications: u0, governance-participation: u0 } 
                                (map-get? enhanced-users { user-id: user-id })))
    )
    
    ;; Check if user has enough stake
    (asserts! (>= (get governance-stake enhanced-user) amount) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Deduct from user's governance stake
    (map-set enhanced-users
      { user-id: user-id }
      (merge enhanced-user {
        governance-stake: (- (get governance-stake enhanced-user) amount)
      })
    )
    
    ;; Add back to user's time balance
    (map-set users
      { user-id: user-id }
      (merge user {
        time-balance: (+ (get time-balance user) amount)
      })
    )
    
    ;; Update total stake
    (var-set total-stake (- (var-get total-stake) amount))
    
    ;; Update governance token balance
    (var-set governance-token-balance (- (var-get governance-token-balance) amount))
    
    (ok true)
  )
)

;; Initialize enhanced contract
(define-public (initialize-enhanced)
  (begin
    ;; Set initial values
    (var-set next-certification-id u1)
    (var-set next-proposal-id u1)
    (var-set governance-token-balance u0)
    (var-set total-stake u0)
    
    (ok true)
  )
) 