# Survival / niching — C# ReferencePointManager + NondominatedSortingSurvival.
# Associate normalized individuals to Das–Dennis rays; select `target_size`
# from a combined pool (fill complete fronts, niche-preserve the last).
# v0: empty in → empty out. No Unsga3Algorithm.Run.

import Base
import ./individual.bend as Ind

type Assignment is Data:
  MkAssignment{
    reference_index: Nat
    perpendicular_distance: F32
    niche_count: Nat
  }

# One assignment per individual, same order. Empty population → Nil{}.
# TODO(v0): nearest-ray perpendicular distance; niche counts.
def associate(
  population: List<&2, Ind.Individual>,
  normalized: List<&2, List<&2, F32>>,
  directions: List<&2, List<&2, F32>>
) -> List<&2, Assignment>:
  match population:
    case Nil{}:
      Nil{}
    case h <> t:
      Nil{}

# Select `target_size` individuals. Empty combined → Nil{}.
# When |combined| ≤ target_size the C# surface returns a clone of combined.
# TODO(v0): NDS.sort → Normalization.normalize → associate → niching fill.
def select(
  combined: List<&2, Ind.Individual>,
  target_size: Nat,
  directions: List<&2, List<&2, F32>>
) -> List<&2, Ind.Individual>:
  match combined:
    case Nil{}:
      Nil{}
    case h <> t:
      Nil{}
