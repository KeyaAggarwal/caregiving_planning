(define (domain jacket-dressing)
  (:requirements :typing :strips)

  (:types
    person
    jacket
    arm
    chair
  )

  (:predicates
    (JacketInHand ?p - person ?j - jacket)
    (JacketOriented ?j - jacket)
    (ArmInSleeveRight ?a - arm ?j - jacket)
    (ArmInSleeveLeft ?a - arm ?j - jacket)
    (JacketOverShoulderRight ?p - person ?j - jacket)
    (JacketOverShoulderLeft ?p - person ?j - jacket)
    (JacketDown ?j - jacket)
    (PersonSeated ?p - person ?c - chair)
    (JacketAdjusted ?j - jacket)
    (BothArmsIn ?p - person ?j - jacket)
    (JacketOn ?p - person ?j - jacket)
  )

  ;; 1. Orient jacket correctly before dressing
  (:action Orient_Jacket
    :parameters (?p - person ?j - jacket ?c - chair)
    :precondition (and (JacketInHand ?p ?j) (PersonSeated ?p ?c))
    :effect  (JacketOriented ?j)
  )

  ;; 2. Thread right arm through sleeve
  (:action JacketOnChair_Thread_RightArm
    :parameters (?p - person ?j - jacket ?a - arm ?c - chair)
    :precondition (and
      (JacketOriented ?j)
      (PersonSeated ?p ?c)
    )
    :effect  (ArmInSleeveRight ?a ?j)
  )

  ;; 3. Pull jacket over right shoulder
  (:action JacketOnChair_PullJacket_OverRightShoulder
    :parameters (?p - person ?j - jacket ?a - arm)
    :precondition (ArmInSleeveRight ?a ?j)
    :effect  (JacketOverShoulderRight ?p ?j)
  )

  ;; 4. Thread left arm
  (:action JacketOnChair_Thread_LeftArm
    :parameters (?p - person ?j - jacket ?a - arm)
    :precondition (and
      (JacketOverShoulderRight ?p ?j) (ArmInSleeveRight ?a ?j)
    )
    :effect  (ArmInSleeveLeft ?a ?j)
  )
    ;; 4. Pull jacket over left shoulder
   (:action JacketOnChair_PullJacket_OverLeftShoulder
    :parameters (?p - person ?j - jacket ?a - arm)
    :precondition (ArmInSleeveLeft ?a ?j)
    :effect  (JacketOverShoulderLeft ?p ?j)
  )

  ;; 5. Pull jacket down back or front
  (:action JacketOnChair_PullJacketDown
    :parameters (?p - person ?j - jacket ?a - arm)
    :precondition (and
      (ArmInSleeveLeft ?a ?j)
      (ArmInSleeveRight ?a ?j)
      (JacketOverShoulderLeft ?p ?j)
      (JacketOverShoulderRight ?p ?j)
    )
    :effect (JacketDown ?j)
  )

  ;; 6. Adjust jacket for final fit
  (:action JacketOnChair_Adjust
    :parameters (?p - person ?j - jacket)
    :precondition (JacketDown ?j)
    :effect (and
      (JacketAdjusted ?j)
      (JacketOn ?p ?j)
    )
  )
)
