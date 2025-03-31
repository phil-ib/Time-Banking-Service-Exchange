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
