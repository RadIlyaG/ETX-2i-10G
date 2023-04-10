set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     2
      set gaSet(com220)     4
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
      set gaSet(comGpib)    NA
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT5PF5Q2
  }
  2 {
      set gaSet(comDut)      5
      set gaSet(com220)      6
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT567X6X        
  }
  
}  
source lib_PackSour.tcl
