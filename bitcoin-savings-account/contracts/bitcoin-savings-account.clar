;; title: bitcoin-savings-account
;; Error constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-MINIMUM-DEPOSIT (err u3))
(define-constant ERR-WITHDRAWAL-FAILED (err u4))
(define-constant ERR-WITHDRAWAL-LIMIT (err u5))
(define-constant ERR-DEPOSIT-LIMIT (err u6))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u7))
(define-constant ERR-INVALID-CONFIGURATION (err u8))


;; Savings Account Storage
(define-map user-accounts 
  {user: principal} 
  {
    balance: uint,
    total-deposits: uint,
    total-withdrawals: uint,
    last-deposit-time: uint,
    accumulated-interest: uint
  }
)


;; Interest Rate Configuration
(define-data-var base-interest-rate uint u5) ;; 5% base rate
(define-data-var max-interest-rate uint u10) ;; 10% max rate
(define-data-var min-interest-rate uint u2)  ;; 2% min rate

;; Deposit Tiers
(define-map deposit-tiers 
  {tier: uint} 
  {
    min-amount: uint, 
    interest-bonus: uint
  }
)

;; Enhanced Account Management
(define-map account-metadata 
  {user: principal}
  {
    withdrawal-limit: uint,
    deposit-limit: uint,
    is-locked: bool,
    account-type: (string-ascii 20),
    created-at: uint
  }
)

;; Interest Configuration
(define-data-var interest-config 
  {
    base-rate: uint,
    max-rate: uint,
    min-rate: uint,
    compound-frequency: uint
  }
  {
    base-rate: u5,     ;; 5% base rate
    max-rate: u10,     ;; 10% max rate
    min-rate: u2,      ;; 2% min rate
    compound-frequency: u365  ;; Annual compounding
  }
)

 ;; Interest Calculation Function
(define-private (calculate-interest (user principal))
  (let 
    (
      (account 
        (unwrap! 
          (map-get? user-accounts {user: user}) 
          u0
        )
      )
      (base-rate (var-get base-interest-rate))
      (balance (get balance account))
      (time-since-deposit (- stacks-block-height (get last-deposit-time account)))
      
      ;; Dynamic interest calculation
      (interest 
        (/ 
          (* balance base-rate time-since-deposit) 
          u36500 ;; Annualized calculation
        )
      )
    )
    interest
  )
)

;; Access Control Mechanism
(define-map account-permissions
  {user: principal}
  {
    can-deposit: bool,
    can-withdraw: bool,
    can-transfer: bool
  }
)

;; Interest Calculation Function
(define-private (calculate-compound-interest 
                 (principal uint) 
                 (rate uint) 
                 (time uint))
  (let 
    ((compound-frequency (get compound-frequency (var-get interest-config))))
    (/ 
      (* principal 
         (pow (+ u1 (/ rate compound-frequency)) 
              (* time compound-frequency))) 
      u1
    )
  )
)


;; Advanced Deposit with Tier Management
(define-public (deposit-with-tier 
                (amount uint) 
                (tier uint))
  (let 
    ((user tx-sender)
     (tier-info (map-get? deposit-tiers {tier: tier}))
     (account (map-get? user-accounts {user: user}))
     (metadata (map-get? account-metadata {user: user})))
    
    (match tier-info
      info
      (if (>= amount (get min-amount info))
        ;; Deposit logic with tier bonus
        (ok true)
        (err ERR-MINIMUM-DEPOSIT))
      (err ERR-INVALID-CONFIGURATION)
    )
  )
)

;; Security Features
(define-public (toggle-account-lock (user principal))
  (let 
    ((current-metadata (unwrap! 
                         (map-get? account-metadata {user: user}) 
                         ERR-ACCOUNT-NOT-FOUND))
     (current-lock-status (get is-locked current-metadata)))
    
    (map-set account-metadata 
      {user: user}
      (merge current-metadata 
             {is-locked: (not current-lock-status)}))
    
    (ok (not current-lock-status))
  )
)

;; Utility Functions
(define-read-only (get-account-balance (user principal))
  (match (map-get? user-accounts {user: user})
    account (some (get balance account))
    none)
)

      

