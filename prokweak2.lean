import Mathlib.Probability.IdentDistrib
import Mathlib.MeasureTheory.Integral.IntervalIntegral -- Assuming relevant modules are available
import Mathlib.MeasureTheory.Measure.LevyProkhorovMetric
import Mathlib.MeasureTheory.Measure.ProbabilityMeasure
import Mathlib.Topology.Defs.Basic
import Mathlib.Topology.MetricSpace.Defs
--set_option maxHeartbeats 400000
--set_option diagnostics true

open Topology Metric Filter Set ENNReal NNReal ProbabilityMeasure TopologicalSpace

namespace MeasureTheory

open scoped Topology ENNReal NNReal BoundedContinuousFunction


variable {Ω : Type*} [MeasurableSpace Ω] [PseudoMetricSpace Ω] -- consider changing this to EMetric later
[OpensMeasurableSpace Ω] [SeparableSpace Ω] --[∀ i, μ i : Measure Ω] {P : MeasurableSpace Ω}
variable {μ : ℕ → Set Ω → ℝ}




noncomputable section

--def compactsetofmeasures := {X : Set (ProbabilityMeasure Ω) // IsCompact X}

variable (S : Set (ProbabilityMeasure Ω)) --(S : Set (ProbabilityMeasure Ω)) --

abbrev P := LevyProkhorov.equiv (ProbabilityMeasure Ω)

abbrev T := P⁻¹' S

-- theorem tendsto_iff_forall_integral_tendsto_prok (γ : Type*) (F : Filter γ) (B : Set Ω) (O : IsOpen B)
--     {S : Set (ProbabilityMeasure Ω)} {μs : γ → (ProbabilityMeasure Ω)} {μ : (ProbabilityMeasure Ω)} (h : IsCompact (closure S)) :
--     Tendsto (fun k => (μs k)) F (𝓝 μ) → Tendsto (fun k =>  (μs k) B) F (𝓝 (μ B)) := by
--     intro h
--     refine Tendsto.apply_nhds ?h B
--     refine tendsto_pi_nhds.mpr ?h.a
--     intro x
--     sorry

    -- refine ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto ?goalone ?goaltwo
    -- · exact h
    -- · frontier B



-- lemma tendsto_in_Prok_eq_tendsto_in_weak {μ : ℕ → (ProbabilityMeasure Ω)} {μlim : ProbabilityMeasure Ω} (h : Tendsto μ atTop (𝓝 μlim)) :
--   Tendsto (fun n => P (μ n)) atTop (𝓝 μlim) := by sorry

lemma my_thing {l : Filter α} {f : α → NNReal} [IsMeasure f] [IsProbabilityMeasure f]:
    liminf (fun x ↦ (f x : ENNReal)) l = liminf f l := by
  apply?
  sorry

-- lemma my_thing2 {ν : ProbabilityMeasure Ω} {s : Set Ω} :
--     @DFunLike.coe (Measure Ω) (Set Ω) (fun x => ℝ≥0∞) _ ν s = ν s := by
--   exact Eq.symm (ProbabilityMeasure.ennreal_coeFn_eq_coeFn_toMeasure ν s)

lemma claim5point2 (U : ℕ → Set Ω) (O : ∀ i, IsOpen (U i)) --(T : Set (LevyProkhorov (ProbabilityMeasure Ω)))
    (hcomp: IsCompact (closure S)) (ε : ℝ≥0) (Cov : univ = ⋃ i, U i):
    ∃ (k : ℕ), ∀ μ ∈ S, μ (⋃ (i ≤ k), U i) > 1 - ε := by
  by_contra! nh
  choose μ hμ hμε using nh

  --exact hcomp.mem_of_is_closed (IsClosed.closure hcomp.is_closed)
  obtain ⟨μnew, hμtwo, sub, tub, bub⟩ := hcomp.isSeqCompact (fun n =>  subset_closure <| hμ n)
  have thing n := calc
    μnew (⋃ (i ≤ n), U i)
    _ ≤ liminf (fun k => μ (sub k) (⋃ (i ≤ n), U i)) atTop := by
      have hopen : IsOpen (⋃ i, ⋃ (_ : i ≤ n), U i) := by
        exact isOpen_biUnion fun i a => O i

      --This is the key lemma
      have := ProbabilityMeasure.le_liminf_measure_open_of_tendsto bub hopen
      simp only [Function.comp_apply] at this
      simp only [← ProbabilityMeasure.ennreal_coeFn_eq_coeFn_toMeasure] at this
      rw [my_thing] at this
      norm_cast at this


      -- Everythin below is a mess (probably wrong)
      --rw [Tendsto.liminf_eq]
      --exact tendsto_iff_forall_integral_tendsto_prok ℕ atTop (⋃ i, ⋃ (_ : i ≤ n), U i) bub
      --apply tendsto_measure_iUnion_atTop
      --apply MeasureTheory.limsup_measure_closed_le_iff_liminf_measure_open_ge,  MeasureTheory.FiniteMeasure.limsup_measure_closed_le_of_tendsto at bub
      --homeomorph_probabilityMeasure_levyProkhorov
    _ ≤ liminf (fun k => μ (sub k) (⋃ (i ≤ k), U i)) atTop := by
      apply Filter.liminf_le_liminf
      · simp
        use n + 1
        intro b hypo
        have hsub : (⋃ i, ⋃ (_ : i ≤ n), U i) ⊆ (⋃ i, ⋃ (_ : i ≤ b), U i) := by
          refine iUnion₂_subset_iff.mpr ?_
          intro t h
          refine subset_biUnion_of_mem ?_
          simp
          apply h.trans
          linarith
        exact ProbabilityMeasure.apply_mono  (μ (sub b)) hsub
      · simp [autoParam]
        use 0
        simp
      · simp [autoParam]
        use 1
        simp
        intro a d hyp
        specialize hyp d (by simp)
        apply hyp.trans
        simp_all only [ProbabilityMeasure.apply_le_one]
      -- rw [Tendsto.liminf_eq]--, Tendsto.liminf_eq]
    _ ≤ 1 - ε := by
      --apply Filter.liminf_le_liminf

      sorry

  have cdiction : Tendsto (fun n => μnew (⋃ i ≤ n, U i)) atTop (𝓝 1) := by sorry
    --(∀ n, P μnew (⋃ (i ≤ n), U i)) ≤ liminf (fun k => P (μ (sub k)) (⋃ (i ≤ n), U i)) atTop := by exact P.liminf_le_liminf hμ
      -- have conv :
  --simp at nh --gt_iff_lt, not_exists, not_forall, Classical.not_imp, not_lt] at nh
  --have h : ∃ μ ∈ (closure S), ∃ (m : ℕ → LevyProkhorov (ProbabilityMeasure Ω)), (∀ i : ℕ, m i ∈ closure S) ∧ Tendsto m atTop (𝓝 μ) := by
  --exact IsCompact.isSeqCompact c
  sorry





-- lemma fivepoint3 {MeasurableSpace X} (MetricSpace X)  (h : IsCompact X) : (inferInstance : TopologicalSpace (LevyProkhorov (ProbabilityMeasure X))) := by
--   sorry


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
