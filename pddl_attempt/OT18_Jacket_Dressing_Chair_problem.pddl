(define (problem jacket-dressing-problem)
  (:domain jacket-dressing)

  (:objects
    person1 - person
    chair1 - chair
    jacket1 - jacket
    right_arm left_arm - arm
  )

  (:init
    ;; Initial state
    (PersonSeated person1 chair1)
    (JacketInHand person1 jacket1)
    ;; Arms are not yet in sleeves
    ;; Jacket not yet oriented or worn
  )

  (:goal
    (and
      (JacketOn person1 jacket1)
      (JacketAdjusted jacket1)
    )
  )
)