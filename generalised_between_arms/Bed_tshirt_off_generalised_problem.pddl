(define (problem tshirt-off-bed-arm-agnostic-problem)
  (:domain tshirt-off-bed-arm-agnostic)

  (:objects
    person1 - person
    mannequin1 - mannequin
    tshirt1 - tshirt
    left_arm right_arm - arm
    left_side right_side - side
  )

  (:init
    ;; Initial state
    (RolledOnBack mannequin1)
    (HasArm mannequin1 left_arm)
    (HasArm mannequin1 right_arm)
    (TShirtInHand person1 tshirt1)
  )

  (:goal
    (and
        (ArmUndressed mannequin1 tshirt1 left_arm)
        (ArmUndressed mannequin1 tshirt1 right_arm)
    )
  )
)
