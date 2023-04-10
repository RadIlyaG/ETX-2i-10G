set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)      5; #6  
      set gaSet(com220)      2; #4 
      set gaSet(comAux1)     9; #9 
      set gaSet(comAux2)     11; #10
      set gaSet(comGpib)   13
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT2SUN8G  
  }
  2 {
      set gaSet(comDut)     4; #5
      set gaSet(com220)     6; #2
      set gaSet(comAux1)   stam
      set gaSet(comAux2)   stam
      set gaSet(comGpib)   stam
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT2SUO9R         
  }
  
}  
source lib_PackSour.tcl
