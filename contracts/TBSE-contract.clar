;; Time-Banking Service Exchange
;; A platform for community members to exchange services based on time contributions

;; Error codes
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

;; Constants for service status
(define-constant SERVICE-STATUS-PENDING u1)
(define-constant SERVICE-STATUS-STARTED u2)
(define-constant SERVICE-STATUS-COMPLETED u3)
(define-constant SERVICE-STATUS-VERIFIED u4)
(define-constant SERVICE-STATUS-DISPUTED u5)
(define-constant SERVICE-STATUS-CANCELED u6)

;; Constants for dispute status
(define-constant DISPUTE-STATUS-OPEN u1)
(define-constant DISPUTE-STATUS-RESOLVED u2)

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-user-id uint u1)
(define-data-var next-skill-id uint u1)
(define-data-var next-service-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var community-fund uint u0) ;; Pool of time credits for community initiatives

;; User profile data structure
(define-map users
  { user-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    bio: (string-utf8 500),
    time-balance: uint,            ;; Time credits in minutes
    time-contributed: uint,         ;; Total time contributed
    time-received: uint,            ;; Total time received
    reputation-score: uint,         ;; 0-100 score
    feedback-count: uint,
    avg-rating: uint,               ;; 0-100 average rating
    join-block: uint,
    last-active-block: uint,
    is-active: bool,
    is-arbiter: bool                ;; Can help resolve disputes
  }
)

;; Map principal to user-id for quick lookups
(define-map principal-to-user-id
  { principal: principal }
  { user-id: uint }
)

;; Skill categories
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

;; Skill providers - users offering specific skills
(define-map skill-providers
  { skill-id: uint, user-id: uint }
  {
    hourly-rate: uint,             ;; Rate in minutes (usually 60 = 1 hour)
    experience-level: (string-utf8 50), ;; "beginner", "intermediate", "expert"
    availability: (string-utf8 500),
    endorsement-count: uint,
    created-at: uint
  }
)

;; Map to track all skills offered by a user
(define-map user-skills
  { user-id: uint, index: uint }
  { skill-id: uint }
)

;; Map to count skills per user
(define-map user-skill-count
  { user-id: uint }
  { count: uint }
)

;; Service exchange records
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

;; Map to track provider's services
(define-map provider-services
  { user-id: uint, index: uint }
  { service-id: uint }
)

;; Map to count services provided by user
(define-map provider-service-count
  { user-id: uint }
  { count: uint }
)
;; Map to track receiver's services
(define-map receiver-services
  { user-id: uint, index: uint }
  { service-id: uint }
)

;; Map to count services received by user
(define-map receiver-service-count
  { user-id: uint }
  { count: uint }
)

;; Feedback for completed services
(define-map service-feedback
  { service-id: uint, feedback-by: uint }
  {
    rating: uint,                  ;; 0-100 rating
    comment: (string-utf8 500),
    created-at: uint
  }
)

;; Skill endorsements between users
(define-map skill-endorsements
  { skill-id: uint, endorsed-user-id: uint, endorser-user-id: uint }
  {
    comment: (string-utf8 200),
    created-at: uint
  }
)

;; Dispute records
(define-map disputes
  { dispute-id: uint }
  {
    service-id: uint,
    raised-by-id: uint,
    raised-against-id: uint,
    description: (string-utf8 500),
    status: uint,
    arbiter-id: (optional uint),
    resolution: (optional (string-utf8 500)),
    time-adjustment: (optional int),
    created-at: uint,
    resolved-at: (optional uint)
  }
)

;; Read-only functions

;; Get user details
(define-read-only (get-user (user-id uint))
  (map-get? users { user-id: user-id })
)

;; Get user ID from principal
(define-read-only (get-user-id-by-principal (user-principal principal))
  (map-get? principal-to-user-id { principal: user-principal })
)

;; Get skill details
(define-read-only (get-skill (skill-id uint))
  (map-get? skills { skill-id: skill-id })
)

;; Get service details
(define-read-only (get-service (service-id uint))
  (map-get? services { service-id: service-id })
)

;; Get skill provider details
(define-read-only (get-skill-provider (skill-id uint) (user-id uint))
  (map-get? skill-providers { skill-id: skill-id, user-id: user-id })
)

;; Check if a user offers a particular skill
(define-read-only (offers-skill? (user-id uint) (skill-id uint))
  (is-some (get-skill-provider skill-id user-id))
)

