/- This code is not mine, and comes from https://github.com/janemms/BanachAlaoglu-/

/-
Copyright (c) 2025 Janette Setälä, Yaël Dillies, Kalle Kytölä. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Janette Setälä, Yaël Dillies, Kalle Kytölä
-/
import Mathlib--.Analysis.NormedSpace.FunctionSeries
--import Mathlib.Analysis.SpecificLimits.Basic

/-!
# Embedding a countably separated space inside a space of sequences

This file proves that a topological `X` separated by countably many continuous functions `X → Y n`
where the `Y n` are metric spaces, then `X` can be embedded inside the product `∀ n, Y n`.
-/

-- TODO: Tag in mathlib
attribute [simp] abs_mul abs_inv ENNReal.ofReal_mul ENNReal.ofReal_inv_of_pos ENNReal.ofReal_pow

namespace ENNReal

lemma ofReal_mono : Monotone ENNReal.ofReal := fun _ _ ↦ ENNReal.ofReal_le_ofReal

@[simp] lemma ofReal_min (x y : ℝ) : ENNReal.ofReal (min x y) = min (.ofReal x) (.ofReal y) :=
  ofReal_mono.map_min

@[simp] lemma ofReal_dist {X : Type*} [PseudoMetricSpace X] (x y : X) :
    .ofReal (dist x y) = edist x y := by simp [edist_dist]

@[simp] lemma min_eq_zero {x y : ℝ≥0∞} : min x y = 0 ↔ x = 0 ∨ y = 0 := min_eq_bot

end ENNReal

namespace PseudoMetricSpace
variable {X : Type*}

/-- Build a new pseudometric space from an old one where the distance uniform structure is provably
(but typically non-definitionaly) equal to some given distance structure. -/
-- See note [forgetful inheritance]
-- See note [reducible non-instances]
abbrev replaceDist (m : PseudoMetricSpace X) (d : X → X → ℝ) (hd : d = dist) :
    PseudoMetricSpace X where
  dist := d
  dist_self := by simp [hd]
  dist_comm := by simp [hd, dist_comm]
  dist_triangle := by simp [hd, dist_triangle]
  edist_dist := by simp [hd, edist_dist]
  uniformity_dist := by simp [hd, uniformity_dist]
  cobounded_sets := by simp [hd, cobounded_sets]
  __ := m

lemma replaceDist_eq (m : PseudoMetricSpace X) (d : X → X → ℝ) (hd : d = dist) :
    m.replaceDist d hd = m := by ext : 2; exact hd

end PseudoMetricSpace

namespace PseudoEMetricSpace

/-- One gets a pseudometric space from an emetric space if the edistance
is everywhere finite, by pushing the edistance to reals. We set it up so that the edist and the
uniformity are defeq in the pseudometric space and the pseudoemetric space. In this definition, the
distance is given separately, to be able to prescribe some expression which is not defeq to the
push-forward of the edistance to reals. See note [reducible non-instances]. -/
abbrev toPseudoMetricSpaceOfDist' {X : Type*} [e : PseudoEMetricSpace X] (dist : X → X → ℝ)
    (dist_nonneg : ∀ x y, 0 ≤ dist x y)
    (h : ∀ x y, edist x y = .ofReal (dist x y)) : PseudoMetricSpace X where
  dist := dist
  dist_self x := by simpa [h, (dist_nonneg _ _).le_iff_eq, -edist_self] using edist_self x
  dist_comm x y := by simpa [h, dist_nonneg] using edist_comm x y
  dist_triangle x y z := by
    simpa [h, dist_nonneg, add_nonneg, ← ENNReal.ofReal_add] using edist_triangle x y z
  edist := edist
  edist_dist _ _ := by simp only [h, ENNReal.ofReal_toReal (edist_ne_top _ _)]
  toUniformSpace := toUniformSpace
  uniformity_dist := e.uniformity_edist.trans <| by
    simpa [h, dist_nonneg, ENNReal.coe_toNNReal_eq_toReal]
      using (Metric.uniformity_edist_aux fun x y : X => (edist x y).toNNReal).symm

