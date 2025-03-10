;; Consciousness Qualification Assessment Contract
;; Evaluates and records consciousness qualifications for various entities

(define-data-var admin principal tx-sender)

;; Data structure for consciousness assessments
(define-map consciousness-assessments
  { entity-id: (string-ascii 50) }
  {
    entity-type: (string-ascii 30),
    self-awareness-score: uint,
    subjective-experience-score: uint,
    temporal-awareness-score: uint,
    assessment-timestamp: uint,
    assessor: principal,
    qualification-status: (string-ascii 20)
  }
)

;; Assessment history
(define-map assessment-history
  { history-id: uint }
  {
    entity-id: (string-ascii 50),
    previous-status: (string-ascii 20),
    new-status: (string-ascii 20),
    reason: (string-ascii 200),
    timestamp: uint
  }
)

;; Counter for history entries
(define-data-var next-history-id uint u1)

;; Register a new consciousness assessment
(define-public (register-assessment
  (entity-id (string-ascii 50))
  (entity-type (string-ascii 30))
  (self-awareness-score uint)
  (subjective-experience-score uint)
  (temporal-awareness-score uint))
  (begin
    (map-set consciousness-assessments
      { entity-id: entity-id }
      {
        entity-type: entity-type,
        self-awareness-score: self-awareness-score,
        subjective-experience-score: subjective-experience-score,
        temporal-awareness-score: temporal-awareness-score,
        assessment-timestamp: block-height,
        assessor: tx-sender,
        qualification-status: "pending"
      }
    )
    (ok true)
  )
)

;; Calculate consciousness qualification based on scores
(define-public (calculate-qualification (entity-id (string-ascii 50)))
  (let (
    (assessment (unwrap! (map-get? consciousness-assessments { entity-id: entity-id }) (err u1)))
    (self-score (get self-awareness-score assessment))
    (subjective-score (get subjective-experience-score assessment))
    (temporal-score (get temporal-awareness-score assessment))
    (total-score (+ (+ self-score subjective-score) temporal-score))
    (previous-status (get qualification-status assessment))
    (history-id (var-get next-history-id))
    (new-status (if (>= total-score u75) "qualified" "unqualified"))
    )

    ;; Record history
    (map-set assessment-history
      { history-id: history-id }
      {
        entity-id: entity-id,
        previous-status: previous-status,
        new-status: new-status,
        reason: "Score-based qualification calculation",
        timestamp: block-height
      }
    )

    ;; Update assessment
    (map-set consciousness-assessments
      { entity-id: entity-id }
      (merge assessment {
        qualification-status: new-status
      })
    )

    (var-set next-history-id (+ history-id u1))
    (ok new-status)
  )
)

;; Override qualification status (admin only)
(define-public (override-qualification (entity-id (string-ascii 50)) (new-status (string-ascii 20)) (reason (string-ascii 200)))
  (let (
    (assessment (unwrap! (map-get? consciousness-assessments { entity-id: entity-id }) (err u1)))
    (previous-status (get qualification-status assessment))
    (history-id (var-get next-history-id))
    )

    ;; Check if admin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Record history
    (map-set assessment-history
      { history-id: history-id }
      {
        entity-id: entity-id,
        previous-status: previous-status,
        new-status: new-status,
        reason: reason,
        timestamp: block-height
      }
    )

    ;; Update assessment
    (map-set consciousness-assessments
      { entity-id: entity-id }
      (merge assessment {
        qualification-status: new-status
      })
    )

    (var-set next-history-id (+ history-id u1))
    (ok true)
  )
)

;; Get assessment details
(define-read-only (get-assessment (entity-id (string-ascii 50)))
  (map-get? consciousness-assessments { entity-id: entity-id })
)

;; Get assessment history entry
(define-read-only (get-assessment-history (history-id uint))
  (map-get? assessment-history { history-id: history-id })
)

