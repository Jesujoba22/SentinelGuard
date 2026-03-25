;; contract title
;; Real-Time DeFi Fraud Scoring AI - Extended Version

;; <add a description here>
;; This smart contract provides a decentralized, real-time fraud scoring mechanism 
;; for DeFi applications. It allows authorized AI oracles to feed off-chain fraud 
;; analysis data on-chain. If a user's fraud score exceeds a defined safety threshold, 
;; their account is automatically frozen to prevent malicious transactions, protecting 
;; the broader DeFi ecosystem from exploits, wash trading, or flash loan attacks.
;;
;; Extended Features:
;; - Dynamic fraud threshold adjustment by the contract owner
;; - Trusted user (VIP) whitelisting to prevent accidental freezing of protocol contracts
;; - Fraud score reduction for proven good behavior
;; - Detailed event emission (print statements) for off-chain indexing
;; - Advanced DeFi transaction simulation and heuristics
;; - Comprehensive on-chain user risk profile readouts

;; constants
;; The deployer of the contract is the owner
(define-constant contract-owner tx-sender)

;; Error codes for security and access control
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-score (err u101))
(define-constant err-account-frozen (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-trusted (err u104))
(define-constant err-not-trusted (err u105))

;; Configuration constants
(define-constant max-score u100)

;; data maps and vars

;; Dynamic configuration variable for the fraud threshold (defaults to 80)
(define-data-var fraud-threshold uint u80)

;; Stores the current fraud score (0-100) for each principal
(define-map user-scores principal uint)

;; Registry of authorized AI oracles that can report scores
(define-map ai-oracles principal bool)

;; Tracks the number of reports submitted by each oracle for auditing
(define-map oracle-report-counts principal uint)

;; Registry of frozen accounts that breached the fraud threshold
(define-map frozen-accounts principal bool)

;; Registry of trusted protocol addresses or VIP users immune to automatic freezing
(define-map trusted-users principal bool)

;; private functions

;; @desc Helper to check if a caller is an authorized AI oracle
(define-private (is-oracle (caller principal))
    (default-to false (map-get? ai-oracles caller))
)

;; @desc Helper to get the current score of a user safely
(define-private (get-user-score (user principal))
    (default-to u0 (map-get? user-scores user))
)

;; @desc Helper to check if a user is whitelisted/trusted
(define-private (is-trusted (user principal))
    (default-to false (map-get? trusted-users user))
)

;; @desc Internal helper to increment oracle report statistics
(define-private (increment-oracle-count (oracle principal))
    (let 
        (
            (current-count (default-to u0 (map-get? oracle-report-counts oracle)))
        )
        (map-set oracle-report-counts oracle (+ current-count u1))
    )
)

;; public functions

;; =========================================================
;; Administrative Functions
;; =========================================================

;; @desc Authorizes a new AI oracle to report fraud scores
;; @param oracle; The principal address of the oracle
;; @restriction Only contract owner
(define-public (add-oracle (oracle principal))
    (begin
        ;; Security check: only the owner can add oracles
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (map-set ai-oracles oracle true)
        (print {event: "oracle-added", oracle: oracle})
        (ok true)
    )
)

;; @desc Removes an AI oracle's authorization
;; @param oracle; The principal address of the oracle
;; @restriction Only contract owner
(define-public (remove-oracle (oracle principal))
    (begin
        ;; Security check: only the owner can remove oracles
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (map-set ai-oracles oracle false)
        (print {event: "oracle-removed", oracle: oracle})
        (ok true)
    )
)

;; @desc Updates the global fraud threshold dynamically
;; @param new-threshold; The new threshold limit (0-100)
;; @restriction Only contract owner
(define-public (update-fraud-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (<= new-threshold max-score) err-invalid-input)
        (var-set fraud-threshold new-threshold)
        (print {event: "threshold-updated", new-threshold: new-threshold})
        (ok true)
    )
)

