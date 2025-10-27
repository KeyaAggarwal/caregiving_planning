(define (domain tshirt-bed-arm-agnostic)
  (:requirements :strips :typing)
  (:types
  tshirt jacket - clothing
  mannequin
  arm
  side
  person
  clothing
)


  (:predicates
    ;; States
    (TShirtInHand ?p - person ?t - tshirt)
    (BackUndressed ?m - mannequin ?t - tshirt)
    (TShirtLifted ?m - mannequin ?t - tshirt)
    (TShirtOverHead ?m - mannequin ?t - tshirt)
    (ArmUndressed ?m - mannequin ?t - tshirt ?a - arm)
    (RolledOnSide ?m - mannequin ?s - side)
    (RolledOnBack ?m - mannequin)
    (PulledOverHead ?m - mannequin ?t - tshirt)
    (HasArm ?m - mannequin ?a - arm)

    (TShirtOriented ?t - tshirt)
    (ArmThreaded ?m - mannequin ?a - arm ?t - tshirt)
    (TShirtOverShoulder ?m - mannequin ?a - arm ?t - tshirt)
    (OneShoulderDone ?m - mannequin ?t - tshirt)
    (HeadLowered ?m - mannequin)
    (TShirtAdjustedBack ?t - tshirt)
    (TShirtPulledDownFront ?m - mannequin ?t - tshirt)
    (TShirtPulledDownBack ?m - mannequin ?t - tshirt)
    (ArmSelected ?a - arm ?t - tshirt)
    (TShirtAdjusted ?t - tshirt)
  )

  ;; Actions
  
  (:action Undress_Back
    :parameters (?p - person ?m - mannequin ?t - tshirt ?s - side)
    :precondition (RolledOnSide ?m ?s)
    :effect (BackUndressed ?m ?t)
  )

  (:action Lift_TShirt
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (and (BackUndressed ?m ?t) (RolledOnBack ?m))
    :effect (TShirtLifted ?m ?t)
  )

  (:action TShirt_Over_Head
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (TShirtLifted ?m ?t)
    :effect (TShirtOverHead ?m ?t)
  )

  (:action Undress_Arm
    :parameters (?p - person ?m - mannequin ?t - tshirt ?a - arm)
    :precondition (TShirtOverHead ?m ?t)
    :effect (ArmUndressed ?m ?t ?a )
  )

  (:action Roll_On_Side
    :parameters (?p - person ?m - mannequin ?s - side)
    :precondition (and)
    :effect (RolledOnSide ?m ?s)
  )

  (:action Roll_On_Back
    :parameters (?p - person ?m - mannequin ?s - side)
    :precondition (RolledOnSide ?m ?s) ;; or right
    :effect (RolledOnBack ?m)
  )

  (:action Pull_TShirt_OverHead
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (and (TShirtOverHead ?m ?t) (RolledOnBack ?m))
    :effect (PulledOverHead ?m ?t)
  )



  ;; Orients the T-shirt
  (:action Orient_TShirt
    :parameters (?p - person ?t - tshirt)
    :precondition (TShirtInHand ?p ?t)
    :effect (TShirtOriented ?t)
  )

  ;; Randomly choose an arm (left or right) with equal probability
  (:action Choose_Arm
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (and
                    (TShirtOriented ?t)
                    (HasArm ?m right-arm)
                    (HasArm ?m left-arm))
    :effect (probabilistic
              0.5 (ArmSelected right-arm ?t)
              0.5 (ArmSelected left-arm ?t))
  )

  ;; Threading, dressing, adjusting actions (unchanged)
  (:action TShirtOnBed_Thread_Arm1
    :parameters (?p - person ?m - mannequin ?a - arm ?t - tshirt)
    :precondition (and
                    (TShirtOriented ?t)
                    (HasArm ?m ?a)
                    (ArmSelected ?a ?t)
                    (not (OneShoulderDone ?m ?t)))
    :effect (ArmThreaded ?m ?a ?t)
  )

  (:action TShirtOnBed_Dress_Shoulder1
    :parameters (?p - person ?m - mannequin ?a - arm ?t - tshirt)
    :precondition (ArmThreaded ?m ?a ?t)
    :effect (and
              (TShirtOverShoulder ?m ?a ?t)
              (OneShoulderDone ?m ?t))
  )

  (:action TShirtOnBed_Thread_Arm2
    :parameters (?p - person ?m - mannequin ?a - arm ?t - tshirt)
    :precondition (and
                    (TShirtOriented ?t)
                    (HasArm ?m ?a)
                    (OneShoulderDone ?m ?t)
                    (not (TShirtOverShoulder ?m ?a ?t)))
    :effect (ArmThreaded ?m ?a ?t)
  )

  (:action TShirtOnBed_Dress_Shoulder2
    :parameters (?p - person ?m - mannequin ?a - arm ?t - tshirt)
    :precondition (and
                    (ArmThreaded ?m ?a ?t)
                    (OneShoulderDone ?m ?t))
    :effect (TShirtOverShoulder ?m ?a ?t)
  )

  (:action TShirtOnBed_TShirt_Over_Head
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (and
                    (forall (?a - arm)
                      (TShirtOverShoulder ?m ?a ?t)))
    :effect (and
              (HeadLowered ?m)
              (TShirtOverHead ?m ?t))
  )

  (:action TShirtOnBed_Adjust_Back
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (TShirtOverHead ?m ?t)
    :effect (TShirtAdjustedBack ?t)
  )

  (:action TShirtOnBed_PullTShirtDown_F
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (TShirtAdjustedBack ?t)
    :effect (TShirtPulledDownFront ?m ?t)
  )

  (:action TShirtOnBed_PullTShirtDown_B
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (TShirtPulledDownFront ?m ?t)
    :effect (and
              (TShirtPulledDownBack ?m ?t)
              (RolledOnBack ?m))
  )

  (:action Final_Adjustments
    :parameters (?p - person ?m - mannequin ?t - tshirt)
    :precondition (and
                    (TShirtPulledDownBack ?m ?t)
                    (RolledOnBack ?m))
    :effect (TShirtAdjusted ?t)
  )

)
