set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)      5; #7
      set gaSet(com220)      2; #8
      set gaSet(comAux1)     10; #2
      set gaSet(comAux2)     9; #5
      set gaSet(comGpib)   13
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT31CMZG  
  }
  2 {
      set gaSet(comDut)      6; #10
       set gaSet(com220)     4; # 9
      set gaSet(comAux1)   stam
      set gaSet(comAux2)   stam
      set gaSet(comGpib)   stam
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT311ONG         
  }
  
}  
source lib_PackSour.tcl
