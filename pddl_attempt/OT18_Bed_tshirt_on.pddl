(define (domain dressing)
  (:requirements :strips :typing)
  (:types person tshirt mannequin)

  ;; Objects and predicates
  (:predicates
    (TShirtInHand ?p ?t)
    (TShirtOriented ?t)
    (LeftArmThreaded ?m ?p ?t)
    (RightArmThreaded ?m ?p ?t)
    (TShirtOverLeftShoulder ?m ?t)
    (TShirtOverRightShoulder ?m ?t)
    (HeadLowered ?m)
    (TShirtOverHead)
    (TShirtAdjustedBack ?t)
    (TShirtPulledDownFront ?t)
    (TShirtPulledDownBack ?t)
    (RolledOnSide ?p ?side)
    (RolledOnBack ?p)
  )
;; Orient the T-shirt
  (:action Orient_TShirt
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtInHand ?p ?t)
    :effect (TShirtOriented ?t)
  )

  ;; Dress Left Arm
  (:action TShirtOnBed_Dress_LeftArm
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtOriented ?t)
    :effect (and
              (LeftArmThreaded ?p ?t)
              (TShirtOverLeftShoulder ?t))
  )

  ;; Dress Right Arm
  (:action TShirtOnBed_Dress_RightArm
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtOverLeftShoulder ?t)
    :effect (and
              (RightArmThreaded ?p ?t)
              (TShirtOverRightShoulder ?t))
  )

  ;; Pull T-shirt Over Head
  (:action TShirtOnBed_TShirt_Over_Head
    :parameters (?p - person ?t - tshirt)
    :precondition (and (TShirtOverLeftShoulder ?t) (TShirtOverRightShoulder ?t))
    :effect (and
              (HeadLowered ?p) (TShirtOverHead ?t))
  )

  ;; Adjust T-shirt on Back
  (:action TShirtOnBed_Adjust_Back
    :parameters (?p - person ?t - tshirt)
    :precondition (HeadLowered ?p)
    :effect (TShirtAdjustedBack ?t)
  )

  ;; Pull T-shirt Down Front
  (:action TShirtOnBed_PullTShirtDown_F
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtAdjustedBack ?t)
    :effect (TShirtPulledDownFront ?t)
  )

  ;; Pull T-shirt Down Back
  (:action TShirtOnBed_PullTShirtDown_B
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtPulledDownFront ?t)
    :effect (and
              (TShirtPulledDownBack ?t)
              (RolledOnSide ?p right)
              (RolledOnSide ?p left)
              (RolledOnBack ?p))
  )

  ;; Final Adjustments
  (:action Final_Adjustments
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtPulledDownBack ?t)
    :effect (TShirtAdjustedBack ?t)
  )
)