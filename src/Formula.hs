module Formula where

import Prelude hiding (or, and, not)
import Data.Set (Set, delete, empty, fromList, member, singleton, union)
import Nominal.Variable (Variable, quantificationVariable)

----------------------------------------------------------------------------------------------------
-- Relation
----------------------------------------------------------------------------------------------------
data Relation = Equals | LessThan | LessEquals | GreaterThan | GreaterEquals deriving (Eq, Ord)

instance Show Relation where
    show Equals = "="
    show LessThan = "<"
    show LessEquals = "≤"
    show GreaterThan = ">"
    show GreaterEquals = "≥"

relationAscii :: Relation -> String
relationAscii Equals = "="
relationAscii LessThan = "<"
relationAscii LessEquals = "<="
relationAscii GreaterThan = ">"
relationAscii GreaterEquals = ">="

----------------------------------------------------------------------------------------------------
-- Formula
----------------------------------------------------------------------------------------------------

data Formula
    = T
    | F
    | Constraint Relation Variable Variable
    | And Formula Formula
    | Or Formula Formula
    | Not Formula
    | Imply Formula Formula
    | Equivalent Formula Formula
    | ForAll Variable Formula
    | Exists Variable Formula

-- true
true :: Formula
true = T

-- false
false :: Formula
false = F

-- constraints
equals :: Variable -> Variable -> Formula
equals x1 x2 = if x1 == x2 then T else Constraint Equals x1 x2

lessThan :: Variable -> Variable -> Formula
lessThan x1 x2 = if x1 == x2 then F else Constraint LessThan x1 x2

lessEquals :: Variable -> Variable -> Formula
lessEquals x1 x2 = if x1 == x2 then T else Constraint LessEquals x1 x2

greaterThan :: Variable -> Variable -> Formula
greaterThan x1 x2 = if x1 == x2 then F else Constraint GreaterThan x1 x2

greaterEquals :: Variable -> Variable -> Formula
greaterEquals x1 x2 = if x1 == x2 then T else Constraint GreaterEquals x1 x2

-- and
(/\) :: Formula -> Formula -> Formula
T /\ f = f
F /\ _ = F
f /\ T = f
_ /\ F = F

-- FIXME: uprościć
f@(Constraint LessThan x1 x2) /\ (Constraint LessEquals y1 y2) | x1 == y1 && x2 == y2 = f
(Constraint LessThan x1 x2) /\ (Constraint Equals y1 y2) | x1 == y1 && x2 == y2 = lessEquals x1 x2
(Constraint LessThan x1 x2) /\ (Constraint GreaterThan y1 y2) | x1 == y1 && x2 == y2 = F
(Constraint LessThan x1 x2) /\ (Constraint GreaterEquals y1 y2) | x1 == y1 && x2 == y2 = F

(Constraint LessEquals x1 x2) /\ f@(Constraint LessThan y1 y2) | x1 == y1 && x2 == y2 = f
f@(Constraint LessEquals x1 x2) /\ (Constraint Equals y1 y2) | x1 == y1 && x2 == y2 = f
(Constraint LessEquals x1 x2) /\ (Constraint GreaterThan y1 y2) | x1 == y1 && x2 == y2 = F
(Constraint LessEquals x1 x2) /\ (Constraint GreaterEquals y1 y2) | x1 == y1 && x2 == y2 = equals x1 x2

(Constraint Equals x1 x2) /\ (Constraint LessThan y1 y2) | x1 == y1 && x2 == y2 = lessEquals x1 x2
(Constraint Equals x1 x2) /\ f@(Constraint LessEquals y1 y2) | x1 == y1 && x2 == y2 = f
(Constraint Equals x1 x2) /\ (Constraint GreaterThan y1 y2) | x1 == y1 && x2 == y2 = greaterEquals x1 x2
(Constraint Equals x1 x2) /\ f@(Constraint GreaterEquals y1 y2) | x1 == y1 && x2 == y2 = f

(Constraint GreaterThan x1 x2) /\ (Constraint LessThan y1 y2) | x1 == y1 && x2 == y2 = F
(Constraint GreaterThan x1 x2) /\ (Constraint LessEquals y1 y2) | x1 == y1 && x2 == y2 = F
(Constraint GreaterThan x1 x2) /\ (Constraint Equals y1 y2) | x1 == y1 && x2 == y2 = greaterEquals x1 x2
f@(Constraint GreaterThan x1 x2) /\ (Constraint GreaterEquals y1 y2) | x1 == y1 && x2 == y2 = f

