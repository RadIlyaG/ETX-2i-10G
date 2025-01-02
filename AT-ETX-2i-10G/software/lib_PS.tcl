proc PS_RetriveDutFam {} {
  global gaSet
  set dutInitName $gaSet(DutInitName)
  puts "\nPS_RetriveDutFam $dutInitName"
  set gaSet(dutFam) 19B.0.0.0.0.8SFPP.0_0
  if [string match *.WDC.* $dutInitName] {
    set PS WDC
  } elseif [string match *.DC.* $dutInitName] {
    set PS DC
  } elseif [string match *.AC.* $dutInitName] {
    set PS AC
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$PS.$np.$up  
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(dutBox) $b
    
  puts "PS_RetriveDutFam dutInitName:$dutInitName dutBox:$gaSet(dutBox) DutFam:$gaSet(dutFam)" ; update
  return {}
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc PS_ID {run} {
  global gaSet buffer
  set com $gaSet(comDut) 

  Power all off
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ps=="WDC" || $ps=="DC"} {
    set ps_voltage "48V"
    set ps_type "DC"
  } else {
    set ps_voltage "AC"
    set ps_type "AC"
  }
  RLSound::Play information
  set txt "Connect $ps_voltage cables to ETX"
  set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Connect power cables" -message $txt]
  if {$res=="Stop"} {
    return -2
  }
  set ret 0  
  
  ## don't check PS2 since it's reference
  #foreach {ps} {1 2} { }
  foreach {ps} {1} { 
    Status "PS_ID $ps Test"
    Power all off
    after 3000
    Power $ps on
    set ret [Wait "Wait for Power ON" 30]
    if {$ret!=0} {return $ret}
    set ret [Login]
    if {$ret!=0} {
      #set ret [Login]
      if {$ret!=0} {return $ret}
    }   
  }
  Power all on
  after 5000
  
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" ">chassis"]
  if {$ret!=0} {set gaSet(fail) "Fail to reach chassis"; return $ret}
  set ret [Send $com "show environment\r" ">chassis"]
  if {$ret!=0} {set gaSet(fail) "Fail to see environment"; return $ret}
  
  set psQty [regexp -all $ps_type $buffer]
  set psQtyShBe 2
  puts "PS_ID psQty:$psQty psQtyShBe:$psQtyShBe"
  if {$psQty!=$psQtyShBe} {
    set gaSet(fail) "Qty or type of PSs is wrong."
    return -1
  }
  
  regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
  regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
  set ps1Status [string trim $ps1Status]    
  puts "ps1Status:<$ps1Status>"  
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
    return -1
  }
  
  ## don't check PS2 since it's reference
  # regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
  # set ps2Status [string trim $ps2Status]
  # puts "ps2Status:<$ps2Status>" 
  # if {$ps2Status!="OK"} {
    # set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
    # return -1
  # }    
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  puts "\nSerial Number DutInitName:<$gaSet(DutInitName)> "; update
  # if {[package vcompare $sw_norm 6.8.5.3.31]!="-1"} {
     # ## if sw_norm >=6.8.5.3.31
  # }
  
  if 1 {
    if {([string match {*ATT*} $gaSet(DutInitName)])} {
      if {[string match {*.ODU.*} $gaSet(DutInitName)]} {
        set invPs1 4002
        set invPs2 4003
      } else {
        set invPs1 4004
        set invPs2 4005      
      }
      puts "\nSerial Number ATT invPs1:<$invPs1> invPs2:<$invPs2>"; update  
      ## don't check PS2 since it's reference
      #foreach ps {1 2} {}
      foreach ps {1} {
        set inv [set invPs${ps}]
        puts "ps-$ps inv-$inv"
        set ret [Send $com "exit all\r" $gaSet(prompt)]
        if {$ret!=0} {set gaSet(fail) "exit all fail"; return $ret}
        set ret [Send $com "config system\r" "config>system"]
        if {$ret!=0} {set gaSet(fail) "config system fail"; return $ret}
        set ret [Send $com "inventory $inv\r" ($inv)]
        if {$ret!=0} {set gaSet(fail) "read inventory $inv fail"; return $ret}
        set ret [Send $com "show status\r" ($inv)]
        if {$ret!=0} {set gaSet(fail) "show status fail"; return $ret}
        # set res [regexp {Serial Number[\s:]+([a-zA-Z\d]+)\sMFG} $buffer ma val]
        set res [regexp {Serial Number[\s:]+([a-zA-Z\d]+)\s} $buffer ma val]
        if {$res==0} {
          set gaSet(fail) "Fail to get Serial Number of PS-$ps ($inv)"
          return -1
        }
        
        set sn_len [string length $val]
        puts "ps-$ps inv-$inv sn:<$val> sn_len:<$sn_len>\n"
        
        # no need check it since the regexp gets letters and digits
        # if {[string is digit $val]==0} {
          # set gaSet(fail) "Serial Number $val is not Digit Number"
          # return -1
        # }
        if {$sn_len!=10 && $sn_len!=16} {
          set gaSet(fail) "Serial Number's Length is $sn_len instead of 10 or 16"
          return -1
        }
        AddToPairLog $gaSet(pair) "PS-$ps Serial Number: $val"        
      }       
    }
  }
 
  ## don't check PS2 since it's reference
  # foreach ps {2 1} {}
  foreach ps {1} {
    Power $ps off
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Failed"} {
      after 1000
      set val [ShowPS $ps]
       puts "val:<$val>"
      if {$val=="-1"} {return -1}
       if {$val!="Failed"} {
        after 1000
         set val [ShowPS $ps]
         puts "val:<$val>"
        if {$val=="-1"} {return -1}
        if {$val!="Failed"} {
          set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
          return -1  
        } 
      }
    }
    
    RLSound::Play information
    set txt "Verify on PS-$ps that RED led is ON"
    set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "LED Test failed"
      return -1
    } else {
      set ret 0
    }
    
    RLSound::Play information
    set txt "Remove PS-$ps and verify that led is OFF"
    set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
        
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="Not exist"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
      return -1
    }
          
    RLSound::Play information
    set txt "Assemble PS-$ps"
    set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "PS_ID Test failed"
      return -1
    } else {
      set ret 0
    }
      
    Power $ps on
    after 2000      
  }
  
  RLSound::Play information
  ## don't check PS2 since it's reference
  #set txt "Close the screws of both PSs firmly and verify PSs are ON"
  set txt "Close the screws of PS-1 firmly and verify PSs are ON"
  set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt -aspect 1000]
  update
  if {$res!="OK"} {
    set gaSet(fail) "PS_ID Test failed"
    return -1
  } else {
    set ret 0
  }
  
  set val [ShowPS 1]
  #foreach {b r p d psType np up} [split $gaSet(dutFam) .] {}
  if {$ps_type eq "DC"} {
    set res [regexp {1\s+DC\s+OK\s+2\s+DC\s+OK} $buffer ma]
  } elseif {$ps_type eq "AC"} {
    set res [regexp {1\s+AC\s+OK\s+2\s+AC\s+OK} $buffer ma]
  }
  if {$res!=1} {
    set gaSet(fail) "Status of PSs is not \"1 $psType OK 2 $ps_type OK\""
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# PS_DataTransmission_conf
# ***************************************************************************
proc PS_DataTransmission_conf {run} {
  global gaSet buffer
  Status "PS_DataTransmission_conf"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" ETX-2]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "configure\r" config]
  if {$ret!=0} {return $ret}    
  set ret [Send $com "port\r" port]
  if {$ret!=0} {return $ret}  
  set ret [Send $com "ethernet 0/2\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "shutdown\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "functional-mode user\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no shutdown\r" 0/2]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" port]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit\r" config]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "flows\r" flows]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "no flow \"1\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"2\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"3\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"4\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"5\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"6\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"7\"\r" flows]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no flow \"8\"\r" flows]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "no classifier-profile \"1\"\r" flows]
  if {$ret!=0} {return $ret}
  after 1000
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(19BCF) "C:/AT-ETX-2i-10G/ConfFiles/8sfpp-data.txt"
  set ret [DataTransmissionSetup]
  return $ret
}

