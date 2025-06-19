;; TimeWarden - Timelock Token Contract
;; A smart contract for time-locked token deposits on Stacks

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-UNLOCKED (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INVALID-UNLOCK-TIME (err u106))

;; Data Variables
(define-data-var contract-name (string-ascii 32) "TimeWarden")
(define-data-var total-locked uint u0)
(define-data-var lock-counter uint u0)

;; Data Maps
(define-map timelock-vaults
  { vault-id: uint }
  {
    owner: principal,
    amount: uint,
    lock-time: uint,
    unlock-time: uint,
    is-active: bool
  }
)

(define-map user-vaults
  { user: principal }
  { vault-ids: (list 100 uint) }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (get-current-time)
  block-height
)

;; Public Functions

;; Create a new timelock vault
(define-public (create-vault (amount uint) (lock-duration uint))
  (let (
    (vault-id (+ (var-get lock-counter) u1))
    (current-time (get-current-time))
    (unlock-time (+ current-time lock-duration))
    (user-vault-list (default-to { vault-ids: (list) } (map-get? user-vaults { user: tx-sender })))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> lock-duration u0) ERR-INVALID-UNLOCK-TIME)
    (asserts! (>= (stx-get-balance tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Create vault record
    (map-set timelock-vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        amount: amount,
        lock-time: current-time,
        unlock-time: unlock-time,
        is-active: true
      }
    )
    
    ;; Update user's vault list
    (map-set user-vaults
      { user: tx-sender }
      { vault-ids: (unwrap! (as-max-len? (append (get vault-ids user-vault-list) vault-id) u100) ERR-NOT-FOUND) }
    )
    
    ;; Update counters
    (var-set lock-counter vault-id)
    (var-set total-locked (+ (var-get total-locked) amount))
    
    (ok vault-id)
  )
)

;; Withdraw from an unlocked vault
(define-public (withdraw-from-vault (vault-id uint))
  (let (
    (vault-data (unwrap! (map-get? timelock-vaults { vault-id: vault-id }) ERR-NOT-FOUND))
    (current-time (get-current-time))
  )
    (asserts! (is-eq (get owner vault-data) tx-sender) ERR-OWNER-ONLY)
    (asserts! (get is-active vault-data) ERR-NOT-FOUND)
    (asserts! (>= current-time (get unlock-time vault-data)) ERR-NOT-UNLOCKED)
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? (get amount vault-data) tx-sender (get owner vault-data))))
    
    ;; Deactivate vault
    (map-set timelock-vaults
      { vault-id: vault-id }
      (merge vault-data { is-active: false })
    )
    
    ;; Update total locked
    (var-set total-locked (- (var-get total-locked) (get amount vault-data)))
    
    (ok (get amount vault-data))
  )
)

;; Extend lock duration for an existing vault
(define-public (extend-lock (vault-id uint) (additional-duration uint))
  (let (
    (vault-data (unwrap! (map-get? timelock-vaults { vault-id: vault-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-eq (get owner vault-data) tx-sender) ERR-OWNER-ONLY)
    (asserts! (get is-active vault-data) ERR-NOT-FOUND)
    (asserts! (> additional-duration u0) ERR-INVALID-UNLOCK-TIME)
    
    ;; Update unlock time
    (map-set timelock-vaults
      { vault-id: vault-id }
      (merge vault-data { unlock-time: (+ (get unlock-time vault-data) additional-duration) })
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get vault information
(define-read-only (get-vault-info (vault-id uint))
  (map-get? timelock-vaults { vault-id: vault-id })
)

;; Get user's vault IDs
(define-read-only (get-user-vaults (user principal))
  (map-get? user-vaults { user: user })
)

;; Check if vault is unlocked
(define-read-only (is-vault-unlocked (vault-id uint))
  (match (map-get? timelock-vaults { vault-id: vault-id })
    vault-data (>= (get-current-time) (get unlock-time vault-data))
    false
  )
)

;; Get time remaining until unlock
(define-read-only (get-time-until-unlock (vault-id uint))
  (match (map-get? timelock-vaults { vault-id: vault-id })
    vault-data 
      (let ((current-time (get-current-time)))
        (if (>= current-time (get unlock-time vault-data))
          u0
          (- (get unlock-time vault-data) current-time)
        )
      )
    u0
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-locked: (var-get total-locked),
    total-vaults: (var-get lock-counter),
    contract-name: (var-get contract-name)
  }
)

;; Get current block height (for time reference)
(define-read-only (get-current-block-height)
  block-height
)

;; Emergency functions (owner only)

;; Update contract name (owner only)
(define-public (set-contract-name (new-name (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set contract-name new-name)
    (ok true)
  )
)