(Constraint GreaterEquals x1 x2) /\ (Constraint LessThan y1 y2) | x1 == y1 && x2 == y2 = F
(Constraint GreaterEquals x1 x2) /\ (Constraint LessEquals y1 y2) | x1 == y1 && x2 == y2 = equals x1 x2
f@(Constraint GreaterEquals x1 x2) /\ (Constraint Equals y1 y2) | x1 == y1 && x2 == y2 = f
(Constraint GreaterEquals x1 x2) /\ f@(Constraint GreaterThan y1 y2) | x1 == y1 && x2 == y2 = f

(Not f1) /\ (Not f2) = (not (f1 \/ f2))
f1 /\ f2
    | f1 == f2       = f1
    | (not f1) == f2 = F
    | otherwise      = And f1 f2

and :: [Formula] -> Formula
and [] = T
and fs = foldr1 (/\) fs

-- or
(\/) :: Formula -> Formula -> Formula
F \/ f = f
T \/ _ = T
f \/ F = f
_ \/ T = T
(Not f1) \/ (Not f2) = (not (f1 /\ f2))
f1 \/ f2
    | f1 == f2       = f1
    | (not f1) == f2 = T
    | otherwise      = Or f1 f2

or :: [Formula] -> Formula
or [] = F
or fs = foldr1 (\/) fs

-- not
not :: Formula -> Formula
not F = T
not T = F
not (Constraint LessThan x1 x2) = greaterEquals x1 x2
not (Constraint LessEquals x1 x2) = greaterThan x1 x2
not (Constraint GreaterThan x1 x2) = lessEquals x1 x2
not (Constraint GreaterEquals x1 x2) = lessThan x1 x2
not (Not f) = f
not f = Not f

-- imply
(==>) :: Formula -> Formula -> Formula
T ==> f = f
F ==> _ = T
_ ==> T = T
f ==> F = f
(Not f1) ==> (Not f2) = f2 ==> f1
f1 ==> f2
    | f1 == f2       = T
    | (not f1) == f2 = f2
    | otherwise      = Imply f1 f2

implies :: Formula -> Formula -> Formula
implies = (==>)

-- equivalent
(<==>) :: Formula -> Formula -> Formula
T <==> f = f
F <==> f = not f
f <==> T = f
f <==> F = not f
(Not f1) <==> (Not f2) = f1 <==> f2
f1 <==> f2
    | f1 == f2       = T
    | (not f1) == f2 = F
    | otherwise      = Equivalent f1 f2

iff :: Formula -> Formula -> Formula
iff = (<==>)

-- for all
(∀) :: Variable -> Formula -> Formula
(∀) _ T = T
(∀) _ F = F
(∀) x (Not f) = not $ (∃) x f
(∀) x f = quantificationFormula ForAll x f

forAllVars :: Variable -> Formula -> Formula
forAllVars = (∀)

-- exists
(∃) :: Variable -> Formula -> Formula
(∃) _ T = T
(∃) _ F = F
(∃) x (Not f) = not $ (∀) x f
(∃) x f = quantificationFormula Exists x f

existsVar :: Variable -> Formula -> Formula
existsVar = (∃)

----------------------------------------------------------------------------------------------------
-- Formula instances
----------------------------------------------------------------------------------------------------

-- Show

showFormula :: Formula -> String
showFormula f@(And f1 f2) = "(" ++ show f ++ ")"
showFormula f@(Or f1 f2) = "(" ++ show f ++ ")"
showFormula f@(Imply f1 f2) = "(" ++ show f ++ ")"
showFormula f@(Equivalent f1 f2) = "(" ++ show f ++ ")"
showFormula (ForAll x f) = "∀" ++ show x ++ "(" ++ show f ++ ")"
showFormula (Exists x f) = "∃" ++ show x ++ "(" ++ show f ++ ")"
showFormula f = show f

instance Show Formula where
    show T = "true"
    show F = "false"
    show (Constraint r x1 x2) = show x1 ++ " " ++ show r ++ " " ++ show x2
    show (Not (Constraint Equals x1 x2)) = show x1 ++ " ≠ " ++ show x2
    show (And f1 f2) = showFormula f1 ++ " ∧ " ++ showFormula f2
    show (Or f1 f2) = showFormula f1 ++ " ∨ " ++ showFormula f2
    show (Not f) = "¬(" ++ show f ++ ")"
    show (Imply f1 f2) = showFormula f1 ++ " → " ++ showFormula f2
    show (Equivalent f1 f2) = showFormula f1 ++ " ↔ " ++ showFormula f2
    show (ForAll x f) = "∀" ++ show x ++ " " ++ show f
    show (Exists x f) = "∃" ++ show x ++ " " ++ show f

