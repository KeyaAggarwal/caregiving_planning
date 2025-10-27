(define (domain tshirt-off-bed-arm-agnostic)
  (:requirements :strips :typing)
  (:types person tshirt mannequin arm side)

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
)