end PseudoEMetricSpace

open Function Topology

variable {X : Type*} {Y : ℕ → Type*} {f : ∀ n, X → Y n}

namespace Metric

include f in
variable (X Y f) in
/-- Given a type `X` and a sequence `Y` of metric spaces and a sequence `f : : ∀ n, X → Y n` of
separating functions, `PiNatEmbed X Y f` is a type synonym for `X` seen as a subset of `∀ n, Y n`.
-/
structure PiNatEmbed (X : Type*) (Y : ℕ → Type*) (f : ∀ n, X → Y n) where
  /-- The map from `X` to the subset of `∀ n, Y n`. -/
  toPiNat ::
  /-- The map from the subset of `∀ n, Y n` to `X`. -/
  ofPiNat : X

namespace PiNatEmbed

@[ext] lemma ext {x y : PiNatEmbed X Y f} (hxy : x.ofPiNat = y.ofPiNat) : x = y := by
  cases x; congr!

variable (X Y f) in
/-- Equivalence between `X` and its embedding into `∀ n, Y n`. -/
@[simps]
def toPiNatEquiv : X ≃ PiNatEmbed X Y f where
  toFun := toPiNat
  invFun := ofPiNat
  left_inv _ := rfl
  right_inv _ := rfl

section PseudoEMetricSpace
variable [∀ n, PseudoEMetricSpace (Y n)]

private noncomputable abbrev truncEDist (x y : PiNatEmbed X Y f) (n : ℕ) :=
  (1 / 2) ^ n * min (edist (f n x.ofPiNat) (f n y.ofPiNat)) 1

private lemma truncEDist_le_geometric {x y : PiNatEmbed X Y f} (n : ℕ) :
    truncEDist x y n ≤ (1 / 2) ^ n := by
  transitivity (1 / 2) ^ n * 1
  · unfold truncEDist
    gcongr
    exact min_le_right ..
  · simp

noncomputable instance : PseudoEMetricSpace (PiNatEmbed X Y f) where
  edist x y := ∑' n, truncEDist x y n
  edist_self x := by simp
  edist_comm x y := by simp [truncEDist, edist_comm]
  edist_triangle x y z := calc
        ∑' n, truncEDist x z n
    _ ≤ ∑' n, (truncEDist x y n + truncEDist y z n) := by
      gcongr with n
      simp_rw [← mul_add, truncEDist]
      gcongr
      calc
            min (edist (f n x.ofPiNat) (f n z.ofPiNat)) 1
        _ ≤ min (edist (f n x.ofPiNat) (f n y.ofPiNat) +
              edist (f n y.ofPiNat) (f n z.ofPiNat)) 1 := by
          gcongr; exact edist_triangle (f n x.ofPiNat) (f n y.ofPiNat) (f n z.ofPiNat)
        _ ≤ min (edist (f n x.ofPiNat) (f n y.ofPiNat)) 1 +
              min (edist (f n y.ofPiNat) (f n z.ofPiNat)) 1 := by
          obtain hxy | hxy := le_total (edist (f n x.ofPiNat) (f n y.ofPiNat)) 1 <;>
            obtain hyz | hyz := le_total (edist (f n y.ofPiNat) (f n z.ofPiNat)) 1 <;>
              simp [*]
    _ = _ := ENNReal.tsum_add ..

lemma edist_def (x y : PiNatEmbed X Y f) :
    edist x y = ∑' n, (1/2) ^ n * min (edist (f n x.ofPiNat) (f n y.ofPiNat)) 1 := rfl

end PseudoEMetricSpace

section PseudoMetricSpace
variable [∀ n, PseudoMetricSpace (Y n)]

