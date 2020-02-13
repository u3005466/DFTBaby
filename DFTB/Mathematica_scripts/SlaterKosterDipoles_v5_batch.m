ClearAll[Evaluate[
  Context[] <> "*"]] (*remove all previous definitions*)

PrintReturn[x_] := 
 Module[{}, PrintTemporary[x]; 
  x] (* allows to include intermediate output in chain of functions*)

  (* Rules for rotating spherical part of orbitals *)

lmax = 2
wD[l_, m1_, m2_] := 
 Block[{\[Alpha] = \[Pi]/
    2, \[Beta] = \[CapitalTheta], \[Gamma] = \[CapitalPhi]}, 
  ComplexExpand[WignerD[{l, m1, m2}, \[Alpha], \[Beta], \[Gamma]]]]

rotateYlmRules := 
 Flatten[Table[
   ysph[l, m] -> 
    Sum[wD[l, \[Mu], m]*ysph[l, \[Mu]], {\[Mu], -l, l}], {l, 0, 
    lmax}, {m, -l, l}]]
ysph2real[l_, m_] := (-1)^m*Which[
   	m > 0, 1/Sqrt[2]*(yreal[l, m] + I*yreal[l, -m]),
   	m == 0, yreal[l, m],
   	m < 0, (-1)^m/Sqrt[2]*(yreal[l, -m] - I*yreal[l, m])]
ysph2yrealRules :=
 
 Flatten[Table[
   ysph[l, m] -> ysph2real[l, m], {l, 0, lmax}, {m, -l, l}]]
yreal2ysph[l_, m_] := (-1)^m*Which[
   	m > 0, 1/Sqrt[2]*(ysph[l, m] + (-1)^m*ysph[l, -m]),
   	m == 0, ysph[l, m],
   	m < 0, -I/Sqrt[2]*(ysph[l, -m] - (-1)^m*ysph[l, m])]
yreal2ysphRules := 
 Flatten[Table[
   yreal[l, m] -> yreal2ysph[l, m], {l, 0, lmax}, {m, -l, l}]]
yreal2lm := 
 Flatten[Table[
   Simplify[yreal[l1, m1].yreal[lM, mM].yreal[l2, m2]] -> {l1, m1, lM,
      mM, l2, m2}, {l1, 0, lmax}, {m1, -l1, l1}, {lM, 1, 1}, {mM, -1, 
    1}, {l2, 0, lmax}, {m2, -l2, l2}]]
Print["yreal2lm"]
yreal2lm
(*Conjugate[yreal]-> yreal*)
yrealConjugationRules :=
 
 Flatten[Table[
   Conjugate[yreal[l, m]] -> yreal[l, m], {l, 0, lmax}, {m, -l, l}]]
(*Rotate real spherical harmonics*)

rotatedYreal[l_, 
  m_] := ((yreal[l, m] /. yreal2ysphRules) /. rotateYlmRules) /. 
  ysph2yrealRules
conjugationRules := 
 Join[{Conjugate[\[CapitalTheta]] -> \[CapitalTheta], 
   Conjugate[\[CapitalPhi]] -> \[CapitalPhi], 
   Im[\[CapitalTheta]] -> 0, Re[\[CapitalTheta]] -> \[CapitalTheta], 
   Im[\[CapitalPhi]] -> 0, Re[\[CapitalPhi]] -> \[CapitalPhi]}, 
  yrealConjugationRules]
realAssumptions := 
 Join[Flatten[
   Table[Element[yreal[l, m], Reals], {l, 0, lmax}, {m, -l, l}]],
  {Element[Cos[\[CapitalPhi]], Reals], 
   Element[Sin[\[CapitalPhi]], Reals],
   Element[Cos[\[CapitalTheta]], Reals], 
   Element[Sin[\[CapitalTheta]], Reals],
   Element[x, Reals], Element[y, Reals], Element[z, Reals]}]
(* check transformation between real and complex spherical harmonics *)
\
On[Assert]
Map[Assert, Flatten[Table[
    FullSimplify[(yreal[l, m] /. yreal2ysphRules) /. 
       ysph2yrealRules] == yreal[l, m],
    {l, 0, 2}, {m, -l, l}]]];
