set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)      4; #7
      set gaSet(com220)      2; #9
      set gaSet(comAux1)     7; #2
      set gaSet(comAux2)     10; #6
      set gaSet(comGpib)    13
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FTRQM3J  
  }
  2 {
      set gaSet(comDut)     6; #10
      set gaSet(com220)     5; # 8
      set gaSet(comAux1)   stam
      set gaSet(comAux2)   stam
      set gaSet(comGpib)   stam
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FTRQC03         
  }
  
}  
source lib_PackSour.tcl