-- Ord

compareEquivalentPairs :: (Ord a) => (a, a) -> (a, a) -> Ordering
compareEquivalentPairs (x11, x12) (x21, x22) =
    compareSortedPairs
        (if x11 <= x12 then (x11, x12) else (x12, x11))
        (if x21 <= x22 then (x21, x22) else (x22, x21))

compareSortedPairs :: (Ord a, Ord b) => (a, b) -> (a, b) -> Ordering
compareSortedPairs (x11, x12) (x21, x22) =
    let compareFirst = compare x11 x21
    in if compareFirst == EQ
         then compare x12 x22
         else compareFirst

instance Ord Formula where
    compare T T = EQ
    compare T _ = GT
    compare _ T = LT

    compare F F = EQ
    compare F _ = GT
    compare _ F = LT

    compare (Constraint Equals x1 y1) (Constraint Equals x2 y2) = compareEquivalentPairs (x1, y1) (x2, y2)
    compare (Constraint r1 x1 y1) (Constraint r2 x2 y2) = if r1 == r2
                                                            then compareSortedPairs (x1, y1) (x2, y2)
                                                            else if symmetricRelations r1 r2
                                                                   then compareSortedPairs (x1, x2) (y2, y1)
                                                                   else compare r1 r2
    compare (Constraint _ _ _) _ = GT
    compare _ (Constraint _ _ _) = LT

    compare (And f11 f12) (And f21 f22) = compareEquivalentPairs (f11, f12) (f21, f22)
    compare (And _ _) _ = GT
    compare _ (And _ _) = LT

    compare (Or f11 f12) (Or f21 f22) = compareEquivalentPairs (f11, f12) (f21, f22)
    compare (Or _ _) _ = GT
    compare _ (Or _ _) = LT

    compare (Not f1) (Not f2) = compare f1 f2
    compare (Not _) _ = GT
    compare _ (Not _) = LT

    compare (Imply f11 f12) (Imply f21 f22) = compareSortedPairs (f11, f12) (f21, f22)
    compare (Imply _ _) _ = GT
    compare _ (Imply _ _) = LT

    compare (Equivalent f11 f12) (Equivalent f21 f22) = compareEquivalentPairs (f11, f12) (f21, f22)
    compare (Equivalent _ _) _ = GT
    compare _ (Equivalent _ _) = LT

    compare (ForAll x1 f1) (ForAll x2 f2) =  compareSortedPairs (x1, f1) (x2, f2)
    compare (ForAll _ _) _ = GT
    compare _ (ForAll _ _) = LT

    compare (Exists x1 f1) (Exists x2 f2) =  compareSortedPairs (x1, f1) (x2, f2)

-- Eq

instance Eq Formula where
    f1 == f2 = (compare f1 f2) == EQ

----------------------------------------------------------------------------------------------------
-- Auxiliary functions
----------------------------------------------------------------------------------------------------

relationOperation :: Relation -> Variable -> Variable -> Formula
relationOperation Equals = equals
relationOperation LessThan = lessThan
relationOperation LessEquals = lessEquals
relationOperation GreaterThan = greaterThan
relationOperation GreaterEquals = greaterEquals

symmetricRelations :: Relation -> Relation -> Bool
symmetricRelations LessThan GreaterThan = True
symmetricRelations GreaterThan LessThan = True
symmetricRelations LessEquals GreaterEquals = True
symmetricRelations GreaterEquals LessEquals = True
symmetricRelations _ _ = False

freeVariables :: Formula -> Set Variable
freeVariables T = empty
freeVariables F = empty
freeVariables (Constraint _ x1 x2) = fromList [x1, x2]
freeVariables (And f1 f2) = union (freeVariables f1) (freeVariables f2)
freeVariables (Or f1 f2) = union (freeVariables f1) (freeVariables f2)
freeVariables (Not f) = freeVariables f
freeVariables (Imply f1 f2) = union (freeVariables f1) (freeVariables f2)
freeVariables (Equivalent f1 f2) = union (freeVariables f1) (freeVariables f2)
freeVariables (ForAll x f) = delete x (freeVariables f)
freeVariables (Exists x f) = delete x (freeVariables f)