# ***************************************************************************
# PS_DataTransmission_run
# ***************************************************************************
proc PS_DataTransmission_run {run} {
  global gaSet buffer
  set com $gaSet(comDut) 

  Power all off
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ps=="WDC"} {
    set ps_voltage "24V"
  } elseif {$ps=="DC"} {
    set ps_voltage "48V"
  } else {
    set ps_voltage "AC"
  }
  
  if {$ps=="WDC"} {
    RLSound::Play information
    ## don't check PS2 since it's reference
    #set txt "Connect $ps_voltage cables to ETX"
    set txt "Connect $ps_voltage cable to PS-1"
    set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Connect power cable" -message $txt]
    if {$res=="Stop"} {
      return -2
    }
  }
  set ret 0  
  
  ## don't check PS2 since it's reference
  #foreach ps {1 2} {}
  foreach ps {1} {
    Power all off
    after 3000
    Power $ps on
    set ret [Wait "Wait for Power ON" 30]
    if {$ret!=0} {return $ret}
    set ret [Login]
    if {$ret!=0} {
      #set ret [Login]
      if {$ret!=0} {return $ret}
    } 
    #set ret [Wait "Wait for ETX stabilization" 60]
    #if {$ret!=0} {return $ret}
    set ret [DataTransmission_run $run]
    if {$ret!=0} {
      set ret [Wait "Wait for ETX stabilization" 60]
      if {$ret!=0} {return $ret}
      set ret [DataTransmission_run $run]
      if {$ret!=0} {return $ret}   
    }
  }
  
  return $ret
}