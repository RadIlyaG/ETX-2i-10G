set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      #set gaSet(comDut)     9; #2
      set gaSet(comMiniUsb)  9
      set gaSet(comMicroUsb) 4
      set gaSet(com220)     7; #4
      set gaSet(comAux1)    5; #8
      set gaSet(comAux2)    2; #9
      set gaSet(comGpib)    13
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FTRQM3J  
  }
  2 {
      #set gaSet(comDut)    8; #5
      set gaSet(comMiniUsb)  8
      set gaSet(comMicroUsb) 6
      set gaSet(com220)    10; #6
      set gaSet(comAux1)   stam
      set gaSet(comAux2)   stam
      set gaSet(comGpib)   stam
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FTRQC03         
  }
  
}  
source lib_PackSour.tcl
