(define (problem tshirt-dressing-problem)
  (:domain tshirt-dressing)

  (:objects
    person1 - person
    mannequin1 - mannequin
    tshirt1 - tshirt
    left_arm right_arm - arm
    ;;left_side right_side - side
    )

  (:init
    ;; Initial state

    (TShirtInHand person1 tshirt1)
    (HasArm mannequin1 left_arm)
    (HasArm mannequin1 right_arm)
    
  )

  (:goal
    (and
        (TShirtOverHead mannequin1 tshirt1)
        (TShirtAdjustedBack tshirt1)
    )
  )
)