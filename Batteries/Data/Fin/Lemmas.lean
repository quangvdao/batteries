/-
Copyright (c) 2022 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro
-/
import Batteries.Data.Fin.Basic
import Batteries.Data.List.Lemmas

namespace Fin

attribute [norm_cast] val_last

/-! ### clamp -/

@[simp] theorem coe_clamp (n m : Nat) : (clamp n m : Nat) = min n m := rfl

/-! ### foldlM -/

theorem foldlM_loop_lt [Monad m] (f : α → Fin n → m α) (x) (h : i < n) :
    foldlM.loop n f x i = f x ⟨i, h⟩ >>= (foldlM.loop n f . (i+1)) := by
  rw [foldlM.loop, dif_pos h]

theorem foldlM_loop_eq [Monad m] (f : α → Fin n → m α) (x) : foldlM.loop n f x n = pure x := by
  rw [foldlM.loop, dif_neg (Nat.lt_irrefl _)]

theorem foldlM_loop [Monad m] (f : α → Fin (n+1) → m α) (x) (h : i < n+1) :
    foldlM.loop (n+1) f x i = f x ⟨i, h⟩ >>= (foldlM.loop n (fun x j => f x j.succ) . i) := by
  if h' : i < n then
    rw [foldlM_loop_lt _ _ h]
    congr; funext
    rw [foldlM_loop_lt _ _ h', foldlM_loop]; rfl
  else
    cases Nat.le_antisymm (Nat.le_of_lt_succ h) (Nat.not_lt.1 h')
    rw [foldlM_loop_lt]
    congr; funext
    rw [foldlM_loop_eq, foldlM_loop_eq]
termination_by n - i

@[simp] theorem foldlM_zero [Monad m] (f : α → Fin 0 → m α) (x) : foldlM 0 f x = pure x :=
  foldlM_loop_eq ..

theorem foldlM_succ [Monad m] (f : α → Fin (n+1) → m α) (x) :
    foldlM (n+1) f x = f x 0 >>= foldlM n (fun x j => f x j.succ) := foldlM_loop ..

/-! ### foldrM -/

theorem foldrM_loop_zero [Monad m] (f : Fin n → α → m α) (x) :
    foldrM.loop n f ⟨0, Nat.zero_le _⟩ x = pure x := by
  rw [foldrM.loop]

theorem foldrM_loop_succ [Monad m] (f : Fin n → α → m α) (x) (h : i < n) :
    foldrM.loop n f ⟨i+1, h⟩ x = f ⟨i, h⟩ x >>= foldrM.loop n f ⟨i, Nat.le_of_lt h⟩ := by
  rw [foldrM.loop]

theorem foldrM_loop [Monad m] [LawfulMonad m] (f : Fin (n+1) → α → m α) (x) (h : i+1 ≤ n+1) :
    foldrM.loop (n+1) f ⟨i+1, h⟩ x =
      foldrM.loop n (fun j => f j.succ) ⟨i, Nat.le_of_succ_le_succ h⟩ x >>= f 0 := by
  induction i generalizing x with
  | zero =>
    rw [foldrM_loop_zero, foldrM_loop_succ, pure_bind]
    conv => rhs; rw [←bind_pure (f 0 x)]
    congr; funext; exact foldrM_loop_zero ..
  | succ i ih =>
    rw [foldrM_loop_succ, foldrM_loop_succ, bind_assoc]
    congr; funext; exact ih ..

@[simp] theorem foldrM_zero [Monad m] (f : Fin 0 → α → m α) (x) : foldrM 0 f x = pure x :=
  foldrM_loop_zero ..

theorem foldrM_succ [Monad m] [LawfulMonad m] (f : Fin (n+1) → α → m α) (x) :
    foldrM (n+1) f x = foldrM n (fun i => f i.succ) x >>= f 0 := foldrM_loop ..

/-! ### foldl -/

theorem foldl_loop_lt (f : α → Fin n → α) (x) (h : i < n) :
    foldl.loop n f x i = foldl.loop n f (f x ⟨i, h⟩) (i+1) := by
  rw [foldl.loop, dif_pos h]

theorem foldl_loop_eq (f : α → Fin n → α) (x) : foldl.loop n f x n = x := by
  rw [foldl.loop, dif_neg (Nat.lt_irrefl _)]

theorem foldl_loop (f : α → Fin (n+1) → α) (x) (h : i < n+1) :
    foldl.loop (n+1) f x i = foldl.loop n (fun x j => f x j.succ) (f x ⟨i, h⟩) i := by
  if h' : i < n then
    rw [foldl_loop_lt _ _ h]
    rw [foldl_loop_lt _ _ h', foldl_loop]; rfl
  else
    cases Nat.le_antisymm (Nat.le_of_lt_succ h) (Nat.not_lt.1 h')
    rw [foldl_loop_lt]
    rw [foldl_loop_eq, foldl_loop_eq]

@[simp] theorem foldl_zero (f : α → Fin 0 → α) (x) : foldl 0 f x = x :=
  foldl_loop_eq ..

theorem foldl_succ (f : α → Fin (n+1) → α) (x) :
    foldl (n+1) f x = foldl n (fun x i => f x i.succ) (f x 0) :=
  foldl_loop ..

theorem foldl_succ_last (f : α → Fin (n+1) → α) (x) :
    foldl (n+1) f x = f (foldl n (f · ·.castSucc) x) (last n) := by
  rw [foldl_succ]
  induction n generalizing x with
  | zero => simp [foldl_succ, last]
  | succ n ih => rw [foldl_succ, ih (f · ·.succ), foldl_succ]; simp [succ_castSucc]

theorem foldl_eq_foldlM (f : α → Fin n → α) (x) :
    foldl n f x = foldlM (m:=Id) n f x := by
  induction n generalizing x <;> simp [foldl_succ, foldlM_succ, *]

/-! ### foldr -/

theorem foldr_loop_zero (f : Fin n → α → α) (x) :
    foldr.loop n f ⟨0, Nat.zero_le _⟩ x = x := by
  rw [foldr.loop]

theorem foldr_loop_succ (f : Fin n → α → α) (x) (h : i < n) :
    foldr.loop n f ⟨i+1, h⟩ x = foldr.loop n f ⟨i, Nat.le_of_lt h⟩ (f ⟨i, h⟩ x) := by
  rw [foldr.loop]

theorem foldr_loop (f : Fin (n+1) → α → α) (x) (h : i+1 ≤ n+1) :
    foldr.loop (n+1) f ⟨i+1, h⟩ x =
      f 0 (foldr.loop n (fun j => f j.succ) ⟨i, Nat.le_of_succ_le_succ h⟩ x) := by
  induction i generalizing x <;> simp [foldr_loop_zero, foldr_loop_succ, *]

@[simp] theorem foldr_zero (f : Fin 0 → α → α) (x) : foldr 0 f x = x :=
  foldr_loop_zero ..

theorem foldr_succ (f : Fin (n+1) → α → α) (x) :
    foldr (n+1) f x = f 0 (foldr n (fun i => f i.succ) x) := foldr_loop ..

theorem foldr_succ_last (f : Fin (n+1) → α → α) (x) :
    foldr (n+1) f x = foldr n (f ·.castSucc) (f (last n) x) := by
  induction n generalizing x with
  | zero => simp [foldr_succ, last]
  | succ n ih => rw [foldr_succ, ih (f ·.succ), foldr_succ]; simp [succ_castSucc]

theorem foldr_eq_foldrM (f : Fin n → α → α) (x) :
    foldr n f x = foldrM (m:=Id) n f x := by
  induction n <;> simp [foldr_succ, foldrM_succ, *]

theorem foldl_rev (f : Fin n → α → α) (x) :
    foldl n (fun x i => f i.rev x) x = foldr n f x := by
  induction n generalizing x with
  | zero => simp
  | succ n ih => rw [foldl_succ, foldr_succ_last, ← ih]; simp [rev_succ]

theorem foldr_rev (f : α → Fin n → α) (x) :
     foldr n (fun i x => f x i.rev) x = foldl n f x := by
  induction n generalizing x with
  | zero => simp
  | succ n ih => rw [foldl_succ_last, foldr_succ, ← ih]; simp [rev_succ]

/-! ### foldM -/

variable {n : Nat} {α : Fin (n+1) → Type _} [Monad m]
    (f : ∀ (i : Fin n), α i.castSucc → m (α i.succ))

theorem foldM_loop_lt (h : i < n) (x : α ⟨i, Nat.lt_add_right 1 h⟩) :
    foldM.loop n α f i (Nat.lt_add_right 1 h) x =
      (f ⟨i, h⟩ x) >>= (foldM.loop n α f (i+1) (Nat.add_lt_add_right h 1)) := by
  rw [foldM.loop, dif_pos h]

theorem foldM_loop_eq (x : α ⟨n, Nat.le_refl _⟩) :
    foldM.loop n α f n (Nat.le_refl _) x = pure x := by
  rw [foldM.loop, dif_neg (Nat.lt_irrefl _), cast_eq]

@[simp] theorem foldM_zero {α : Fin 1 → Sort _} (f : (i : Fin 0) → α i.castSucc → m (α i.succ))
    (x : α 0) : foldM 0 α f x = pure x :=
  foldM_loop_eq ..

variable {α : Fin (n+2) → Type _} (f : (i : Fin (n+1)) → α i.castSucc → m (α i.succ))

theorem foldM_loop (h : i < n+1) (x : α ⟨i, Nat.lt_add_right 1 h⟩) :
    foldM.loop (n+1) α f i (Nat.lt_add_right 1 h) x =
      f ⟨i, h⟩ x >>= (foldM.loop n (α ∘ succ) (f ·.succ ·) i h .) := by
  if h' : i < n then
    rw [foldM_loop_lt _ h _]
    congr; funext
    rw [foldM_loop_lt _ h' _, foldM_loop]; rfl
  else
    cases Nat.le_antisymm (Nat.le_of_lt_succ h) (Nat.not_lt.1 h')
    rw [foldM_loop_lt]
    congr; funext
    rw [foldM_loop_eq, foldM_loop_eq]

theorem foldM_succ (x) : foldM (n+1) α f x = f 0 x >>= foldM n (α ∘ succ) (f ·.succ ·) :=
  foldM_loop ..

/-- Dependent version `foldM` equals non-dependent version `foldlM` --/
theorem foldM_eq_foldlM {α : Type _} (f : Fin n → α → m α) (x : α) :
    foldM n (fun _ => α) f x = foldlM n (fun x i => f i x) x := by
  induction n generalizing x with
  | zero => simp only [foldM_zero, foldlM_zero]
  | succ n ih =>
    simp only [foldM_succ, foldlM_succ, Function.comp_apply, Function.comp_def]
    congr; ext; simp only [ih]

/-! ### fold -/

variable {α : Fin (n+1) → Sort _} (f : ∀ (i : Fin n), α i.castSucc → α i.succ)

theorem fold_loop_lt (h : i < n) (x : α ⟨i, Nat.lt_add_right 1 h⟩) :
    fold.loop n α f i (Nat.lt_add_right 1 h) x =
      fold.loop n α f (i+1) (Nat.add_lt_add_right h 1) (f ⟨i, h⟩ x) := by
  rw [fold.loop, dif_pos h]

theorem fold_loop_eq (x : α ⟨n, Nat.le_refl _⟩) :
    fold.loop n α f n (Nat.le_refl _) x = x := by
  rw [fold.loop, dif_neg (Nat.lt_irrefl _), cast_eq]

@[simp] theorem fold_zero {α : Fin 1 → Sort _} (f : (i : Fin 0) → α i.castSucc → α i.succ)
    (x : α 0) : fold 0 α f x = x :=
  fold_loop_eq ..

variable {α : Fin (n+2) → Sort _} (f : (i : Fin (n+1)) → α i.castSucc → α i.succ)

theorem fold_loop (h : i < n+1) (x : α ⟨i, Nat.lt_add_right 1 h⟩) :
    fold.loop (n+1) α f i (Nat.lt_add_right 1 h) x =
      fold.loop n (α ∘ succ) (f ·.succ ·) i h (f ⟨i, h⟩ x) := by
  if h' : i < n then
    rw [fold_loop_lt _ h _]
    rw [fold_loop_lt _ h' _, fold_loop]; rfl
  else
    cases Nat.le_antisymm (Nat.le_of_lt_succ h) (Nat.not_lt.1 h')
    rw [fold_loop_lt]
    rw [fold_loop_eq, fold_loop_eq]

theorem fold_succ (x : α 0) : fold (n+1) α f x = fold n (α ∘ succ) (f ·.succ ·) (f 0 x) :=
  fold_loop ..

theorem fold_succ_last (x : α 0) :
    fold (n+1) α f x = f (last n) (fold n (α ∘ castSucc) (f ·.castSucc ·) x) := by
  rw [fold_succ]
  induction n with
  | zero => simp [fold_succ, last]
  | succ n ih => rw [fold_succ, @ih (α ∘ succ) (f ·.succ ·), fold_succ]; congr

theorem fold_eq_foldl {α : Sort _} (f : Fin n → α → α) (x : α) :
    fold n (fun _ => α) f x = foldl n (fun x i => f i x) x := by
  induction n generalizing x with
  | zero => simp only [fold_zero, foldl_zero]
  | succ n ih =>
    simp only [fold_succ, foldl_succ, Function.comp_apply, Function.comp_def]
    congr; simp only [ih]