;; Get feedback for a service
(define-read-only (get-service-feedback (service-id uint) (feedback-by uint))
  (map-get? service-feedback { service-id: service-id, feedback-by: feedback-by })
)

;; Check if a user has endorsed another user for a skill
(define-read-only (has-endorsed? (skill-id uint) (endorsed-user-id uint) (endorser-user-id uint))
  (is-some (map-get? skill-endorsements 
    { skill-id: skill-id, endorsed-user-id: endorsed-user-id, endorser-user-id: endorser-user-id }))
)

;; Get dispute details
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

;; Check if a dispute exists for a service
(define-read-only (service-has-dispute? (service-id uint))
  (let
    (
      (service (unwrap! (get-service service-id) false))
    )
    (is-eq (get status service) SERVICE-STATUS-DISPUTED)
  )
)

;; Public functions

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
    
    ;; Initialize skill count
    (map-set user-skill-count
      { user-id: user-id }
      { count: u0 }
    )
    
    ;; Initialize service counts
    (map-set provider-service-count
      { user-id: user-id }
      { count: u0 }
    )
    
    (map-set receiver-service-count
      { user-id: user-id }
      { count: u0 }
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
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
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
    
    ;; Add to user's skills
    (let
      (
        (current-count (get count (default-to { count: u0 } 
                                          (map-get? user-skill-count { user-id: user-id }))))
      )
      (map-set user-skills
        { user-id: user-id, index: current-count }
        { skill-id: skill-id }
      )
      
      (map-set user-skill-count
        { user-id: user-id }
        { count: (+ current-count u1) }
      )
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

;; Request a service
(define-public (request-service
  (provider-id uint)
  (skill-id uint)
  (description (string-utf8 500))
  (estimated-minutes uint)
  (notes (string-utf8 500))
)
  (let
    (
      (service-id (var-get next-service-id))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (receiver-id (get user-id user-mapping))
      (receiver (unwrap! (get-user receiver-id) (err ERR-USER-NOT-FOUND)))
      (provider (unwrap! (get-user provider-id) (err ERR-USER-NOT-FOUND)))
      (provider-skill (unwrap! (get-skill-provider skill-id provider-id) (err ERR-NOT-SERVICE-PROVIDER)))
    )
    
    ;; Cannot request service from yourself
    (asserts! (not (is-eq provider-id receiver-id)) (err ERR-SELF-ACTION-NOT-ALLOWED))
    
    ;; Check if provider is active
    (asserts! (get is-active provider) (err ERR-USER-NOT-FOUND))
    
    ;; Check if receiver has enough time balance
    (asserts! (>= (get time-balance receiver) estimated-minutes) (err ERR-INSUFFICIENT-BALANCE))
    
    ;; Create service request
    (map-set services
      { service-id: service-id }
      {
        provider-id: provider-id,
        receiver-id: receiver-id,
        skill-id: skill-id,
        description: description,
        estimated-minutes: estimated-minutes,
        actual-minutes: none,
        status: SERVICE-STATUS-PENDING,
        created-at: block-height,
        started-at: none,
        completed-at: none,
        verified-at: none,
        notes: notes
      }
    )
    
    ;; Update provider's service list
    (let
      (
        (provider-count (get count (default-to { count: u0 } 
                                          (map-get? provider-service-count { user-id: provider-id }))))
      )
      (map-set provider-services
        { user-id: provider-id, index: provider-count }
        { service-id: service-id }
      )
      
      (map-set provider-service-count
        { user-id: provider-id }
        { count: (+ provider-count u1) }
      )
    )
    
    ;; Update receiver's service list
    (let
      (
        (receiver-count (get count (default-to { count: u0 } 
                                          (map-get? receiver-service-count { user-id: receiver-id }))))
      )
      (map-set receiver-services
        { user-id: receiver-id, index: receiver-count }
        { service-id: service-id }
      )
      
      (map-set receiver-service-count
        { user-id: receiver-id }
        { count: (+ receiver-count u1) }
      )
    )
    
    ;; Update user's last active block
    (map-set users
      { user-id: receiver-id }
      (merge receiver {
        last-active-block: block-height
      })
    )
    
    ;; Increment service ID
    (var-set next-service-id (+ service-id u1))
    
    (ok service-id)
  )
)

;; Start a service
(define-public (start-service (service-id uint))
  (let
    (
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (provider (unwrap! (get-user provider-id) (err ERR-USER-NOT-FOUND)))
      (receiver (unwrap! (get-user receiver-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if caller is the provider
    (asserts! (is-eq user-id provider-id) (err ERR-NOT-SERVICE-PROVIDER))
    
    ;; Check if service is in pending status
    (asserts! (is-eq (get status service) SERVICE-STATUS-PENDING) (err ERR-SERVICE-ALREADY-STARTED))
    
    ;; Check if receiver has enough time balance
    (asserts! (>= (get time-balance receiver) (get estimated-minutes service)) (err ERR-INSUFFICIENT-BALANCE))
    
    ;; Reserve the time from receiver's balance
    (map-set users
      { user-id: receiver-id }
      (merge receiver {
        time-balance: (- (get time-balance receiver) (get estimated-minutes service)),
        last-active-block: block-height
      })
    )
    
    ;; Update service status
    (map-set services
      { service-id: service-id }
      (merge service {
        status: SERVICE-STATUS-STARTED,
        started-at: (some block-height)
      })
    )
    
    ;; Update provider's last active block
    (map-set users
      { user-id: provider-id }
      (merge provider {
        last-active-block: block-height
      })
    )
    
    (ok true)
  )
)

;; Complete a service
(define-public (complete-service (service-id uint) (actual-minutes uint))
  (let
    (
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (provider (unwrap! (get-user provider-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if caller is the provider
    (asserts! (is-eq user-id provider-id) (err ERR-NOT-SERVICE-PROVIDER))
    
    ;; Check if service is in started status
    (asserts! (is-eq (get status service) SERVICE-STATUS-STARTED) (err ERR-SERVICE-NOT-STARTED))
    
    ;; Update service status
    (map-set services
      { service-id: service-id }
      (merge service {
        status: SERVICE-STATUS-COMPLETED,
        completed-at: (some block-height),
        actual-minutes: (some actual-minutes)
      })
    )
    
    ;; Update provider's last active block
    (map-set users
      { user-id: provider-id }
      (merge provider {
        last-active-block: block-height
      })
    )
    
    (ok true)
  )
)

;; Verify a completed service
(define-public (verify-service (service-id uint))
  (let
    (
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (provider (unwrap! (get-user provider-id) (err ERR-USER-NOT-FOUND)))
      (receiver (unwrap! (get-user receiver-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if caller is the receiver
    (asserts! (is-eq user-id receiver-id) (err ERR-NOT-SERVICE-RECEIVER))
    
    ;; Check if service is in completed status
    (asserts! (is-eq (get status service) SERVICE-STATUS-COMPLETED) (err ERR-SERVICE-NOT-COMPLETED))
    
    ;; Get the actual minutes spent
    (let
      (
        (actual-mins (unwrap! (get actual-minutes service) (err ERR-INVALID-PARAMETERS)))
        (estimated-mins (get estimated-minutes service))
        (time-difference (- actual-mins estimated-mins))
        (refund-amount (if (< actual-mins estimated-mins) (- estimated-mins actual-mins) u0))
      )
      
      ;; Credit provider's time balance
      (map-set users
        { user-id: provider-id }
        (merge provider {
          time-balance: (+ (get time-balance provider) actual-mins),
          time-contributed: (+ (get time-contributed provider) actual-mins),
          last-active-block: block-height
        })
      )
      
      ;; Refund receiver if service took less time than estimated
      (if (> refund-amount u0)
        (map-set users
          { user-id: receiver-id }
          (merge receiver {
            time-balance: (+ (get time-balance receiver) refund-amount)
          })
        )
        true
      )
      
      ;; Update receiver's time received
      (map-set users
        { user-id: receiver-id }
        (merge receiver {
          time-received: (+ (get time-received receiver) actual-mins),
          last-active-block: block-height
        })
      )
      
      ;; Update service status
      (map-set services
        { service-id: service-id }
        (merge service {
          status: SERVICE-STATUS-VERIFIED,
          verified-at: (some block-height)
        })
      )
      
      ;; Add small donation to community fund (1% of time)
      (var-set community-fund (+ (var-get community-fund) (/ actual-mins u100)))
      
      (ok true)
    )
  )
)
;; Leave feedback for a service
(define-public (leave-feedback (service-id uint) (rating uint) (comment (string-utf8 500)))
  (let
    (
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (is-provider (is-eq user-id provider-id))
      (is-receiver (is-eq user-id receiver-id))
      (feedback-target-id (if is-provider receiver-id provider-id))
      (feedback-target (unwrap! (get-user feedback-target-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if caller is either provider or receiver
    (asserts! (or is-provider is-receiver) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if service is verified
    (asserts! (is-eq (get status service) SERVICE-STATUS-VERIFIED) (err ERR-SERVICE-NOT-COMPLETED))
    
    ;; Check if feedback already given
    (asserts! (is-none (map-get? service-feedback { service-id: service-id, feedback-by: user-id }))
              (err ERR-FEEDBACK-ALREADY-GIVEN))
    
    ;; Check rating range (0-100)
    (asserts! (<= rating u100) (err ERR-INVALID-PARAMETERS))
    
    ;; Record feedback
    (map-set service-feedback
      { service-id: service-id, feedback-by: user-id }
      {
        rating: rating,
        comment: comment,
        created-at: block-height
      }
    )
    
    ;; Update target's reputation and feedback stats
    (let
      (
        (current-count (get feedback-count feedback-target))
        (current-rating (get avg-rating feedback-target))
        (new-count (+ current-count u1))
        (new-rating (if (> current-count u0)
                       (/ (+ (* current-rating current-count) rating) new-count)
                       rating))
      )
      
      (map-set users
        { user-id: feedback-target-id }
        (merge feedback-target {
          feedback-count: new-count,
          avg-rating: new-rating,
          reputation-score: (/ (+ (get reputation-score feedback-target) new-rating) u2) ;; Blend of old reputation and new rating
        })
      )
    )
    
    (ok true)
  )
)

;; Endorse a user for a skill
(define-public (endorse-skill (skill-id uint) (endorsed-user-id uint) (comment (string-utf8 200)))
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (endorser-id (get user-id user-mapping))
      (skill (unwrap! (get-skill skill-id) (err ERR-SKILL-NOT-FOUND)))
      (endorsed-user (unwrap! (get-user endorsed-user-id) (err ERR-USER-NOT-FOUND)))
      (provider-skill (unwrap! (get-skill-provider skill-id endorsed-user-id) (err ERR-NOT-SERVICE-PROVIDER)))
    )
    
    ;; Cannot endorse yourself
    (asserts! (not (is-eq endorser-id endorsed-user-id)) (err ERR-SELF-ACTION-NOT-ALLOWED))
    
    ;; Check if already endorsed
    (asserts! (not (has-endorsed? skill-id endorsed-user-id endorser-id)) (err ERR-ENDORSEMENT-ALREADY-EXISTS))
    
    ;; Record endorsement
    (map-set skill-endorsements
      { skill-id: skill-id, endorsed-user-id: endorsed-user-id, endorser-user-id: endorser-id }
      {
        comment: comment,
        created-at: block-height
      }
    )
    
    ;; Update endorsement count
    (map-set skill-providers
      { skill-id: skill-id, user-id: endorsed-user-id }
      (merge provider-skill {
        endorsement-count: (+ (get endorsement-count provider-skill) u1)
      })
    )
    
    ;; Update endorsed user's reputation
    (map-set users
      { user-id: endorsed-user-id }
      (merge endorsed-user {
        reputation-score: (if (> (+ (get reputation-score endorsed-user) u2) u100) u100 (+ (get reputation-score endorsed-user) u2)) ;; Small boost to reputation
      })
    )
    
    (ok true)
  )
)

;; Cancel a service
(define-public (cancel-service (service-id uint))
  (let
    (
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (receiver (unwrap! (get-user receiver-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if caller is either provider or receiver
    (asserts! (or (is-eq user-id provider-id) (is-eq user-id receiver-id)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if service is in pending or started status
    (asserts! (or (is-eq (get status service) SERVICE-STATUS-PENDING)
                 (is-eq (get status service) SERVICE-STATUS-STARTED))
              (err ERR-SERVICE-ALREADY-CANCELED))
    
    ;; If service was started, refund time to receiver
    (if (is-eq (get status service) SERVICE-STATUS-STARTED)
      (map-set users
        { user-id: receiver-id }
        (merge receiver {
          time-balance: (+ (get time-balance receiver) (get estimated-minutes service))
        })
      )
      true
    )
    
    ;; Update service status
    (map-set services
      { service-id: service-id }
      (merge service {
        status: SERVICE-STATUS-CANCELED
      })
    )
    
    (ok true)
  )
)

;; Raise a dispute
(define-public (raise-dispute (service-id uint) (description (string-utf8 500)))
  (let
    (
      (dispute-id (var-get next-dispute-id))
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
    )
    
    ;; Check if caller is either provider or receiver
    (asserts! (or (is-eq user-id provider-id) (is-eq user-id receiver-id)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if service is not already in disputed status
    (asserts! (not (is-eq (get status service) SERVICE-STATUS-DISPUTED)) (err ERR-DISPUTE-ALREADY-EXISTS))
    
    ;; Check if service was started
    (asserts! (or (is-eq (get status service) SERVICE-STATUS-STARTED)
                 (is-eq (get status service) SERVICE-STATUS-COMPLETED))
              (err ERR-INVALID-PARAMETERS))
    
    ;; Create dispute
    (map-set disputes
      { dispute-id: dispute-id }
      {
        service-id: service-id,
        raised-by-id: user-id,
        raised-against-id: (if (is-eq user-id provider-id) receiver-id provider-id),
        description: description,
        status: DISPUTE-STATUS-OPEN,
        arbiter-id: none,
        resolution: none,
        time-adjustment: none,
        created-at: block-height,
        resolved-at: none
      }
    )
    
    ;; Update service status
    (map-set services
      { service-id: service-id }
      (merge service {
        status: SERVICE-STATUS-DISPUTED
      })
    )
    
    ;; Increment dispute ID
    (var-set next-dispute-id (+ dispute-id u1))
    
    (ok dispute-id)
  )
)

;; Assign arbiter to dispute
(define-public (assign-arbiter (dispute-id uint) (arbiter-id uint))
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
      (arbiter (unwrap! (get-user arbiter-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Only contract owner can assign arbiters
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if dispute is open
    (asserts! (is-eq (get status dispute) DISPUTE-STATUS-OPEN) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Check if user is an arbiter
    (asserts! (get is-arbiter arbiter) (err ERR-NOT-ARBITER))
    
    ;; Assign arbiter
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        arbiter-id: (some arbiter-id)
      })
    )
    
    (ok true)
  )
)

;; Resolve a dispute
(define-public (resolve-dispute (dispute-id uint) (resolution (string-utf8 500)) (time-adjustment int))
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (service-id (get service-id dispute))
      (service (unwrap! (get-service service-id) (err ERR-SERVICE-NOT-FOUND)))
      (provider-id (get provider-id service))
      (receiver-id (get receiver-id service))
      (provider (unwrap! (get-user provider-id) (err ERR-USER-NOT-FOUND)))
      (receiver (unwrap! (get-user receiver-id) (err ERR-USER-NOT-FOUND)))
    )
  ;; Check if dispute is open
    (asserts! (is-eq (get status dispute) DISPUTE-STATUS-OPEN) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Check if caller is the assigned arbiter or contract owner
    (asserts! (or (is-eq (some user-id) (get arbiter-id dispute))
                 (is-eq tx-sender (var-get contract-owner)))
              (err ERR-NOT-AUTHORIZED))
    
    ;; Resolve dispute
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: DISPUTE-STATUS-RESOLVED,
        resolution: (some resolution),
        time-adjustment: (some time-adjustment),
        resolved-at: (some block-height)
      })
    )
    
    ;; Apply time adjustment if needed
    (if (not (is-eq time-adjustment 0))
      (if (> time-adjustment 0)
        ;; Additional time for provider (from receiver)
        (begin
          ;; Check if receiver has enough balance
          (if (>= (get time-balance receiver) (to-uint time-adjustment))
            (begin
              ;; Deduct from receiver
              (map-set users
                { user-id: receiver-id }
                (merge receiver {
                  time-balance: (- (get time-balance receiver) (to-uint time-adjustment))
                })
              )
              ;; Add to provider
              (map-set users
                { user-id: provider-id }
                (merge provider {
                  time-balance: (+ (get time-balance provider) (to-uint time-adjustment)),
                  time-contributed: (+ (get time-contributed provider) (to-uint time-adjustment))
                })
              )
            )
            ;; Insufficient balance, take from community fund
            (begin
              (var-set community-fund (- (var-get community-fund) (to-uint time-adjustment)))
              (map-set users
                { user-id: provider-id }
                (merge provider {
                  time-balance: (+ (get time-balance provider) (to-uint time-adjustment)),
                  time-contributed: (+ (get time-contributed provider) (to-uint time-adjustment))
                })
              )
            )
          )
        )
        ;; Time refund to receiver (negative adjustment means provider gets less)
        (begin
          (let
            (
              (abs-adjustment (to-uint (- 0 time-adjustment)))
            )
            ;; Check if provider has enough balance
            (if (>= (get time-balance provider) abs-adjustment)
              (begin
                ;; Deduct from provider
                (map-set users
                  { user-id: provider-id }
                  (merge provider {
                    time-balance: (- (get time-balance provider) abs-adjustment)
                  })
                )
                ;; Add to receiver
                (map-set users
                  { user-id: receiver-id }
                  (merge receiver {
                    time-balance: (+ (get time-balance receiver) abs-adjustment)
                  })
                )
              )
              ;; Insufficient balance, take from community fund
              (begin
                (var-set community-fund (- (var-get community-fund) abs-adjustment))
                (map-set users
                  { user-id: receiver-id }
                  (merge receiver {
                    time-balance: (+ (get time-balance receiver) abs-adjustment)
                  })
                )
              )
            )
          )
        )
      )
      true
    )
    
    ;; Update service status to completed or verified depending on original status
    (map-set services
      { service-id: service-id }
      (merge service {
        status: SERVICE-STATUS-COMPLETED ;; Reset to completed status after dispute resolution
      })
    )
    
    (ok true)
  )
)

;; Make a user an arbiter
(define-public (make-arbiter (user-id uint))
  (let
    (
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Only contract owner can make users arbiters
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update user
    (map-set users
      { user-id: user-id }
      (merge user {
        is-arbiter: true
      })
    )
    
    (ok true)
  )
)

;; Transfer time credits to community fund
(define-public (donate-to-community (amount uint))
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Check if user has enough balance
    (asserts! (>= (get time-balance user) amount) (err ERR-INSUFFICIENT-BALANCE))
    
    ;; Deduct from user
    (map-set users
      { user-id: user-id }
      (merge user {
        time-balance: (- (get time-balance user) amount)
      })
    )
    
    ;; Add to community fund
    (var-set community-fund (+ (var-get community-fund) amount))
    
    (ok true)
  )
)

;; Allocate time from community fund to user
(define-public (allocate-from-community (recipient-id uint) (amount uint) (reason (string-utf8 500)))
  (let
    (
      (recipient (unwrap! (get-user recipient-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Only contract owner can allocate from community fund
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if community fund has enough balance
    (asserts! (>= (var-get community-fund) amount) (err ERR-INSUFFICIENT-BALANCE))
    
    ;; Deduct from community fund
    (var-set community-fund (- (var-get community-fund) amount))
    
    ;; Add to recipient
    (map-set users
      { user-id: recipient-id }
      (merge recipient {
        time-balance: (+ (get time-balance recipient) amount)
      })
    )
    
    (ok true)
  )
)

;; Update user profile
(define-public (update-profile (name (string-utf8 100)) (bio (string-utf8 500)))
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (user (unwrap! (get-user user-id) (err ERR-USER-NOT-FOUND)))
    )
    
    ;; Update user profile
    (map-set users
      { user-id: user-id }
      (merge user {
        name: name,
        bio: bio,
        last-active-block: block-height
      })
    )
    
    (ok true)
  )
)

;; Update skill provider details
(define-public (update-provider-details 
  (skill-id uint) 
  (hourly-rate uint) 
  (experience-level (string-utf8 50))
  (availability (string-utf8 500))
)
  (let
    (
      (user-mapping (unwrap! (get-user-id-by-principal tx-sender) (err ERR-USER-NOT-FOUND)))
      (user-id (get user-id user-mapping))
      (provider-skill (unwrap! (get-skill-provider skill-id user-id) (err ERR-NOT-SERVICE-PROVIDER)))
    )
    
    ;; Update provider details
    (map-set skill-providers
      { skill-id: skill-id, user-id: user-id }
      (merge provider-skill {
        hourly-rate: hourly-rate,
        experience-level: experience-level,
        availability: availability
      })
    )
    
    (ok true)
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)