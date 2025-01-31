;; title: bitcoin-savings-account
;; Error constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-MINIMUM-DEPOSIT (err u3))
(define-constant ERR-WITHDRAWAL-FAILED (err u4))

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
(define-data-var base-interest-rate uint u5) ; 5% base rate
(define-data-var max-interest-rate uint u10) ; 10% max rate
(define-data-var min-interest-rate uint u2)  ; 2% min rate