(* Table of angular part of real spherical harmonics *)
orbitalslm := 
 Select[{{s, 0, 0}, {py, 1, -1}, {pz, 1, 0}, {px, 1, 1}, {dxy, 
    2, -2}, {dyz, 2, -1}, {dz2, 2, 0}, {dzx, 2, 1}, {dx2y2, 2, 2}}, 
  Part[#, 2] <= lmax &] 
yreal2orbitalRules := 
 Map[yreal[Part[#, 2], Part[#, 3]] -> Part[#, 1] &, orbitalslm]
yrealList = Map[{Part[#, 1], Part[#, 2], Part[#, 3],
    FullSimplify[
     ComplexExpand[
      yreal2ysph[Part[#, 2], 
        Part[#, 3]] /. {ysph[l_, m_] -> 
         SphericalHarmonicY[l, m, \[CapitalTheta], \[CapitalPhi]]}]]
    } &, orbitalslm]
yrealList // 
 TableForm[# , 
   TableHeadings -> {{}, {"Symbol", "l", "m", 
      "Yreal(\[CapitalTheta],\[CapitalPhi])"}}] &

Find distinct multipole integrals
multipoleIntegrand[l1_, m1_, lM_, mM_, l2_, m2_] := TensorExpand[
  FullSimplify[(Conjugate[ComplexExpand[rotatedYreal[l1, m1]]] /. 
      conjugationRules).rotatedYreal[lM, mM].rotatedYreal[l2, m2], 
   realAssumptions]
  ]

multipoles := Flatten[Table[
   {yreal[l1, m1].yreal[lM, mM].yreal[l2, m2],
    Integrate[((yreal[l1, m1] /. yreal2ysphRules) /. 
        ysph[l_, m_] -> 
         SphericalHarmonicY[l, m, \[CapitalTheta]1, \[CapitalPhi]])*
      Sqrt[(4*\[Pi])/
      3]*((yreal[lM, mM] /. yreal2ysphRules) /. 
        ysph[l_, m_] -> 
         SphericalHarmonicY[l, 
          m, \[CapitalTheta]1, \[CapitalPhi]])*((yreal[l2, m2] /. 
          yreal2ysphRules) /. 
        ysph[l_, m_] -> 
         SphericalHarmonicY[l, 
          m, \[CapitalTheta]2, \[CapitalPhi]]), {\[CapitalPhi], 0, 
      2*\[Pi]}]}, {l1, 0, lmax}, {lM, 1, 1}, {mM, -1, 1}, {l2, 0, 
    lmax}, {m1, -l1, l1}, {m2, -l2, l2}], 5]
Print["Multipoles"]
multipoles /. 
  yreal[l1_, m1_].yreal[lM_, mM_].yreal[l2_, m2_] -> {l1, m1, lM, mM, 
    l2, m2} // 
 TableForm[#, 
   TableHeadings -> {{}, {"(l1,m1,lM,mM,l2,m2)", 
      "\[Phi](\[Theta]1,\[Theta]2)"}}, TableDepth -> 2] &
distinctMultipoles := 
 Map[Part[#, 2] &, 
  DeleteDuplicates[multipoles, Part[#1, 2] == Part[#2, 2] &]]
Print["Distinct Multipoles"]
distinctMultipoles
(* replace each unique integral by a symbol of the type SK[#], e.g. \
SK[1],SK[2],...*)
SetAttributes[SK, NumericFunction]
multipole2numIntegralsRules := Map[
  Block[{Intg = Part[#, 2], pattern = Part[#, 1]},
    If[SameQ[Intg, 0],
     pattern -> 0,
     pos = Position[distinctMultipoles, Intg, 1];
     If[Length[pos] == 1,
      pattern -> SK[Part[Flatten[pos], 1] - 1], {}; Print[pos]]]] &
  , multipoles]
Print["multipole2numIntegralsRules"]
multipole2numIntegralsRules
sklist = DeleteDuplicates[
  Flatten[multipole2numIntegralsRules /. 
    yreal2lm]](*, Part[#1,1]==Part[#2,1]&]*)

multipoleRule[l1_, m1_, lM_, mM_, l2_, m2_] := 
 If[SameQ[Integrate[((yreal[l1, m1] /. yreal2ysphRules) /. 
       ysph[l_, m_] -> 
        SphericalHarmonicY[l, m, \[CapitalTheta]1, \[CapitalPhi]])*
     ((yreal[lM, mM] /. yreal2ysphRules) /. 
       ysph[l_, m_] -> 
        SphericalHarmonicY[l, 
         m, \[CapitalTheta]1, \[CapitalPhi]])*((yreal[l2, m2] /. 
         yreal2ysphRules) /. 
       ysph[l_, m_] -> 
        SphericalHarmonicY[l, 
         m, \[CapitalTheta]2, \[CapitalPhi]]), {\[CapitalPhi], 0, 
     2*\[Pi]}], 0],
  yreal[l1, m1].yreal[lM, mM].yreal[l2, m2] -> 0, {}]
zeroMultipoleRules := 
 Flatten[Table[
   multipoleRule[l1, m1, lM, mM, l2, m2], {l1, 0, lmax}, {l2, 0, 
    lmax}, {lM, 1, 1}, {m1, -l1, l1}, {m2, -l2, l2}, {mM, -1, 1}]]

multipole2SKIntegralsRules := {
  s*s -> skInt[ss\[Sigma]],
  s*pz -> skInt[sp\[Sigma]], pz*s -> skInt[sp\[Sigma]],
  s*dz2 -> skInt[sd\[Sigma]], dz2*s -> skInt[sd\[Sigma]],
  py^2 -> skInt[pp\[Pi]],
  py*dyz -> skInt[pd\[Pi]], dyz*py -> skInt[pd\[Pi]],
  pz^2 -> skInt[pp\[Sigma]],
  pz*dz2 -> skInt[pd\[Sigma]], dz2*pz -> skInt[pd\[Sigma]],
  px^2 -> skInt[pp\[Pi]],
  px*dzx -> skInt[pd\[Pi]], dzx*px -> skInt[pd\[Pi]],
  dxy^2 -> skInt[dd\[Delta]],
  dyz^2 -> skInt[dd\[Pi]],
  dz2^2 -> skInt[dd\[Sigma]],
  dzx^2 -> skInt[dd\[Pi]],
  dx2y2^2 -> skInt[dd\[Pi]]}
Slater Koster Transformation Rules
SlaterKosterMultipole[l1_, m1_, lM_, mM_, l2_, m2_] := 
 FullSimplify[((TensorExpand[(
       (
         TrigExpand[
           FullSimplify[
            TrigExpand[
             FullSimplify[
              ComplexExpand[
               multipoleIntegrand[l1, m1, lM, mM, l2, m2]]]], 
            realAssumptions]] // 
          TransformedField[
            "Spherical" -> 
             "Cartesian", #, {R, \[CapitalTheta], \[CapitalPhi]} -> \
{x, y, z}] &)
        /. zeroMultipoleRules)] /. 
     Flatten[multipole2numIntegralsRules])), realAssumptions]

(* The following code takes very long, calculate is ones and reload \
it from a file *)
Print["Slater-Koster transformations for multipoles"]

SKtransfListxyz = Outer[PrintReturn[{
      Part[#1, 1], Part[#1, 2], Part[#1, 3],
      Part[#2, 1], Part[#2, 2], Part[#2, 3],
      Part[#3, 1], Part[#3, 2], Part[#3, 3],
      SlaterKosterMultipole[Part[#1, 2], Part[#1, 3], Part[#2, 2], 
       Part[#2, 3], Part[#3, 2], Part[#3, 3]]
      }] &, orbitalslm, {{py, 1, -1}, {pz, 1, 0}, {px, 1, 1}}, 
   orbitalslm, 1, 1, 1] // Flatten[#, 2] &
SKtransfListxyz // 
 TableForm[#, 
   TableHeadings -> {{}, {"O1", "l1", "m1", "Multipole Operator M", 
      "lM", "mM", "O2 at R", "l2", "m2", "Multipole Integral"}}] &
Put[SKtransfListxyz, "sktransflistxyz_multipoles_batch.expr"]

Print["Write python scripts"]
SKtransfListxyz = Get["sktransflistxyz_multipoles_batch.expr"]
SKtransfListxyz = 
 FullSimplify[
  SKtransfListxyz /. SK[n_] -> Dipole[n, Sqrt[x^2 + y^2 + z^2]]]
phiList = ((distinctMultipoles /. {\[Pi] -> pi}) /. {Sin[x_] -> 
      sin[x], Cos[x_] -> cos[x], 
     Sqrt[x_] -> sqrt[x]}) /. {\[CapitalTheta]1 -> 
    th1, \[CapitalTheta]2 -> th2}
fh = OpenWrite[
  FileNameJoin[{NotebookDirectory[], "transformations_dipole_batch.py"}]]
WriteString[fh, "# This file has been generated automatically\n"]
WriteString[fh, "from numpy import sin,cos,sqrt,pi\n"]
(* Subscript[\[Phi], \[Tau]](Subscript[\[Theta], \
1],Subscript[\[Theta], 2])*)
WriteString[fh, "phi = [ \\\n"]
Do[WriteString[fh, "\tlambda th1,th2: ", FortranForm[expr], 
  ", \\\n"], {expr, phiList}]
WriteString[fh, "]\n\n"]
(* find Subscript[\[Phi], \[Tau]](Subscript[\[Theta], 1],Subscript[\
\[Theta], 2]), which we have to use for a pair of orbitals \
(l1,m1,lM,mM,l2,m2) *)
WriteString[fh, "angular_phi = {\\\n"]
Do[
 If[SameQ[Part[tup, 2], 0], Print[tup]; Print[Part[tup, 2]], 
  WriteString[fh, "\t", 
   "(", Part[Part[tup, 1], 1], ",",
   	Part[Part[tup, 1], 2], "," ,
   	Part[Part[tup, 1], 3], ",",
   	Part[Part[tup, 1], 4], "," ,
   	Part[Part[tup, 1], 5], ",",
   	Part[Part[tup, 1], 6], ")", 
   " : ", "phi[", Part[tup, 2] /. SK[x_] -> x, "],\t\\\n"], 
  "],\\\n"], {tup, sklist}]
WriteString[fh, "}\n\n"] 
(* tau2index *)
WriteString[fh, "tau2index = {\\\n"]
Do[
 If[SameQ[Part[tup, 2], 0], Print[tup]; Print[Part[tup, 2]], 
  WriteString[fh, "\t", 
   "(", Part[Part[tup, 1], 1], ",",
   	Part[Part[tup, 1], 2], "," ,
   	Part[Part[tup, 1], 3], ",",
             Part[Part[tup, 1], 4], "," ,
   	Part[Part[tup, 1], 5], ",",
   	Part[Part[tup, 1], 6], ")", 
   " : ", Part[tup, 2] /. SK[x_] -> x, ",\\\n"]], {tup, sklist}]
WriteString[fh, "}\n\n"] 
(* index2tau *)
sklistUniqueIndeces = 
 Union[sklist, 
  SameTest -> (((Part[#1, 2] /. SK[x_] -> x) == (Part[#2, 2] /. 
         SK[x_] -> x)) &)]
WriteString[fh, "index2tau = {\\\n"]
Do[
 If[SameQ[Part[tup, 2], 0], Print[tup]; Print[Part[tup, 2]], 
  WriteString[fh, "\t", 
   Part[tup, 2] /. SK[x_] -> x, " : ", "(",
   	Part[Part[tup, 1], 1], ",",
   	Part[Part[tup, 1], 2], "," ,
   	Part[Part[tup, 1], 3], ",",
             Part[Part[tup, 1], 4], "," ,
   	Part[Part[tup, 1], 5], ",",
   	Part[Part[tup, 1], 6], ")", ",\\\n"]], {tup, 
  sklistUniqueIndeces}]
WriteString[fh, "}\n\n"] 
WriteString[fh, "# transformation rules for matrix elements\n"]
SKtransfListDirCos = 
 FullSimplify[
  FullSimplify[(SKtransfListxyz /. x^2 + y^2 + z^2 -> r^2) /. {x -> 
       x*r, y -> y*r, z -> z*r}, r >= 0] /. Sqrt[x_] -> sqrt[x]]
WriteString[fh, "# x,y,z are directional cosines, r is the distance \
between the two centers\n"]
WriteString[fh, "slako_transformations = {\\\n"]
Do[WriteString[fh, "\t", 
  "(", Part[tup, 2], ",",
  	Part[tup, 3], "," ,
  	Part[tup, 5], ",",
  	Part[tup, 6], ",",
            Part[tup, 8], "," ,
  	Part[tup, 9], ")", 
  " : ", "lambda r,x,y,z,Dipole: ", FortranForm[Part[tup, 10]], 
  ", \\\n"], {tup, SKtransfListDirCos}]
WriteString[fh, "}\n"]

Close[fh]
Print["FINISHED"]

