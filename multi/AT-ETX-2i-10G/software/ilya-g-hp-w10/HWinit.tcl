set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_181\\bin
switch -exact -- $gaSet(pair) {
  1 {
      set gaSet(comDut)     2
      set gaSet(com220)    4; #8
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FTRQM3J  
  }
  2 {
      set gaSet(comDut)    5
      set gaSet(com220)    6
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FTLVF8G         
  }
  
}  
source lib_PackSour.tcl