mapFormulaVariables :: (Variable -> Variable) -> Formula -> Formula
mapFormulaVariables _ T = T
mapFormulaVariables _ F = F
mapFormulaVariables fun (Constraint r x1 x2) = (relationOperation r) (fun x1) (fun x2)
mapFormulaVariables fun (And f1 f2) = mapFormulaVariables fun f1 /\ mapFormulaVariables fun f2
mapFormulaVariables fun (Or f1 f2) = mapFormulaVariables fun f1 \/ mapFormulaVariables fun f2
mapFormulaVariables fun (Not f) = not $ mapFormulaVariables fun f
mapFormulaVariables fun (Imply f1 f2) = mapFormulaVariables fun f1 ==> mapFormulaVariables fun f2
mapFormulaVariables fun (Equivalent f1 f2) = mapFormulaVariables fun f1 <==> mapFormulaVariables fun f2
mapFormulaVariables fun (ForAll x f) = (∀) (fun x) (mapFormulaVariables fun f)
mapFormulaVariables fun (Exists x f) = (∃) (fun x) (mapFormulaVariables fun f)

replaceFormulaVariable :: Variable -> Variable -> Formula -> Formula
replaceFormulaVariable oldVar newVar = mapFormulaVariables (\var -> if oldVar == var then newVar else var)

foldFormulaVariables :: (Variable -> a -> a) -> a -> Formula -> a
foldFormulaVariables _ acc T = acc
foldFormulaVariables _ acc F = acc
foldFormulaVariables fun acc (Constraint _ x1 x2) = fun x2 $ fun x1 acc
foldFormulaVariables fun acc (And f1 f2) = foldFormulaVariables fun (foldFormulaVariables fun acc f1) f2
foldFormulaVariables fun acc (Or f1 f2) = foldFormulaVariables fun (foldFormulaVariables fun acc f1) f2
foldFormulaVariables fun acc (Not f) = foldFormulaVariables fun acc f
foldFormulaVariables fun acc (Imply f1 f2) = foldFormulaVariables fun (foldFormulaVariables fun acc f1) f2
foldFormulaVariables fun acc (Equivalent f1 f2) = foldFormulaVariables fun (foldFormulaVariables fun acc f1) f2
foldFormulaVariables fun acc (ForAll x f) = foldFormulaVariables fun (fun x acc) f
foldFormulaVariables fun acc (Exists x f) = foldFormulaVariables fun (fun x acc) f

getQuantificationLevel :: Formula -> Int
getQuantificationLevel T = 0
getQuantificationLevel F = 0
getQuantificationLevel (Constraint _ _ _) = 0
getQuantificationLevel (And f1 f2) = max (getQuantificationLevel f1) (getQuantificationLevel f2)
getQuantificationLevel (Or f1 f2) = max (getQuantificationLevel f1) (getQuantificationLevel f2)
getQuantificationLevel (Not f) = getQuantificationLevel f
getQuantificationLevel (Imply f1 f2) = max (getQuantificationLevel f1) (getQuantificationLevel f2)
getQuantificationLevel (Equivalent f1 f2) = max (getQuantificationLevel f1) (getQuantificationLevel f2)
getQuantificationLevel (ForAll x f) = succ $ getQuantificationLevel f
getQuantificationLevel (Exists x f) = succ $ getQuantificationLevel f

quantificationFormula :: (Variable -> Formula -> Formula) -> Variable -> Formula -> Formula
quantificationFormula makeFormula x f = if member x $ freeVariables f
                                        then let qv = quantificationVariable $ succ $ getQuantificationLevel f
                                             in makeFormula qv (replaceFormulaVariable x qv f)
                                        else f

fromBool :: Bool -> Formula
fromBool True = T
fromBool False = F

getFormulaRelations :: Formula -> Set Relation
getFormulaRelations T = empty
getFormulaRelations F = empty
getFormulaRelations (Constraint r _ _) = singleton r
getFormulaRelations (And f1 f2) = union (getFormulaRelations f1) (getFormulaRelations f2)
getFormulaRelations (Or f1 f2) = union (getFormulaRelations f1) (getFormulaRelations f2)
getFormulaRelations (Not f) = getFormulaRelations f
getFormulaRelations (Imply f1 f2) = union (getFormulaRelations f1) (getFormulaRelations f2)
getFormulaRelations (Equivalent f1 f2) = union (getFormulaRelations f1) (getFormulaRelations f2)
getFormulaRelations (ForAll _ f) = getFormulaRelations f
getFormulaRelations (Exists _ f) = getFormulaRelations f