;; @desc Adds a user or smart contract to the trusted whitelist
;; @param user; The principal to whitelist
;; @restriction Only contract owner
(define-public (add-trusted-user (user principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (not (is-trusted user)) err-already-trusted)
        (map-set trusted-users user true)
        (print {event: "trusted-user-added", user: user})
        (ok true)
    )
)

;; @desc Removes a user from the trusted whitelist
;; @param user; The principal to remove
;; @restriction Only contract owner
(define-public (remove-trusted-user (user principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (is-trusted user) err-not-trusted)
        (map-delete trusted-users user)
        (print {event: "trusted-user-removed", user: user})
        (ok true)
    )
)

;; =========================================================
;; Core Scoring & Enforcement Functions
;; =========================================================

;; @desc Directly updates a user's fraud score from an AI oracle
;; @param user; The user being scored
;; @param score; The new fraud score (0-100)
;; @restriction Only authorized oracles
(define-public (report-fraud-score (user principal) (score uint))
    (begin
        ;; Security check: caller must be an authorized oracle
        (asserts! (is-oracle tx-sender) err-unauthorized)
        ;; Validate the score is within bounds
        (asserts! (<= score max-score) err-invalid-score)
        
        ;; Increment oracle reporting stats
        (increment-oracle-count tx-sender)
        
        ;; Update the score
        (map-set user-scores user score)
        (print {event: "fraud-score-reported", user: user, score: score, oracle: tx-sender})
        
        ;; If the score breaches the threshold, and they are not trusted, freeze the account
        (if (and (>= score (var-get fraud-threshold)) (not (is-trusted user)))
            (begin
                (map-set frozen-accounts user true)
                (print {event: "account-frozen", user: user, reason: "threshold-breach"})
                true
            )
            false ;; do nothing
        )
        
        (ok true)
    )
)

;; @desc Reduces a user's fraud score based on verified good behavior
;; @param user; The user whose score is being reduced
;; @param reduction-amount; Points to deduct from the fraud score
;; @restriction Only authorized oracles
(define-public (reduce-fraud-score (user principal) (reduction-amount uint))
    (let 
        (
            (current-score (get-user-score user))
            ;; Ensure score does not drop below 0
            (new-score (if (>= current-score reduction-amount)
                           (- current-score reduction-amount)
                           u0))
        )
        ;; Security check: caller must be an authorized oracle
        (asserts! (is-oracle tx-sender) err-unauthorized)
        
        (increment-oracle-count tx-sender)
        (map-set user-scores user new-score)
        (print {event: "fraud-score-reduced", user: user, old-score: current-score, new-score: new-score})
        
        (ok new-score)
    )
)

;; @desc Unfreezes an account and resets their score (Manual override)
;; @param user; The user to defrost
;; @restriction Only contract owner
(define-public (defrost-account (user principal))
    (begin
        ;; Security check: only owner can manually override and defrost
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        
        (map-delete frozen-accounts user)
        (map-set user-scores user u0)
        (print {event: "account-defrosted", user: user})
        (ok true)
    )
)