private lemma min_le_geometric {x y : X} (n : ℕ) :
    ‖(1 / 2) ^ n * min (dist (f n x) (f n y)) 1‖ ≤ (1 / 2) ^ n := by
  simp only [one_div, inv_pow, Real.norm_eq_abs, abs_mul, abs_inv, abs_pow, Nat.abs_ofNat,
    inv_pos, Nat.ofNat_pos, pow_pos, mul_le_iff_le_one_right]
  rw [abs_of_nonneg (by positivity)]
  exact min_le_right ..

private lemma summable_min {x y : X} :
    Summable fun n ↦ (1 / 2) ^ n * min (dist (f n x) (f n y)) 1 := by
    apply (summable_geometric_two.of_norm_bounded) min_le_geometric


noncomputable instance : PseudoMetricSpace (PiNatEmbed X Y f) :=
  PseudoEMetricSpace.toPseudoMetricSpaceOfDist'
    (fun x y ↦ ∑' n, (1/2) ^ n * min (dist (f n x.ofPiNat) (f n y.ofPiNat)) 1)
    (fun x y ↦ by dsimp; positivity) fun x y ↦ by
      rw [edist_def, ENNReal.ofReal_tsum_of_nonneg (fun _ ↦ by positivity) summable_min]
      simp [edist, truncEDist, ENNReal.inv_pow]

lemma dist_def (x y : PiNatEmbed X Y f) :
    dist x y = ∑' n, (1/2) ^ n * min (dist (f n x.ofPiNat) (f n y.ofPiNat)) 1 := rfl

variable [TopologicalSpace X]

lemma continuous_toPiNat (continuous_f : ∀ n, Continuous (f n)) :
    Continuous (toPiNat : X → PiNatEmbed X Y f) := by
  rw [continuous_iff_continuous_dist]
  exact continuous_tsum (by fun_prop) summable_geometric_two fun n (a, b) ↦ min_le_geometric _

end PseudoMetricSpace

section EMetricSpace
variable [∀ n, EMetricSpace (Y n)]

/-- If the functions `f n : X → Y n` separate points of `X`, then `X` can be embedded into
`∀ n, Y n`. -/
noncomputable abbrev emetricSpace (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    EMetricSpace (PiNatEmbed X Y f) where
  eq_of_edist_eq_zero hxy := by ext; exact separating_f.eq <| by simpa [edist_def] using hxy

end EMetricSpace

open Set
section MetricSpace
variable [∀ n, MetricSpace (Y n)] --{Z : ℕ → Icc 0 1}

/-- If the functions `f n : X → Y n` separate points of `X`, then `X` can be embedded into
`∀ n, Y n`. -/
noncomputable abbrev metricSpace (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    MetricSpace (PiNatEmbed X Y f) :=
  (emetricSpace separating_f).toMetricSpace fun x y ↦ by simp [← ENNReal.ofReal_dist]

section CompactSpace
variable [TopologicalSpace X] [CompactSpace X]

lemma isHomeomorph_toPiNat (continuous_f : ∀ n, Continuous (f n))
    (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    IsHomeomorph (toPiNat : X → PiNatEmbed X Y f) := by
  letI := emetricSpace separating_f
  rw [isHomeomorph_iff_continuous_bijective]
  exact ⟨continuous_toPiNat continuous_f, (toPiNatEquiv X Y f).bijective⟩

variable (X Y f) in
/-- Homeomorphism between `X` and its embedding into `∀ n, Y n` induced by a separating family of
continuous functions `f n : X → Y n`. -/
@[simps!]
noncomputable def toPiNatHomeo (continuous_f : ∀ n, Continuous (f n))
    (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    X ≃ₜ PiNatEmbed X Y f :=
  (toPiNatEquiv X Y f).toHomeomorphOfIsInducing
    (isHomeomorph_toPiNat continuous_f separating_f).isInducing


end CompactSpace

open TopologicalSpace Classical Filter

variable [MetricSpace X] [SeparableSpace X] [Nonempty X]
--Note we need to handle the empty case sometime too

--def Z n := ℕ → Icc (0:ℝ) 1
--lemma compactness : CompactSpace (ℕ → Icc 0 1) := compactSpace

noncomputable section
def D : ℕ → X := choose (exists_dense_seq X)

--variable (X) in
lemma dense_range_D : DenseRange (D : ℕ → X) := by
  rw [denseRange_iff_closure_range]
  exact denseRange_iff_closure_range.mp <| choose_spec (exists_dense_seq X)

variable (X) in
def T_func : ℕ → X → Icc (0:ℝ) 1 := fun n x ↦
  projIcc (0:ℝ) 1 zero_le_one (dist x (D n))

lemma continuous_T (n : ℕ) : Continuous (T_func X n) := by
  exact continuous_projIcc.comp <| Continuous.dist continuous_id' continuous_const

lemma separation (x : X) (C : Set X) (hC : IsClosed C) (hnC : Nonempty C) (hx : x ∉ C) :
  ∃ (ε : ℝ) (i : ℕ), 0 < ε ∧ T_func X i x ≤ ε / 3 ∧ ∀ y ∈ C, (T_func X i y) ≥ 2 * ε / 3 := by
  let bigg_eps : ℝ := min (infDist x C) 1
  have big_pos : bigg_eps / 3 > 0 := by
    simp [bigg_eps]
    refine (IsClosed.notMem_iff_infDist_pos hC Nonempty.of_subtype).mp hx
  have : DenseRange (D : ℕ → X) := dense_range_D
  have suff_i : ∃ i, dist x (D i)  < bigg_eps / 3 := by
    rw [denseRange_iff] at this
    exact this x (bigg_eps / 3) big_pos
  obtain ⟨i, hi⟩ := suff_i
  use bigg_eps, i
  constructor
  · simp [bigg_eps]; refine (IsClosed.notMem_iff_infDist_pos hC Nonempty.of_subtype).mp hx
  constructor
  · simp [T_func]
    rw [@coe_projIcc]; simp; constructor
    · exact le_of_lt big_pos
    right; exact le_of_lt hi
  intro y hy
  simp [T_func]
  rw [@coe_projIcc]
  simp; right; constructor
  · ring_nf
    have ineq : min (infDist x C) 1 ≤ 1 := by simp
    refine mul_le_one₀ ineq (by positivity) (by linarith)
  calc
    dist y (D i) ≥ dist x y - dist x (D i) := by
      simp; rw [add_comm]; exact dist_triangle_right x y (D i)
    _ ≥ infDist x C - bigg_eps / 3 := by
      refine tsub_le_tsub (infDist_le_dist_of_mem hy) (le_of_lt hi)
    _ ≥ 2 * bigg_eps / 3 := by
      have joe_mama : (infDist x C) ≥ bigg_eps := by simp [bigg_eps]
      rw [ge_iff_le, le_sub_iff_add_le']
      apply le_trans _ joe_mama
      ring_nf; rfl


lemma injective_T : Pairwise fun x y ↦ ∃ n, T_func X n x ≠ T_func X n y := by
  intro x y hxy
  let singleton_y : Set X := {y}
  obtain ⟨ε, n, hεpos, lilbound, bigbound⟩ := separation x singleton_y (isClosed_singleton)
    (instNonemptyOfInhabited) (hxy)
  use n; specialize bigbound y rfl
  refine Subtype.coe_ne_coe.mp <| ne_of_lt ?_
  apply lilbound.trans_lt
  apply gt_of_ge_of_gt bigbound; linarith

-- def T' : ℕ → X → Icc (0 : ℝ) 1 :=
--   --obtain ⟨d : Set X,a,b⟩ := exists_countable_dense X
--   fun n x => min (dist x <| D n) 1
variable (A : Type*) [TopologicalSpace A]

-- lemma IsInducingSeq (F : X → A) (hb : Bijective F) (hfor : SeqContinuous F) (hypo : ∀ (xn : ℕ → X) (x : X), Tendsto xn atTop (𝓝 x) ↔ Tendsto (F ∘ xn) atTop (𝓝 <| F x)) : IsHomeomorph F := by --(hback : SeqContinuous F ⁻¹)
--   rw [isHomeomorph_iff_exists_inverse]
--   refine ⟨?_,?_,?_,?_,?_⟩
--   · exact SeqContinuous.continuous hfor
--   ·

--Will need to specialize this to embedding

-- variable (Z : Type*) [TopologicalSpace Z]
-- lemma isEmbedding_iff_exists_inverse (g : X → Z) : IsEmbedding g ↔ Continuous g ∧ ∃ h : Z → X,--g '' (univ)
--     LeftInverse h g ∧ RightInverse h g  ∧ Continuous h := by
--   refine ⟨fun hf ↦ ⟨hf.continuous, ?_⟩, fun ⟨hf, h, hg⟩ ↦ ?_⟩
--   have : IsHomeomorph g := by
--     refine isHomeomorph_iff_isEmbedding_surjective.mpr ?_
--     constructor

-- theorem exists_strictMono_subsequence {P : ℕ → Prop} (h : ∀ N, ∃ n ≥ N, P n) :
--     ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∀ n, P (φ n) := by
--   have : NoMaxOrder {n // P n} := by
--     refine { exists_gt := ?_ }
--     simp
--     intro a Pa
--     specialize h a

--     ⟨fun n ↦ Exists.intro ⟨(h n.1).choose, (h n.1).choose_spec.2⟩ (h n.1).choose_spec.1⟩
--   obtain ⟨f, hf, _⟩ := Nat.exists_strictMono' (⟨(h 0).choose, (h 0).choose_spec.2⟩ : {n // P n})
--   exact Exists.intro (fun n ↦ (f n).1) ⟨hf, fun n ↦ (f n).2⟩

--   · sorry
--   -- · let l := hf.embedding g
--   --   exact ⟨h.symm, h.left_inv, h.right_inv, h.continuous_invFun⟩
--   · exact (Homeomorph.mk ⟨g, h, hg.1, hg.2.1⟩ hf hg.2.2).isHomeomorph
example (S : Set X) (a : X) (ha : a ∈ S) : a ∈ closure S := by

theorem homeothingamajig : ∃ fonction : (X → (ℕ → Icc (0:ℝ) 1)), IsEmbedding fonction := by
  have firststep : X ≃ₜ PiNatEmbed X (fun n => Icc (0:ℝ) 1) (T_func X) := {
    toFun := toPiNatEquiv X (fun n => Icc (0:ℝ) 1) (T_func X)
    invFun := ofPiNat
    left_inv _ := rfl
    right_inv _ := rfl
    continuous_toFun := by
      simp [toPiNatEquiv]
      refine continuous_toPiNat ?_; intro n
      exact continuous_T n
    continuous_invFun := by
      refine SeqContinuous.continuous ?_
      intro txn tx h_conv_txn
      --apply (tendsto_of_subseq_tendsto)
      by_contra! hdoesnt
      rw [tendsto_atTop'] at hdoesnt
      simp only [gt_iff_lt, ge_iff_le, comp_apply, not_forall, not_exists,
        not_lt] at hdoesnt
      obtain ⟨ε,εpos,hwhat⟩ := hdoesnt
      simp at hwhat
      --rw [←Filter.frequently_atTop'] at hwhat
      change ∀ (N : ℕ), ∃ n > N, ε ≤ dist (txn n).ofPiNat tx.ofPiNat at hwhat
      obtain ⟨subseq,hmonosubseq,hsepsubseq⟩ := Nat.exists_strictMono_subsequence hwhat
      have sep : tx.ofPiNat ∉ (closure <| Set.range (fun n => (txn <| subseq n).ofPiNat)) := by
        refine (infDist_pos_iff_notMem_closure (range_nonempty fun n ↦ (txn (subseq n)).ofPiNat)).mpr ?_
        rw [infDist_eq_iInf]
        apply lt_of_lt_of_le εpos
        refine (le_ciInf_set_iff (range_nonempty fun n ↦ (txn (subseq n)).ofPiNat) ?_).mpr ?_
        · refine bddBelow_def.mpr ?_
          use 0
          simp; exact fun a ↦ dist_nonneg
        · simp; refine fun a ↦ by rw [dist_comm]; exact hsepsubseq a
      have clos : IsClosed (closure <| Set.range (fun n => (txn <| subseq n).ofPiNat)) := isClosed_closure
      have nonemp : Nonempty <| (closure <| Set.range (fun n => (txn <| subseq n).ofPiNat)) := by
        rw [@nonempty_coe_sort, closure_nonempty_iff]; exact range_nonempty fun n ↦ (txn (subseq n)).ofPiNat
      obtain ⟨δ,i,δpos,hlineq,hgreq⟩ := separation tx.ofPiNat (closure <| Set.range (fun n => (txn <| subseq n).ofPiNat)) clos nonemp sep
      rw [tendsto_atTop] at h_conv_txn
      specialize h_conv_txn (2 * δ / 3) (by positivity)
      rw [← eventually_atTop,eventually_iff_seq_eventually] at h_conv_txn
      specialize h_conv_txn subseq <| StrictMono.tendsto_atTop hmonosubseq
      simp at h_conv_txn
      obtain ⟨a,hb⟩ := h_conv_txn
      specialize hb (a+1) (Nat.le_add_right a 1)
      have rangeclosure : (txn (subseq (a + 1))).ofPiNat ∈ closure (range fun n ↦ (txn (subseq n)).ofPiNat) := by
        apply subset_closure
        exact mem_range_self (a + 1)
      specialize hgreq (txn <| subseq (a+1)).ofPiNat rangeclosure
      


  }
  sorry

theorem homeothing : ∃ fonction : (X → (ℕ → Icc (0:ℝ) 1)), IsEmbedding fonction := by
  have firststep : X ≃ₜ PiNatEmbed X (fun n => Icc (0:ℝ) 1) (T_func X) := {
    toFun := toPiNatEquiv X (fun n => Icc (0:ℝ) 1) (T_func X)
    invFun := ofPiNat
    left_inv _ := rfl
    right_inv _ := rfl
    continuous_toFun := by
      simp [toPiNatEquiv]
      refine continuous_toPiNat ?_; intro n
      exact continuous_T n
    continuous_invFun := by
      refine SeqContinuous.continuous ?_
      intro txn tx h_conv_txn
      apply (tendsto_of_subseq_tendsto)
      --1. all subsequences converge to tx.ofPiNat
      --
      intro subseq hsubseqinfty
      use id
      by_contra! hdoesnt
      simp at hdoesnt
      have sep : tx.ofPiNat ∉ (closure <| range (fun n => (txn (subseq n)).ofPiNat)) := by
        rw [tendsto_atTop] at hdoesnt
        simp at hdoesnt
        obtain ⟨ε,εpos,hwhat⟩ := hdoesnt; specialize hwhat 0
        obtain ⟨n,npos,hwhat1⟩ := hwhat
        sorry
      have clos : IsClosed (closure <| Set.range (fun n => (txn (subseq n)).ofPiNat)) := isClosed_closure
      have nonemp : Nonempty <| (closure <| Set.range (fun n => (txn (subseq n)).ofPiNat)) := by
        rw [@nonempty_coe_sort, closure_nonempty_iff]; exact range_nonempty fun n ↦ (txn (subseq n)).ofPiNat
      have fromclaim : ∃ (ε : ℝ) (i : ℕ), 0 < ε ∧ T_func X i (tx.ofPiNat) ≤ ε / 3 ∧ ∀ y ∈ (closure <| Set.range (fun n => (txn (subseq n)).ofPiNat)), (T_func X i y) ≥ 2 * ε / 3 := by
        exact separation tx.ofPiNat (closure <| Set.range (fun n => (txn (subseq n)).ofPiNat)) clos nonemp sep

      obtain ⟨ε,i,εpos,lineq,gineq⟩ := fromclaim
      sorry
      --have sub : ∃ (subsequence : ℕ → ℕ), tx.ofPiNat ∉ (ofPiNat ∘ txn ∘ subsequence) '' _ := by sorry
      -- rw [Filter.not_tendsto_iff_exists_frequently_notMem] at this
      -- obtain ⟨s, hs_neighbourhood, hs_not_conv⟩ := this
      -- rw [frequently_iff_forall_eventually_exists_and] at hs_not_conv
      --obtain ⟨a⟩ := hs_not_conv
      --rw [frequently_atTop] at hs_not_conv


      --specialize hs_not_conv 3
      --obtain ⟨b, hb, not_conv⟩ := hs_not_conv

  } --refine toPiNatHomeo X ?_ ?_

  have secondstep : IsEmbedding (T_func X : (ℕ → X → Icc (0:ℝ) 1)) := by sorry
  sorry

lemma IsInducingSeq (hb : Bijective (T_func X)) (hfor : SeqContinuous (T_func X)) : IsHomeomorph (T_func X) := by --(hback : SeqContinuous F ⁻¹) (hypo : ∀ (xn : ℕ → X) (x : X), Tendsto xn atTop (𝓝 x) ↔ Tendsto ((T_func X) ∘ xn) atTop (𝓝 <| F x))
  rw [isHomeomorph_iff_exists_inverse] --Need a version of this for embeddings
  refine ⟨?_,?_,?_,?_,?_⟩
  · exact SeqContinuous.continuous hfor
  sorry
  sorry
  sorry
  sorry


instance : SequentialSpace <| PiNatEmbed X (fun n => Icc (0:ℝ) 1) (T_func X) := FrechetUrysohnSpace.to_sequentialSpace

lemma isEmbedding_toPiNaticc :
    IsEmbedding (toPiNat : X → PiNatEmbed X (fun n => Icc (0:ℝ) 1) (T_func X)) := by
  rw [isEmbedding_iff_isInducing]
  refine isInducing_iff_nhds.mpr ?_
  intro x
  --rw [← @nhds_induced] - Potentially useful, but no idea how to proceed as no lemmas work on it
  rw [@Filter.ext_iff]
  intro S
  constructor
  intro hS
  · simp
    use toPiNat '' S
    constructor
    rw [@mem_nhds_iff]




  -- rw [isEmbedding_iff, isInducing_iff_nhds]
  -- refine ⟨fun x ↦ ((continuous_toPiNat continuous_T).tendsto x).le_comap.antisymm ?_,
  --   (toPiNatEquiv X (fun n => Icc (0:ℝ) 1) (T_func X)).injective⟩
  -- simp_rw [le_def]
  -- intro xe hxe
  -- refine (mem_comap_iff ?_ ?_).mpr ?_
  -- have injection (x : X) : { ofPiNat := x } = toPiNat x := by apply?
  -- · rw [@injective_iff_pairwise_ne]
  --   sorry
  -- · rw [range]
  --   simp
  -- · rw [mem_nhds_iff] at hxe
  --   refine mem_interior_iff_mem_nhds.mp ?_
  --   --rw [interior]
  --   rw [@mem_interior]
  --   simp
  --   obtain ⟨ε, hεpos, hε⟩ := hxe
  --   use ball x ε
  --   constructor; exact hε
  --   constructor
  --   · rw [@isOpen_iff_continuous_mem]
  --     simp
  --     constructor
  --     intro s t




  -- , mem_nhds_iff]
  --rintro S ⟨ε, hε, hεs⟩
  -- refine ⟨ofPiNat ⁻¹' S, ?_, .rfl⟩


  --intro xe hxe
  -- rw [← nhds_induced]
  -- rw [mem_nhds_induced]
  --refine (mem_nhds_induced toPiNat x xe).mp ?_




  -- , mem_nhds_iff]
  -- rintro S ⟨ε, hε, hεs⟩
  -- refine ⟨ofPiNat ⁻¹' S, ?_, .rfl⟩
  sorry



lemma isEmbedding_toPiNat (continuous_f : ∀ n, Continuous (f n))
    (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    IsEmbedding (toPiNat : X → PiNatEmbed X Y f) := by
  letI metspace := metricSpace separating_f
  rw [isEmbedding_iff, isInducing_iff_nhds]
  refine ⟨fun x ↦ ((continuous_toPiNat continuous_f).tendsto x).le_comap.antisymm ?_,
    (toPiNatEquiv X Y f).injective⟩
  simp_rw [Filter.le_def, mem_nhds_iff]
  rintro S ⟨ε, hε, hεs⟩
  refine ⟨ofPiNat ⁻¹' S, ?_, .rfl⟩
  by_cases hempt : IsEmpty X
  · refine preimage_nhds_coinduced ?_
    simp
    rw [← Set.singleton_subset_iff]
    have klj : {x} ⊆ ball x ε := by
      simp only [Set.singleton_subset_iff, mem_ball, dist_self]
      exact hε
    exact klj.trans hεs -- Empty case
  rw [not_isEmpty_iff] at hempt
  --obtain ⟨p⟩ := hempt
  let D : ℕ → X := choose (exists_dense_seq X)
  sorry


  --let α : ℕ → X → ℝ := fun n x => min (dist x <| D n) 1

  -- · refine Continuous.continuousAt ?_
  --   refine SeqContinuous.continuous ?_
  --   intro Tn limTn hconvTn
  --   by_contra!






    --from continuity of f? No
  -- simp
  -- rw [mem_nhds_iff]
  -- use ε

  --simp [ofPiNat];
  --rw [@mem_nhds_iff];
  -- refine eventually_nhds_iff_ball.mp ?_
  -- rw [eventually_iff_seq_eventually]
  -- intro zn htendszn
  -- refine tendsto_principal.mp ?_
  -- have Function.injective f := by


  -- use 2 * ε; constructor
  --· norm_num; exact hε
  --refine Set.image_subset_iff.mp ?_


  -- by_contra!


  -- rw [Metric]
  -- refine ⟨fun x ↦ ?_, (toPiNatEquiv X Y f).injective⟩


  -- rw [isHomeomorph_iff_continuous_bijective]
  -- exact ⟨continuous_toPiNat continuous_f, (toPiNatEquiv X Y f).bijective⟩

--end MetricSpace
--end MetricSpace
--end Metric.PiNatEmbed

variable [TopologicalSpace X] [CompactSpace X] [∀ n, MetricSpace (Y n)]

/-- If `X` is compact, and there exists a sequence of continuous functions `f n : X → Y n` to
metric spaces `Y n` that separate points on `X`, then `X` is metrizable. -/
lemma TopologicalSpace.MetrizableSpace.of_countable_separating (f : ∀ n, X → Y n)
    (continuous_f : ∀ n, Continuous (f n)) (separating_f : Pairwise fun x y ↦ ∃ n, f n x ≠ f n y) :
    MetrizableSpace X :=
  letI := Metric.PiNatEmbed.metricSpace separating_f
  (Metric.PiNatEmbed.toPiNatHomeo X Y f continuous_f separating_f).isEmbedding.metrizableSpace
