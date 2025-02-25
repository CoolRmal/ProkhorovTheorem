import Mathlib.Probability.IdentDistrib
import Mathlib.MeasureTheory.Integral.IntervalIntegral -- Assuming relevant modules are available
import Mathlib.MeasureTheory.Measure.LevyProkhorovMetric
import Mathlib.Topology.Defs.Basic
import Mathlib.Topology.MetricSpace.Defs
--set_option diagnostics true

open Topology Metric Filter Set ENNReal NNReal

namespace MeasureTheory

open scoped Topology ENNReal NNReal BoundedContinuousFunction


variable {Ω : Type} [MeasurableSpace Ω] [PseudoMetricSpace Ω] -- consider changing this to EMetric later
[OpensMeasurableSpace Ω] --[h : Fact (OpensMeasurableSpace Ω)]--[SeparableSpace Ω]--[∀ i, μ i : Measure Ω] {P : MeasurableSpace Ω}
variable {μ : ℕ → Set Ω → ℝ}




noncomputable section

--def compactsetofmeasures := {X : Set (ProbabilityMeasure Ω) // IsCompact X}




-- Levy Prok α is syn
-- α is Foo, ofSyn is .equiv


variable (S : Set (LevyProkhorov (ProbabilityMeasure Ω)))
   
abbrev P := LevyProkhorov.equiv (ProbabilityMeasure Ω) 

--abbrev T := P⁻¹' S 




variable [OpensMeasurableSpace Ω] in

lemma claim5point2 (U : ℕ → Set Ω) (O : ∀ i, IsOpen (U i)) --(T : Set (LevyProkhorov (ProbabilityMeasure Ω)))
    (hcomp: IsCompact (closure S)) (ε : ℝ≥0) (Cov : univ = ⋃ i, U i):
    ∃ (k : ℕ), ∀ μ ∈ S,  P μ (⋃ (i ≤ k), U i) > 1 - ε := by
  by_contra! nh
  choose μ hμ hμε using nh

  --exact hcomp.mem_of_is_closed (IsClosed.closure hcomp.is_closed)
  obtain ⟨μnew, hμ, sub, tub, bub⟩ := hcomp.isSeqCompact (fun n =>  subset_closure <| hμ n)
  have thing n := calc
    P μnew (⋃ (i ≤ n), U i)
    _ = liminf (fun k => P (μ (sub k)) (⋃ (i ≤ n), U i)) atTop := by 
      rw [Tendsto.liminf_eq]
      refine NNReal.tendsto_coe.mp ?_
      apply bub --apply iInf_le_liminf
    _ ≤ liminf (fun k => P (μ (sub k)) (⋃ (i ≤ k), U i)) atTop := by sorry
    _ ≤ 1 - ε := sorry

  have cdiction : Tendsto (fun n => P μnew (⋃ i ≤ n, U i)) atTop (𝓝 1) := by sorry
    --(∀ n, P μnew (⋃ (i ≤ n), U i)) ≤ liminf (fun k => P (μ (sub k)) (⋃ (i ≤ n), U i)) atTop := by exact P.liminf_le_liminf hμ
      -- have conv :
  --simp at nh --gt_iff_lt, not_exists, not_forall, Classical.not_imp, not_lt] at nh
  --have h : ∃ μ ∈ (closure S), ∃ (m : ℕ → LevyProkhorov (ProbabilityMeasure Ω)), (∀ i : ℕ, m i ∈ closure S) ∧ Tendsto m atTop (𝓝 μ) := by
  --exact IsCompact.isSeqCompact c
  




lemma fivepoint3 (MetricSpace X) (h : IsCompact X) (A : ProbabilityMeasure X) (B := LevyProkhorov.equiv (ProbabilityMeasure X)) : IsCompact B := by
  sorry


-- Definition taken from Rémy's PR number #21955
def IsTightFamily (S : Set (Measure Ω)) : Prop :=
  ∀ ε, 0 < ε → ∃ (K_ε : Set Ω), ∀ μ ∈ S, μ K_εᶜ < ε ∧ IsCompact K_ε


def IsRelativelyCompact (S : Set (Measure Ω)) [PseudoMetricSpace (Measure Ω)] : Prop :=
  IsCompact (closure S)

theorem Prokhorov (G : Set (Measure Ω)) [PseudoMetricSpace (Measure Ω)]:
   (IsTightFamily G) ↔ (IsRelativelyCompact G) := by
   sorry

end section
-- Change Omega to X