set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_191\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     2
      set gaSet(com220)     4
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT5PFBSH  
  }
  2 {
      set gaSet(comDut)      5
      set gaSet(com220)      6
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT4SNHED         
  }
  3 {
      set gaSet(comDut)      7
      set gaSet(com220)      8
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 3"} 
      set gaSet(pioBoxSerNum) FT5PFBON         
  }
  4 {
      set gaSet(comDut)      9
      set gaSet(com220)      10
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 4"} 
      set gaSet(pioBoxSerNum) FTRQ9LR         
  }
  
}  
source lib_PackSour.tcl