;; =========================================================
;; Feature: Complex DeFi Transaction Processing & Scoring
;; =========================================================
;; This function simulates processing a DeFi transaction while
;; concurrently updating the user's fraud score based on
;; transaction heuristics (amount, type, and current status).
;; This allows the AI scoring system to proactively block
;; suspicious transactions in real-time before they execute.
;; It also considers trusted whitelists to bypass heuristics.
(define-public (process-defi-tx-with-scoring (user principal) (amount uint) (tx-type uint))
    (let 
        (
            ;; Retrieve current fraud score, defaulting to 0 if new
            (current-score (get-user-score user))
            
            ;; Check if the user is already frozen
            (is-frozen (default-to false (map-get? frozen-accounts user)))
            
            ;; Check if the user is on the trusted whitelist
            (user-trusted (is-trusted user))
            
            ;; Heuristic 1: Large amounts add significant risk
            ;; > 1,000,000 tokens adds 15 points, > 100,000 adds 5 points
            (amount-penalty (if (> amount u1000000) u15 (if (> amount u100000) u5 u0)))
            
            ;; Heuristic 2: Certain tx-types carry higher inherent risk
            ;; Type 3 (e.g., flash loans) = +20 risk, Type 2 (e.g., swaps) = +10 risk
            (type-penalty (if (is-eq tx-type u3) u20 (if (is-eq tx-type u2) u10 u0)))
            
            ;; Calculate intermediate new score
            (raw-new-score (+ current-score (+ amount-penalty type-penalty)))
            
            ;; Cap the score at the maximum allowed score (100)
            (final-new-score (if (> raw-new-score max-score) max-score raw-new-score))
            
            ;; Fetch current dynamic threshold
            (current-threshold (var-get fraud-threshold))
        )
        ;; Security check: ensure the caller is an authorized oracle or the contract owner
        (asserts! (or (is-eq tx-sender contract-owner) (is-oracle tx-sender)) err-unauthorized)
        
        ;; Security check: explicitly block transaction if account is already frozen
        (asserts! (not is-frozen) err-account-frozen)
        
        ;; If user is trusted, we bypass the penalty application but allow the tx to proceed
        (if user-trusted
            (begin
                (print {event: "trusted-tx-processed", user: user, amount: amount, tx-type: tx-type})
                (ok current-score)
            )
            (begin
                ;; Update the user's fraud score in the data map to reflect this new action
                (map-set user-scores user final-new-score)
                (print {event: "heuristic-score-update", user: user, new-score: final-new-score})
                
                ;; Check if the newly calculated score breaches the dynamic fraud threshold
                (if (>= final-new-score current-threshold)
                    (begin
                        ;; Freeze the account immediately to prevent any further DeFi interactions
                        (map-set frozen-accounts user true)
                        (print {event: "account-frozen-during-tx", user: user, tx-type: tx-type})
                        ;; Return a specific frozen error to the integrating protocol
                        err-account-frozen
                    )
                    (begin
                        ;; Transaction is deemed safe, proceed with simulated execution
                        ;; In a real-world integration, the actual DeFi asset transfer or swap 
                        ;; logic would be executed securely here.
                        (print {event: "safe-tx-processed", user: user, amount: amount, tx-type: tx-type})
                        (ok final-new-score)
                    )
                )
            )
        )
    )
)

;; =========================================================
;; Feature: Comprehensive User Risk Profile Readout
;; =========================================================
;; A robust 25+ line read-only function that acts as a unified
;; endpoint for dApps and off-chain indexers to instantly fetch
;; the full risk profile and operational status of a single user
;; without having to make multiple on-chain RPC calls.
(define-read-only (get-user-full-status (user principal))
    (let
        (
            (score (get-user-score user))
            (is-frozen (default-to false (map-get? frozen-accounts user)))
            (trusted (is-trusted user))
            (threshold (var-get fraud-threshold))
            
            ;; Calculate safety margin (distance to threshold) safely
            ;; If the score is already past the threshold, margin is 0
            (safety-margin (if (>= score threshold) 
                               u0 
                               (- threshold score)))
                               
            ;; Determine human-readable risk level string categorization
            ;; - CRITICAL: Account is completely frozen
            ;; - HIGH: Nearing threshold (score >= 61)
            ;; - MEDIUM: Moderate risk (score 31 - 60)
            ;; - LOW: Good standing (score 0 - 30)
            (risk-level (if is-frozen
                            "CRITICAL"
                            (if (>= score u61)
                                "HIGH"
                                (if (>= score u31)
                                    "MEDIUM"
                                    "LOW"))))
                                    
            ;; Quick boolean helper to indicate if txs should be routed
            (can-transact (and (not is-frozen) (or trusted (< score threshold))))
        )
        ;; Returns a structured tuple representing the user's complete standing
        {
            user-address: user,
            current-fraud-score: score,
            is-account-frozen: is-frozen,
            is-trusted-whitelist: trusted,
            points-to-freeze: safety-margin,
            risk-assessment-level: risk-level,
            current-global-threshold: threshold,
            is-eligible-for-tx: can-transact
        }
    )
)


