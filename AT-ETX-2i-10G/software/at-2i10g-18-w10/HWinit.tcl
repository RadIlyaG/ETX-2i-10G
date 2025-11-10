set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_191\\bin
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)    10; #2
      set gaSet(com220)    9;  #4
      set gaSet(comAux1)    NA
      set gaSet(comAux2)    NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT7FGL3S  
  }
  2 {
      set gaSet(comDut)     7; #5
      set gaSet(com220)     8; #6
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT7EUBQV        
  }
  3 {
      set gaSet(comDut)     5; #7
      set gaSet(com220)     6; #8
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 3"} 
      set gaSet(pioBoxSerNum) FT7EUAXK         
  }
  4 {
      set gaSet(comDut)    4; #9
      set gaSet(com220)    2; #10
      set gaSet(comAux1)   NA
      set gaSet(comAux2)   NA
      set gaSet(comGpib)   NA
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 4"} 
      set gaSet(pioBoxSerNum) FT7EUB3T         
  }
  
}  
source lib_PackSour.tcl
