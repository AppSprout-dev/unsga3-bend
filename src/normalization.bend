# Normalization — C# Unsga3.Core.Normalization.
# NSGA-III adaptive hyperplane normalization (Deb & Jain), intended to
# track pymoo HyperplaneNormalization: persistent ideal, ASF extremes,
# intercept nadir. v0 stub: empty in → empty out.

import Base
import ./individual.bend as Ind

type State is Data:
  MkState{
    n_objectives: Nat
    ideal: List<&2, F32>
    nadir: List<&2, F32>
    intercepts: List<&2, F32>
  }

def new_state(n_objectives: Nat) -> State:
  MkState{n_objectives, Nil{}, Nil{}, Nil{}}

# Update persistent ideal / nadir and return normalized objective vectors
# in population order. Empty population → empty result (implemented).
# TODO(v0): persistent ideal, ND-front ASF extremes, intercept nadir.
def normalize(state: State, population: List<&2, Ind.Individual>) -> State & List<&2, List<&2, F32>>:
  match population:
    case Nil{}:
      (state, Nil{})
    case h <> t:
      (state, Nil{})

# Second component of normalize, for length laws (drops updated State).
def normalize_vecs.snd(pair: State & List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  (state, vecs) = pair
  vecs

def normalize_vecs(population: List<&2, Ind.Individual>) -> List<&2, List<&2, F32>>:
  normalize_vecs.snd(normalize(new_state(2n), population))
