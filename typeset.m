(* Yi Wang, 2013, tririverwangyi@gmail.com, GPLv3 *)
BeginPackage["MathGR`typeset`", {"MathGR`tensor`"}]

ToTeX::usage="ToTeX[expr] translates expr into TeXForm"
ToTeXHook::usage="ToTeXHook is set of transformations before export to TeX"
DecorateTeXString::usage="DecorateTeXString[s] does post processing for a TeX string."
Begin["`Private`"]
Needs["MathGR`utilPrivate`"]
(* ::Section:: *)
(* TraditionalForm and TeX output *)

altUp:= Alternatives @@ IdxUpList
altDn:= Alternatives @@ IdxDnList
idxQ[idx__]:= MatchQ[{idx}, {(IdxPtn|_UE|_DE) ..}]
makeBoxesTsrQ = !MatchQ[#, List|Rule|Alternatives|Sequence]&
mkPd[form_][i___] := Sequence @@ (MakeBoxes[\[CapitalSampi]@#, form] & /@ {i})

SetOptions[$Output, PageWidth -> Infinity]

If[!defQ@ToTeXHook, ToTeXHook = {}]

(* (* TODO: the follows can be removed thanks to SyntaxForm *)
guessTensorQ[f_String]:= StringFreeQ[f, Characters@"+-*/"] && (!StringFreeQ[f, "^"]||!StringFreeQ[f, "_"])
removeParenthesis[s_String]:= FixedPoint[StringReplace[#, "\\left("~~f__~~"\\right)"~~g___~~EndOfString 
	/; StringFreeQ[f, {"\\left(", "\\right)"}](* not nested *) && guessTensorQ[f](* looks like tensor *) && (StringLength[g]<=3||StringTake[g,3]=!="{}^")(* not power of tensor *)
	:> f<>g]&, s]
*)
	
removeTextAndCurly[s_String]:= s // StringReplace[#, "\\text{"~~f__~~"}"/;StringFreeQ[f,{"{","}"}] :>f ] & // StringReplace[#, "$":>""] &
removeWaste[s_String]:= s // StringReplace[#, "\\text{}" :> "{}"] & // StringReplace[#, "){}^" :> ")^"] & // StringReplace[#, "\\partial {}_" :> "\\partial_"] &
replaceTimeDot[s_String]:= If[!StringFreeQ[s, "\\partial ^{-2}"], s (* dot acting on Pm2 looks wrong *),
	StringReplace[s, {"\\partial_0\\partial_0\\partial_0" :> "\\dddot", "\\partial_0\\partial_0" :> "\\ddot", "\\partial_0" :> "\\dot"}]]
breakLine[s_String]:= s // StringReplace[#, {"+":>"\n + ", f_~~"-" /; f=!="\n"&&f=!="{" :> f<>"\n - ", "=":>"\n= ", "\\to":>"\n \\to "}] &
addHeaderTail[s_String]:= "%Generated by MathGR/typeset.m, "<>DateString[]<>".\n\\documentclass{revtex4}\n\\usepackage{breqn}\n\\begin{document}\n\\begin{dmath}\n"<>s<>"\n\\end{dmath}\n\\end{document}\n"
finalCleanUp[s_String]:= s // StringReplace[#, {"\n\n"->"\n"}] & (* Shouldn't be necessary. Just in case. *)

If[!defQ@DecorateTeXString, DecorateTeXString = (
	Print["Warning: DecorateTeXString may produce unpredictable results. Please check the output.\nIn case of problem, set DecorateTeXString=Identity"];
	# (*// removeParenthesis*) // removeWaste // replaceTimeDot // removeTextAndCurly // breakLine // addHeaderTail // finalCleanUp) & ]

ToTeX[e_] := e//.ToTeXHook // PolynomialForm[#, TraditionalOrder -> False]& // ToString[#, TeXForm] & // DecorateTeXString // TraditionalForm

MakeBoxes[\[CapitalSampi], TraditionalForm]:="\[PartialD]"
MakeBoxes[Dta, TraditionalForm]:="\[Delta]"
MakeBoxes[tsr_[idx__], TraditionalForm]/;(idxQ[idx]&&makeBoxesTsrQ[tsr]):= With[
	{idList={idx}/.{altUp[i_]:>SuperscriptBox["", i], UE[i_]:>SuperscriptBox["", ToString@i], altDn[i_]:>SubscriptBox["", i], DE[i_]:>SubscriptBox["", ToString@i]}},
	TagBox[RowBox[{MakeBoxes[tsr, TraditionalForm]}~Join~idList],  "mgrTsr", SyntaxForm->"symbol"]]
MakeBoxes[PdT[f_, PdVars[i0:DE@0..., i__]], TraditionalForm] /; FreeQ[{i}, DE@0] := With[{id0 = mkPd[TraditionalForm]@i0, id = mkPd[TraditionalForm]@i}, 
	TagBox[RowBox[{id, id0, MakeBoxes[f, TraditionalForm]}], "mgrPdT", SyntaxForm -> "^"]]
MakeBoxes[PdT[f_, PdVars[i0:DE@0..]], TraditionalForm] := With[{id0 = mkPd[TraditionalForm]@i0}, 
	TagBox[RowBox[{id0, MakeBoxes[f, TraditionalForm]}], "mgrPdT", SyntaxForm -> "symbol"]]


(* ::Section:: *)
(* All the below only run with a frontend *)

If[$FrontEnd===Null, Print["(typeset.m): No FrontEnd detected. StandardForm and input aliases definitions skipped."],

(* ::Section:: *)
(* Tensor *)

MakeBoxes[tsr_[idx__], StandardForm]/;(idxQ[idx]&&makeBoxesTsrQ[tsr]):= TagBox[RowBox[{AdjustmentBox[MakeBoxes[tsr, StandardForm], BoxMargins -> {{0, -0.2}, {0, 0}}], 
	StyleBox[ GridBox[{idx} /. {
		{(a:altUp)[i_]:>TagBox[StyleBox[MakeBoxes[i, StandardForm], FontColor->IdxColor@a], a], 
			IdxDnPtn:>"", UE@n_:>TagBox[StyleBox[MakeBoxes[n, StandardForm], FontColor->IdxColor@UE],UE], DE@n_:>""}, 
		{IdxUpPtn:>"", (a:altDn)[i_]:>TagBox[StyleBox[MakeBoxes[i, StandardForm], FontColor->IdxColor@a], a], 
			DE@n_:>TagBox[StyleBox[MakeBoxes[n, StandardForm], FontColor->IdxColor@DE],DE], UE@n_:>""}
	}, ColumnSpacings->0, RowSpacings->0], FontSize->10]}], "mgrTsr"(*, SyntaxForm->"symbol"*)];

parseUD[lst_, StandardForm]:= Sequence @@ (Map[If[#[[1]] === "", #[[2]], #[[1]]] &, Transpose[lst]] /. {TagBox[i_ | StyleBox[i_, __], tag_] :> tag@ToExpression[i, StandardForm]});
MakeExpression[TagBox[RowBox[{AdjustmentBox[t_, ___], StyleBox[GridBox[idx__, ___], ___]}], "mgrTsr", OptionsPattern[]], StandardForm] := 
	With[{h = ToExpression[t, StandardForm], i = parseUD[idx, StandardForm]}, HoldComplete@h@i];

(* ::Section:: *)
(* Derivative *)

MakeBoxes[PdT[f_, PdVars[i__]], StandardForm] /; FreeQ[{i}, DE@0] || !FreeQ[{f}, Pm2] := With[{id = mkPd[StandardForm]@i}, TagBox[RowBox[{id, MakeBoxes[f, StandardForm]}], "mgrPdT"(*, SyntaxForm -> "^"*)]];
MakeBoxes[PdT[a_, PdVars[dt : DE@0 .., i__]], StandardForm] /; FreeQ[{i}, DE@0]:= With[{id = mkPd[StandardForm]@i, bu = StringJoin@ConstantArray["\[Bullet]", Length@{dt}]}, 
	TagBox[RowBox[{id, OverscriptBox[MakeBoxes[a, StandardForm], bu]}], "mgrPdT"(*, SyntaxForm -> "^"*)]];
MakeBoxes[PdT[a_, PdVars[dt : DE@0 ..]], StandardForm] /; FreeQ[{a}, Pm2] := With[{bu = StringJoin@ConstantArray["\[Bullet]", Length@{dt}]}, OverscriptBox[MakeBoxes[a, StandardForm], bu]];

MakeBoxes[Pm2[a_, type_], form_] := TagBox[RowBox[{TagBox[StyleBox[SuperscriptBox[MakeBoxes[\[CapitalSampi], form], "-2"], FontColor->IdxColor[type]], type], 
	"(", MakeBoxes[a, form], ")" }], "mgrPm2"];
MakeExpression[TagBox[RowBox[{TagBox[_, type_], "(", a_, ")"}], "mgrPm2"], StandardForm]:= With[{expr=Pm2[ToExpression[a, StandardForm], type]}, HoldComplete[expr]];

MakeExpression[TagBox[RowBox[{d__,f_}], "mgrPdT", OptionsPattern[]], StandardForm]:= 
	With[{idExpr=PdVars@@Cases[ToExpression[{d}, StandardForm], \[CapitalSampi][a_]:>a], fExpr=ToExpression[f, StandardForm]}, HoldComplete@PdT[fExpr, idExpr]];

MakeExpression[OverscriptBox[a_, str_String], StandardForm] := With[{pds = Nest[Pd[#, DE@0] &, ToExpression[a, StandardForm], 
      StringLength[str]]}, HoldComplete[pds]] /; StringMatchQ[str, "\[Bullet]" ..];

(* the following are used for backwards compatibility *)
MakeExpression[TagBox[RowBox[{SubscriptBox["\[CapitalSampi]", a_], f_}], "mgrPd"], StandardForm] := MakeExpression[RowBox[{"Pd[", f, ",", a, "]"}], StandardForm];

(* ::Section:: *)
(* Paste the blob calculated in InputAliases.nb *)

aliasesList= {"tp" -> TagBox[
   RowBox[{TagBox[
      RowBox[{AdjustmentBox["\[CapitalSampi]", 
         BoxMargins -> {{0, -0.2}, {0, 0}}], 
        StyleBox[
         GridBox[{{""}, {TagBox[
             StyleBox["\"\[SelectionPlaceholder]\"", 
              FontColor -> GrayLevel[0]], DN]}}, ColumnSpacings -> 0, 
          RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
     "\[Placeholder]"}], "mgrPdT"], 
 "tp0" -> OverscriptBox["\[SelectionPlaceholder]", "\[Bullet]"], 
 "tp1" -> TagBox[
   RowBox[{TagBox[
      RowBox[{AdjustmentBox["\[CapitalSampi]", 
         BoxMargins -> {{0, -0.2}, {0, 0}}], 
        StyleBox[
         GridBox[{{""}, {TagBox[
             StyleBox["\"\[SelectionPlaceholder]\"", 
              FontColor -> GrayLevel[0]], D1]}}, ColumnSpacings -> 0, 
          RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
     "\[Placeholder]"}], "mgrPdT"], 
 "tp2" -> TagBox[
   RowBox[{TagBox[
      RowBox[{AdjustmentBox["\[CapitalSampi]", 
         BoxMargins -> {{0, -0.2}, {0, 0}}], 
        StyleBox[
         GridBox[{{""}, {TagBox[
             StyleBox["\"\[SelectionPlaceholder]\"", 
              FontColor -> RGBColor[1, 0, 0]], D2]}}, 
          ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
      "mgrTsr"], "\[Placeholder]"}], "mgrPdT"], 
 "tpt" -> TagBox[
   RowBox[{TagBox[
      RowBox[{AdjustmentBox["\[CapitalSampi]", 
         BoxMargins -> {{0, -0.2}, {0, 0}}], 
        StyleBox[
         GridBox[{{""}, {TagBox[
             StyleBox["\"\[SelectionPlaceholder]\"", 
              FontColor -> RGBColor[0, 0, 1]], DTot]}}, 
          ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
      "mgrTsr"], "\[Placeholder]"}], "mgrPdT"], 
 "tu" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP]}, {""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "td" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tuu" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP]}, {"", ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tud" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], ""}, {"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], DN]}}, ColumnSpacings -> 0, 
       RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
 "tdu" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], UP]}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tdd" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tuuu" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP]}, {"", "", ""}}, ColumnSpacings -> 0, RowSpacings -> 0],
       FontSize -> 10]}], "mgrTsr"], 
 "tudd" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], "", ""}, {"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], DN], 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], DN]}}, ColumnSpacings -> 0, 
       RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
 "tddd" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", "", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tuuuu" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          UP]}, {"", "", "", ""}}, ColumnSpacings -> 0, 
       RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
 "tdddd" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", "", "", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          DN]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tu1" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          U1]}, {""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "td1" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          D1]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tu1u1" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          U1], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          U1]}, {"", ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tu1d1" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          U1], ""}, {"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], D1]}}, ColumnSpacings -> 0, 
       RowSpacings -> 0], FontSize -> 10]}], "mgrTsr"], 
 "td1u1" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> GrayLevel[0]], U1]}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          D1], ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "td1d1" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          D1], TagBox[
          StyleBox["\"\[Placeholder]\"", FontColor -> GrayLevel[0]], 
          D1]}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tu2" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], U2]}, {""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "td2" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], D2]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tu2u2" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], U2], 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], U2]}, {"", ""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tu2d2" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], U2], ""}, {"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], D2]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "td2u2" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], U2]}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], D2], ""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "td2d2" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], D2], 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[1, 0, 0]], D2]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tut" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], UTot]}, {""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tdt" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], DTot]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tutut" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], UTot], 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], UTot]}, {"", ""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tutdt" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], UTot], ""}, {"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], DTot]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tdtut" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], UTot]}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], DTot], ""}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tdtdt" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         ""}, {TagBox[
          StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], DTot], 
         TagBox[StyleBox["\"\[Placeholder]\"", 
           FontColor -> RGBColor[0, 0, 1]], DTot]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tu0" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          UE]}, {""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "td0" -> TagBox[
   RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{""}, {TagBox[
          StyleBox["0", FontColor -> GrayLevel[0.5]], DE]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "tu0u0" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          UE], TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          UE]}, {"", ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "tu0d0" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          UE], ""}, {"", 
         TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], DE]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"], 
 "td0u0" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          UE]}, {TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], 
          DE], ""}}, ColumnSpacings -> 0, RowSpacings -> 0], 
      FontSize -> 10]}], "mgrTsr"], 
 "td0d0" -> 
  TagBox[RowBox[{AdjustmentBox["\[SelectionPlaceholder]", 
      BoxMargins -> {{0, -0.2}, {0, 0}}], 
     StyleBox[
      GridBox[{{"", 
         ""}, {TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], DE],
          TagBox[StyleBox["0", FontColor -> GrayLevel[0.5]], DE]}}, 
       ColumnSpacings -> 0, RowSpacings -> 0], FontSize -> 10]}], 
   "mgrTsr"]};

SetOptions[EvaluationNotebook[], InputAliases -> aliasesList];

] (* end of the big if (or tell me how to stop in the middle of a package gracefully?) *)

End[]
EndPackage[]