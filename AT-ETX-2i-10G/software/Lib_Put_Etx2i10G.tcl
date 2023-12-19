# ***************************************************************************
# EntryBootMenu 
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] EntryBootMenu"; update
  set ret [Send $com \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $com \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $com \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
#   set ret [Reset2BootMenu $uut]
#   if {$ret!=0} {return $ret}
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  Power all off
  RLTime::Delay 2
  Power all on
  RLTime::Delay 2
  Status "Entry to Boot Menu"
  set gaSet(fail) "Entry to Boot Menu fail"
  set ret [Send $com \r "stop auto-boot.." 20]
  if {[string match {*HW Failure*} $buffer]} {
    set gaSet(fail) "HW Failure"
  } 
  if {[string match {*DEADBEEF Program Check Exception*} $buffer]} {
    set gaSet(fail) "DEADBEEF Program Check Exception"
  } 
  if {$ret!=0} {return $ret}
  set ret [Send $com \r\r "\[boot\]:"]
  if {[string match {*HW Failure*} $buffer]} {
    set gaSet(fail) "HW Failure"
  }
  if {$ret!=0} {return $ret}
  return 0
}

# ***************************************************************************
# DownloadUsbPortApp
# ***************************************************************************
proc DownloadUsbPortApp  {} { 
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] DownloadUsbPortApp"; update
  set gaSet(fail) "Config IP in Boot Menu fail"
  set ret [Send $com "c ip\r" "(ip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "10.10.10.1$gaSet(pair)\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
    
  set gaSet(fail) "Config DM in Boot Menu fail"
  set ret [Send $com "c dm\r" "(dm)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "255.255.255.0\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config SIP in Boot Menu fail"
  set ret [Send $com "c sip\r" "(sip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config GW in Boot Menu fail"
  set ret [Send $com "c g\r" "(g)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config TFTP in Boot Menu fail"
  set ret [Send $com "c p\r" "ftp\]"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "ftp\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "\r" "\[boot\]:"]
  if {$ret!=0} {return $ret} 
  
  set ret [Send $com "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Start \'download 3,sw-pack_2i_USB_test.bin\' fail"
  set ret [Send $com "download 3,sw-pack_2i_USB_test.bin\r" "transferring" 3]
  if [string match {*you sure(y/n)*} $buffer] {
    set ret [Send $com "y\r" "transferring"]    
  }
  if {$ret!=0} {return $ret} 
  
  set startSec [clock seconds]
  while 1 {
    Status "Wait for application downloading"
    if {$gaSet(act)==0} {return -2}
    set nowSec [clock seconds]
    set dwnlSec [expr {$nowSec - $startSec}]
    #puts "dwnlSec:$dwnlSec"
    $gaSet(runTime) configure -text $dwnlSec
    if {$dwnlSec>600} {
      set ret -1 
      break
    }
    set ret [RLSerial::Waitfor $com buffer "\[boot\]:" 2]
    ##set ret [RLCom::Waitfor $gaSet(comDut) buffer "\[boot\]:" 2]
    puts "<$dwnlSec><$buffer>" ; update
    if {$ret==0} {break}
    if [string match {*\[boot\]*} $buffer] {
      set ret 0
      break
    }
  }  
  if {$ret=="-1"} {
    set gaSet(fail) "Download \'3,sw-pack_2i_usb.bin\' fail"
    return -1 
  }
  
  set gaSet(fail) "\'set-active 3\' fail" 
  set ret [Send $com "\r" "\[boot\]:" 1]
  set ret [Send $com "\r" "\[boot\]:" 1]
  set ret [Send $com "set-active 3\r" "\[boot\]:" 25]
  if {$ret!=0} {return $ret}  
  Status "Wait for Loading/un-compressing sw-pack-3"
  set ret [Send $com "run 3\r" "sw-pack-3.." 50]
  if {$ret!=0} {return $ret} 
          
  return 0
}  
# ***************************************************************************
# CheckUsbPort
# ***************************************************************************
proc CheckUsbPort {} {
  puts "[MyTime] CheckUsbPort"; update
  global gaSet buffer accBuffer
  
 ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app 
#   set startSec [clock seconds]
#   while 1 {
#     if {$gaSet(act)==0} {return -2}
#     set nowSec [clock seconds]
#     set dwnlSec [expr {$nowSec - $startSec}]
#     #puts "dwnlSec:$dwnlSec"
#     $gaSet(runTime) configure -text $dwnlSec
#     update
#     if {$dwnlSec>120} {
#       set ret -1 
#       break
#     }
#     set ret [RLSerial::Waitfor $gaSet(comDut) buffer "user>" 2]
#     append accBuffer [regsub -all {\s+} $buffer " "]
#     $gaSet(runTime) configure -text $dwnlSec
#     puts "<$dwnlSec><$buffer>" ; update
#     if {$ret==0} {break}
#     if [string match {*user>*} $buffer] {
#       set ret 0
#       break
#     }
#   }  
#   if {$ret=="-1"} {
#     set gaSet(fail) "Getting \'user>\' fail"
#     return -1 
#   }
#   
# #   if [string match {*A device is connected to Bus:000 Port:0*} $accBuffer] {
# #     set ret 0
# #   } else {
# #     set ret -1
# #     set gaSet(fail) "USB port doesn't recognize device on Bus:000 Port:0"
# #   }
#   #set ret [Send $gaSet(comDut) "run 3\r" "sw-pack-3.." 15]
#   
  Status "USB port Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read USB port"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read USB port fail"
  set ret [Send $com "debug usb display-device-param\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  
  if {[string match {*USB device in*} $buffer]} {
    set ret 0
  } else {
    set ret -1
    set gaSet(fail) "USB port doesn't recognize an USB device"
  }        
  return $ret
}  
# ***************************************************************************
# DeleteUsbPortApp
# ***************************************************************************
proc DeleteUsbPortApp {} { 
  puts "[MyTime] DeleteUsbPortApp"; update
  global gaSet buffer
  set com $gaSet(comDut)
  set gaSet(fail) "Delete UsbPort App fail"
  set ret [Send $com "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  set ret [Send $com "run\r" "sw-pack-1.." 55]
  if {$ret!=0} {return $ret} 
  return $ret
}  

# ***************************************************************************
# PS_IDTest
# ***************************************************************************
proc PS_IDTest {} {
  global gaSet buffer
  Status "PS_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  
  set ret [ReadP1015Code]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "\r" $gaSet(prompt)]
  set prompt $buffer
  set dutFullName $gaSet(DutFullName)  
  puts "prompt:<$prompt> dutFullName:<$dutFullName>\n"; update
  if {([string match *-B* $prompt]  &&  [string match *-B* $dutFullName]) || \
      (![string match *-B* $prompt] && ![string match *-B* $dutFullName]) || \
      ([string match *RAD_ZTP* $prompt]  &&  [string match *-B_VO* $dutFullName])} {
        ## both promt and dutFullName have or haven't -B, it is OK
  } else {
    set gaSet(fail) "Mismatch between UUT's Prompt ($prompt) and Barcode ($dutFullName)" 
    return -1
  }  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$np=="8SFPP" && $up=="0_0"} { 
    set dut10GB   [string match {*10G-B*} $gaSet(DutInitName)]
    set prmpt10GB [string match {*10G-B*} $buffer)]
    puts "PS_IDTest dut10GB:<$dut10GB> prmpt10GB:<$prmpt10GB>"
    AddToPairLog $gaSet(pair) "$gaSet(DutInitName), $buffer"
    if {$dut10GB!=$prmpt10GB} {
      set gaset(fail) "Mismatch between UUT's Name and Prompt" 
      return -1
    }
  }
  
  if {[string match *.DDC.* $gaSet(DutInitName)]} {
    foreach psOff {1 2} psOn {2 1} {
      Power $psOff off
      after 2000
      set ret [Send $com "exit all\r" $gaSet(prompt)]
      if {$ret!=0} {
        set gaSet(fail) "UUT doesn't respond when only Power of Inlet-$psOn is ON"
        return $ret
      }
      Power $psOff on
      after 2000
    }  
  }
#   set ret [Send $com "info\r" more 80]  
#   regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  set ret [Send $com "le\r" $gaSet(prompt)]  
  regexp {sw\s+\"([\.\d\(\)\w]+)\"\s} $buffer - sw
  
  if ![info exists sw] {
    set gaSet(fail) "Can't read the SW version"
    return -1
  }
  puts "sw:$sw"
    
#   set ret [Send $com "\3" ETX-2I 0.25]
#   if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" Celsius]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ps eq "noPS"} {
    set ps AC
    set psQty [regexp -all $ps $buffer]
  } elseif {$ps=="ACDC"} {
    set acQty [set dcQty [set psQty 0]]
    incr psQty [set acQty [regexp -all AC $buffer]]
    incr psQty [set dcQty [regexp -all DC $buffer]]
    puts "\nPS_IDTest psQty:<$psQty> acQty:<$acQty> dcQty:<$dcQty>"
    if {$acQty!=1 || $dcQty!=1} {
      set gaSet(fail) "Qty or type of PSs is wrong."
      return -1
    }
  } else {
    if {$gaSet(rbTestMode) eq "MainBoard"} {
      set ps AC
    }  
    set psQty [regexp -all $ps $buffer]
  }
  if {$b=="19" || $b=="19B"} {
    set psQtyShBe 2
  } elseif {$b=="Half19" || $b=="Half19B"} {
    set psQtyShBe 1
  }
  
  puts "PS_IDTest b:$b psQty:$psQty psQtyShBe:$psQtyShBe"
  if {$psQty!=$psQtyShBe} {
    set gaSet(fail) "Qty or type of PSs is wrong."
    return -1
  }
  regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
  if {$b=="Half19" || $b=="Half19B"} {
    regexp {1\s+\w+\s+([\s\w]+)\s+FAN} $psStatus - ps1Status
  } elseif {$b=="19" || $b=="19B"} { 
    regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
    if [string match *24VR* $gaSet(DutInitName)] { 
      regexp {1\s+24 VDC\s+([\s\w]+)\s+2 } $psStatus - ps1Status
    }
  }
  set ps1Status [string trim $ps1Status]
         
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
    return -1
  }
  
  if {$b=="19" || $b=="19B"} {
    regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
    if [string match *24VR* $gaSet(DutInitName)] { 
      regexp {2\s+24 VDC\s+([\s\w]+)\s+} $psStatus - ps2Status
    }
    set ps2Status [string trim $ps2Status]
    if {$ps2Status!="OK"} {
      set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
      return -1
    }    
  }
  
  set res [regexp {(\d+)\s+Celsius} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Can't read the Sensor's Value"
    return -1
  }
  puts "Read Sensor Value ma:<$ma> val:<$val>"
  if {$val==0} {
    set gaSet(fail) "Sensor's Value is 0"
    return -1
  }
  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
#   if {[string range $sw end-1 end]=="SR" && $r=="R"} {
#     set gaSet(fail) "The sw is \"$sw\" and the DUT is RTR"
#     return -1
#   }
#   if {[string range $sw end-1 end]!="SR" && $r=="0"} {
#     set gaSet(fail) "The sw is \"$sw\" and the DUT is not RTR"
#     return -1
#   }
  
  if {[string range $sw end-1 end]=="SR"} {
    puts "sw:$sw"
    set sw [string range $sw 0 end-2]  
    puts "sw:$sw"
  }
  puts gaSet(dbrSW):<$gaSet(dbrSW)>
  if {$gaSet(dbrSW)==""} {
    set ret [GetDbrSWAgain]
    if {$ret!=0} {return $ret}
  }
  
  if {$sw!=$gaSet(dbrSW)} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
    return -1
  }
  
  ## 09:15 06/03/2022
  ## CLE and  new SN test
  
  set gaSet(fail) "show device-information fail"
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "config system\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  Send $com "show device-information\r\r" system
  puts "buffer:<$buffer>"; update
  set res [regexp {Manufacturer Serial Number[\s\:]+([\w\s]+)\sConnectors} $buffer ma val]
  puts "Manufacturer Serial Number res:$res ma:$ma val:$val"
    
  set sw_norm [join  [regsub -all {[\(\)A-Z]} $sw " "]  . ] ; # 6.8.5(1.27T5) -> 6.8.5.1.27T5
  puts "DutInitName:<$gaSet(DutInitName)> sw:<$sw> sw_norm:<$sw_norm>"; update
  if {([string match {*ATT*} $gaSet(DutInitName)]           || \
       [string match {*_C.*} $gaSet(DutInitName)]           || \
       [string match {*_BRSD.*} $gaSet(DutInitName)]        || \
       [string match {*_VO.*} $gaSet(DutInitName)]          || \
       [string match {ETX-2I-10G_LY.*} $gaSet(DutInitName)] || \
       [string match {ETX-2I-10G-B_LY.*} $gaSet(DutInitName)]) && \
       [package vcompare $sw_norm 6.7.1.0.15]!="-1"} {
    ## if sw_norm >=6.7.1.0.15
    
    if {$res==0} {
      set gaSet(fail) "No \'Manufacturer Serial Number\' field"  
      return -1
    }
    if {$val=="Unavailable" || $val=="Error" || $val=="Not Available"} {
      set gaSet(fail) "The \'Manufacturer Serial Number\' is \'$val\'"  
      return -1
    }
    set man_sn_len [string length $val]
    if [string match {*ATT*} $gaSet(DutInitName)] {
      if {[package vcompare $sw_norm 6.8.2.1.43]!="-1"} {
        ## if sw_norm >=6.8.2.1.43
        set max_sn_len 10
      } else {
        set max_sn_len 16
      } 
    } 
    if {[string match {*_C.*} $gaSet(DutInitName)] || [string match {*_BRSD.*} $gaSet(DutInitName)]} {
      if {[package vcompare $sw_norm 6.8.2.0.52]!="-1"} {
        ## if sw_norm >=6.8.2.0.52
        set max_sn_len 10
      } else {
        set max_sn_len 16
      } 
    }    
    if [string match {*_VO.*} $gaSet(DutInitName)] {
      if {[package vcompare $sw_norm 6.8.2.0.75]!="-1"} {
        ## if sw_norm >=6.8.2.0.75
        set max_sn_len 10
      } else {
        set max_sn_len 16
      } 
    }    
    
    if {$man_sn_len!=$max_sn_len} {
      set gaSet(fail) "The length of the \'Serial Number\' is $man_sn_len. Should be $max_sn_len"  
      return -1
    }
    if {[string is digit $val]==0} {
      set gaSet(fail) "The \'Serial Number\' ($val) is wrong. Should be only digits"  
      return -1
    }
    AddToPairLog $gaSet(pair) "Manufacturer Serial Number: $val"
    
    if {([string match {*ATT*} $gaSet(DutInitName)] || \
         [string match {*_C.*} $gaSet(DutInitName)] || \
         [string match {*_BRSD.*} $gaSet(DutInitName)]) &&\
        [package vcompare $sw_norm 6.8.2.0.33]!="-1"} {
      ## if sw_norm >=6.8.2.0.33
      set res [regexp {CLEI Code[\s\:]+([\w]+)\s} $buffer ma val]
      puts "CLEI Code res:$res ma:$ma val:$val"
      if {$res==0} {
        set gaSet(fail) "No \'CLEI Code\' field"  
        return -1
      }
      if {$val=="Unavailable" || $val=="Error"} {
        set gaSet(fail) "The \'CLEI Code\' is \'$val\'"  
        return -1
      }
      set clei_len [string length $val]
      if {$clei_len!=10} {
        set gaSet(fail) "The length of the \'CLEI Code\' is $clei_len. Should be 10"  
        return -1
      }
      
      ## 08:45 20/04/2023
      if {[lsearch $gaSet(CleiCodesL) $gaSet(DutFullName)]=="-1"} {
        set gaSet(fail) "The \'$gaSet(DutFullName)\' doesn't exist in CleiCodes.txt"  
        return -1
      }
      set tblClei [lindex $gaSet(CleiCodesL) [expr {1 + [lsearch $gaSet(CleiCodesL) $gaSet(DutFullName)]}]]
      puts "\n DutFullName:<$gaSet(DutFullName)> tblClei:<$tblClei> Clei:<$val>"
      if {$val != $tblClei} {
        set gaSet(fail) "The \'CLEI Code\' is $val. Should be $tblClei"  
        return -1
      }
      
      AddToPairLog $gaSet(pair) "CLEI Code: $val"
    } else {
      puts "No ATT or sw < 6.8.2(0.33)"
    }
  } else {
    puts "No ATT or sw < 6.8.2(0.32)"
    if {[string match {*ATT*} $gaSet(DutInitName)]==0 && \
        [string match {*_C.*} $gaSet(DutInitName)]==0 && \
        [string match {*_BRSD.*} $gaSet(DutInitName)]==0} {
      if {$res==0} {
        puts "No ATT and no Lumen, No \'Manufacturer Serial Number\' field"          
      } else {
        puts "No ATT and no Lumen, Manufacturer Serial Number: $val"
        AddToPairLog $gaSet(pair) "Manufacturer Serial Number: $val"        
        if {$val=="Unavailable" || $val=="Error" || $val=="Not Available"} {
          set ret 0 
        } else {
          set gaSet(fail) "The \'Manufacturer Serial Number\' is \'$val\'"  
          return -1
        }
      }
    }
  }
    
#   set ret [ReadCPLD]
#   if {$ret!=0} {return $ret}
  
  if {![info exists gaSet(uutBootVers)] || $gaSet(uutBootVers)==""} {
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin reboot\r" "yes/no"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "seconds" 20]
    if {$ret!=0} {return $ret}
    set ret [ReadBootVersion noWD]
    if {$ret!=0} {return $ret}
  }
  
  puts "gaSet(uutBootVers):<$gaSet(uutBootVers)>"
  puts "gaSet(dbrBVer):<$gaSet(dbrBVer)>"
  if {[string index $gaSet(dbrBVer) 0]=="B"} {
    set gaSet(dbrBVer) [string range $gaSet(dbrBVer) 1 end]
    puts "gaSet(dbrBVer):<$gaSet(dbrBVer)>"
  }
  update
  if {$gaSet(uutBootVers)!=$gaSet(dbrBVer)} {
    set gaSet(fail) "Boot Version is \"$gaSet(uutBootVers)\". Should be \"$gaSet(dbrBVer)\""
    return -1
  }
  set gaSet(uutBootVers) ""
  
  return $ret
}
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
   
  set wsDir C:\\Program\ Files\\Wireshark
  set npfL [exec $wsDir\\tshark.exe -D]
  ## 1. \Device\NPF_{3EEEE372-9D9D-4D45-A844-AEA458091064} (ATE net)
  ## 2. \Device\NPF_{6FBA68CE-DA95-496D-83EA-B43C271C7A28} (RAD net)
  set intf ""
  foreach npf [split $npfL "\n\r"] {
    set res [regexp {(\d)\..*ATE} $npf - intf] ; puts "<$res> <$npf> <$intf>"
    if {$res==1} {break}
  }
  if {$res==0} {
    set gaSet(fail) "Get ATE net's Network Interface fail"
    return -1
  }
  
  if {$gaSet(pair)==5} {
    set dutIp 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set dutIp 10.10.10.111
    } else {
      set dutIp 10.10.10.1[set gaSet(pair)]
    }  
  }
  
  set ret [PingTraps $intf $dutIp]
  if {$ret=="-1"} {
    set ret [Wait "Wait Management up" 20 white]
    if {$ret!=0} {return $ret}
    set ret [PingTraps $intf $dutIp]
    if {$ret!=0} {return $ret}
  }

  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
  set ret [Dyigasp_ClearLog]
  if {$ret!=0} {return $ret}
  
  Power $psOffOn on
  Power $psOff off
  
  Status "Wait for Dying Gasp trap"
  set dur 10
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile snmp &  
     
  after 1000
  Power $psOffOn off
  after 1000
  Power $psOffOn on
  
  after "[expr {$dur +1}]000" ; ## one more sec then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\rMonData---<$monData>---\r"; update
  
  
  ## 4479696e672067617370
  ## D y i n g   g a s p
  #set framsL [regexp -all -inline "Src: $dutIp.+?\\n\\n\\n" $monData]
  #set framsL [split $monData %]
  set framsL [wsplit $monData lIsT]
  if {[llength $framsL]==0} {
    set gaSet(fail) "No frame from $dutIp was detected"
    return -1
  }
  puts "\rDying gasp == 4479696e672067617370\r"; update
  set res 0
  foreach fram $framsL {
    puts "\rFrameA---<$fram>---\r"; update
    if {[string match "*Src: $dutIp*" $fram] && ([string match *4479696e672067617370* $fram] || [string match {*Dying gasp*} $fram])} {
      set res 1
      #file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }

  if {$res==1} {
    set ret [Wait "Wait UUT up" 30 white]
    if {$ret!=0} {return $ret}
    set ret [Dyigasp_ReadLog]
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret  
}

# ***************************************************************************
# DateTime_Test
# ***************************************************************************
proc DateTime_Test {} {
  global gaSet buffer
  Status "DateTime_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" >system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show system-date\r" >system]
  if {$ret!=0} {return $ret}
  
  regexp {date\s+([\d-]+)\s+([\d:]+)\s} $buffer - dutDate dutTime
  
  set dutTimeSec [clock scan $dutTime]
  set pcSec [clock seconds]
  set delta [expr abs([expr {$pcSec - $dutTimeSec}])]
  if {$delta>300} {
    set gaSet(fail) "Difference between PC and the DUT is more then 5 minutes ($delta)"
    set ret -1
  } else {
    set ret 0
  }
  
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    if {$pcDate!=$dutDate} {
      set gaSet(fail) "Date of the DUT is \"$dutDate\". Should be \"$pcDate\""
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
}

# ***************************************************************************
# DataTransmissionSetup
# ***************************************************************************
proc DataTransmissionSetup {} {
  global gaSet
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set ret [MirpesetStat]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
    
  return $ret
}

# ***************************************************************************
# ExtClkTest
# ***************************************************************************
proc ExtClkTest {mode} {
  puts "[MyTime] ExtClkTest $mode"
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
#   set ret [Send $com "configure system clock station 1/1\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   set ret [Send $com "shutdown\r" "(1/1)"]
#   if {$ret!=0} {return $ret}
#   Send $com "exit all\r" stam 0.25 
  
  if {$mode=="Unlocked"} {
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set clkSrc [set state ""]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
    if {$clkSrc!="0" && $state!="Freerun"} {
      set gaSet(fail) "$syst"
      return -1
    }
  }
 
 if {$mode=="Locked"} {
    set cf $gaSet(ExtClkCF) 
    set cfTxt "EXT CLK"
    set ret [DownloadConfFile $cf $cfTxt 0 $com]
    if {$ret!=0} {return $ret}
    
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure system clock station 1/1\r" "station"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "shutdown\r" "station"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "line-code hdb3\r" "station"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no shutdown\r" "station"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    
    set ret [Send $com "configure system clock\r" ">clock"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "domain 1\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    for {set i 1} {$i<=20} {incr i} {
      puts "ExtClock wait for Locked i:$i" ; update
      set ret [Send $com "show status\r" "domain(1)"]
      if {$ret!=0} {return $ret} 
      set syst [set clkSrc [set state ""]]
      regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s} $buffer syst clkSrc state
      if {$clkSrc=="1" && $state=="Locked"} {
        set ret 0
        break
      } else {      
        set ret -1
        after 1000
      }
    }
    if {$ret=="-1"} {
      set gaSet(fail) "$syst"
    } elseif {$ret=="0"} {
      set ret [Send $com "no source 1\r" "domain(1)"]
      if {$ret!=0} {return $ret}
    }
  }
  return $ret
}

# ***************************************************************************
# TstAlm 
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# ReadMac
# ***************************************************************************
proc ReadMac {} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure system\r" ">system"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "show device-information\r" ">system"]
  if {$ret!=0} {return $ret}
  
  set mac 00-00-00-00-00-00
  set res [regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac]
  if {$res eq 0} {
    set ret [Send $com "show device-information\r" ">system"]
    if {$ret!=0} {return $ret}
  }
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  set mac2 0x$mac1
  puts "mac1:$mac1" ; update
  if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {
    Send $com "exit all\r" stam 0.25
    set ret [Send $com "configure system\r" ">system"]
    if {$ret!=0} {return $ret} 
    set ret [Send $com "show device-information\r" ">system"]
    if {$ret!=0} {return $ret}
    set mac 00-00-00-00-00-00
    set res [regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac]
    if {$res eq 0} {
      set ret [Send $com "show device-information\r" ">system"]
      if {$ret!=0} {return $ret}
    }
    if [string match *:* $mac] {
      set mac [join [split $mac :] ""]
    }
    set mac1 [join [split $mac -] ""]
    set mac2 0x$mac1
    puts "mac1:$mac1" ; update
    
    if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF )} {  
      RLSound::Play fail
      set gaSet(fail) "The MAC of UUT is $mac"
      set ret [DialogBox -type "Terminate Continue" -icon /images/error -title "MAC check"\
          -text $gaSet(fail) -aspect 2000]
      if {$ret=="Terminate"} {
        return -1
      }
    }  
  }
  set gaSet(${::pair}.mac1) $mac1
  
  return 0
}
# ***************************************************************************
# ReadPortMac
# ***************************************************************************
proc ReadPortMac {port} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Read MAC of port $port fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25
  set ret [Send $com "configure port\r" "port"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show status\r" "($port)"]
  if {$ret!=0} {return $ret}
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
  if [string match *:* $mac] {
    set mac [join [split $mac :] ""]
  }
  set mac1 [join [split $mac -] ""]
  return $mac1
}

#***************************************************************************
#**  Login
#***************************************************************************
proc Login {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set com $gaSet(comDut)
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
#   set ret [MyWaitFor $com {ETX-2I user>} 5 1]
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  puts "login lo:A01 ret:<$ret>" ; update
  if {[string match {*Are you sure?*} $buffer]==1} {
    Send $com n\r stam 1
    append gaSet(loginBuffer) "$buffer"
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
    puts "login lo:A02 ret:<$ret>" ; update
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r -2I
    append gaSet(loginBuffer) "$buffer"
    puts "login lo:A03 ret:<$ret>" ; update
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r -2I
    puts "login lo:A04 ret:<$ret>" ; update
  }
  if {[string match *-2I* $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    puts "login lo:A05 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ETX-2i* $buffer]} {
    set gaSet(prompt) "ETX-2i"
    set ret 0
    puts "login lo:A06 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ztp* $buffer]} {
    set ret 0
    set gaSet(prompt) "ztp"
    puts "login lo:A07 ret:<$ret>" ; update
    return 0
  }
  if {[string match *ZTP* $buffer]} {
    set ret 0
    set gaSet(prompt) "ZTP"
    puts "login lo:A07.1 ret:<$ret>" ; update
    return 0
  }
  if {[string match *CUST-LAB* $buffer]} {
    set ret 0
    set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
    puts "login lo:A08 ret:<$ret>" ; update
    return 0
  }
  if {[string match *WallGarden_TYPE-5* $buffer]} {
    set ret 0
    set gaSet(prompt) "WallGarden_TYPE-5"
    puts "login lo:A09 ret:<$ret>" ; update
    return 0
  }
  if {[string match *BOOTSTRAP-2I10G* $buffer]} {
    set ret 0
    set gaSet(prompt) "BOOTSTRAP-2I10G"
    puts "login lo:A0A ret:<$ret>" ; update
    return 0
  }
  if {[string match *RAD_ZTP* $buffer]} {
    set ret 0
    set gaSet(prompt) "RAD_ZTP"
    puts "login lo:A0B ret:<$ret>" ; update
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    puts "login lo:A0C ret:<$ret>" ; update
    return 0
  } 
  if {[string match *2i10G-COV-* $buffer]} {
    set ret 0
    set gaSet(prompt) "2i10G-COV-"
    puts "login lo:A0D ret:<$ret>" ; update
    return 0
  }
  if {[string match *user>* $buffer]} {
    Send $com su\r stam 0.25
    puts "login user1 prmpt:<$gaSet(prompt)>"
    set ret [Send $com 1234\r $gaSet(prompt)]
    if {[string match *ETX-2i* $buffer]} {
      set gaSet(prompt) "ETX-2i"
      set ret 0
      puts "login lo:B01 ret:<$ret>" ; update
    }
    $gaSet(runTime) configure -text ""
    #set gaSet(prompt) "ETX-2I"
    puts "login user2 prmpt:<$gaSet(prompt)> ret:<$ret>"
    if {$ret=="-1"} {
      set gaSet(fail) "Login failed"
    }
    return $ret
  }
  if {$ret!=0} {
    #set ret [Wait "Wait for ETX up" 20 white]
    #if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 64} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into ETX-2I"
    puts "Login into ETX-2I i:$i"; update
    $gaSet(runTime) configure -text $i; update
    Send $com \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX's up"  
        return -1
      } else {
        # 08:33 25/07/2022 puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1 || [string match {*user>*} $buffer]==1 || \
        [string match {*-2i*} $buffer]==1) && ([string match {*Device*} $buffer]==0)} {      
      puts "if1 <$buffer>"
      set ret 0
      puts "login lo:C01 ret:<$ret>" ; update
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
      append gaSet(loginBuffer) "$buffer"
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r -2I
      puts "login lo:C02 0" ; update
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      puts "login lo:C02 ret:<$ret>" ; update
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user>* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "2I" 3]
      if {[string match *220* $buffer]} {
        set gaSet(prompt) "ETX-220"
        set ret 0
        puts "login lo:C04 ret:<$ret>" ; update
      }
      if {[string match *203* $buffer]} {
        set gaSet(prompt) "ETX-203"
        set ret 0
        puts "login lo:C05 ret:<$ret>" ; update
      }
      if {[string match *ztp* $buffer]} {
        set gaSet(prompt) "ztp"
        set ret 0
        puts "login lo:C06 ret:<$ret>" ; update
      }
      if {[string match *ETX-2I* $buffer]} {
        set gaSet(prompt) "ETX-2I"
        set ret 0
        puts "login lo:C07 ret:<$ret>" ; update
      }
      if {[string match *CUST-LAB* $buffer]} {
        set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        set ret 0
        puts "login lo:C08 ret:<$ret>" ; update
      }
      if {[string match *WallGarden_TYPE-5* $buffer]} {
        set gaSet(prompt) "WallGarden_TYPE-5"
        set ret 0
        puts "login lo:C09 ret:<$ret>" ; update
      }
      if {[string match *BOOTSTRAP-2I10G* $buffer]} {
        set gaSet(prompt) "BOOTSTRAP-2I10G"
        set ret 0
        puts "login lo:C0A ret:<$ret>" ; update
      } 
      if {[string match *ETX-2i* $buffer]} {
        set gaSet(prompt) "ETX-2i"
        set ret 0
        puts "login lo:C0B ret:<$ret>" ; update
      }    
      if {[string match *RAD_ZTP* $buffer]} {
        set ret 0
        set gaSet(prompt) "RAD_ZTP"
        puts "login lo:C0C ret:<$ret>" ; update
      }
      if {[string match *2i10G-COV-* $buffer]} {
        set ret 0
        set gaSet(prompt) "2i10G-COV-"
        puts "login lo:C0D ret:<$ret>" ; update
      }
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2I Fail"
  }
  puts "login lo:D00 ret:<$ret>" ; update
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}

# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode wdMode} {
  global gaSet buffer 
  Status "FactDefault $mode $wdMode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  
  Send $com "exit all\r" stam 0.25 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {set gaSet(fail) "Set to Default fail"; return $ret}
  #set ret [Send $com "y" "stam" 1]
  set ret [Send $com "y\r\r" "seconds" 20]
  if {$ret!=0} {set gaSet(fail) "Set to Default fail"; return $ret}
  
  set ret [ReadBootVersion $wdMode]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait DUT up" 20 white]
  if {$ret!=0} {return $ret} 
  
  set ret [Login]
  if {$ret!=0} {return $ret} 
  
  return $ret
}
# ***************************************************************************
# LicensePerf
# ***************************************************************************
proc LicensePerf {licMode} {
  global gaSet buffer 
  Status "LicensePerf $licMode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  
  set gaSet(fail) "Logon fail"
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "$licMode SFPP license"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }     
  
  set sw $gaSet(dbrSW) ; # 6.2.1(0.44)
  set majSW [string range $sw 0 [expr {[string first ( $sw] - 1}]]; # 6.2.1
  puts "sw:$sw majSW:$majSW"
  
  set gaSet(fail) "$licMode 4SFPP license fail"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "admin license\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  if {$majSW<6.4} {
    puts "majSW1:$majSW"
    if {$licMode=="Open"} {
      set ret [Send $com "license-enable four-sfp-plus-ports\r" $gaSet(prompt)] 
    } elseif {$licMode=="Close"} {
      set ret [Send $com "no license-enable four-sfp-plus-ports\r" $gaSet(prompt)] 
    }  
    puts "majSW1:$majSW ret:<$ret>"
  } else {
    puts "majSW2:$majSW"
    if {$licMode=="Open"} {
      set ret [Send $com "show summary\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      if {$np=="8SFPP" && $up=="0_0"} {
        ## 20/10/2020 10:04:05 NO license IN 8SFPP 
      } else {
        if {[string match {*Enabled 4 4*} $buffer] == 1 } {
          ## 4 port are open, don't open license
          set ret 0
        } else {
          set ret [Send $com "license-enable sfp-plus-factory-10g-rate 4\r" $gaSet(prompt)]
        } 
      }
      puts "majSW2:$majSW ret:<$ret>"
    } elseif {$licMode=="Close"} {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      set ret [Send $com "configure port\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      if {$np=="8SFPP" && $up=="0_0"} {
        set etPoL {0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8}
      } else {
        set etPoL {0/1 0/2 0/3 0/4}
      }
      foreach etPo $etPoL {
        set ret [Send $com "eth $etPo\r" $gaSet(prompt)]
        if {$ret!=0} {return $ret}
        set ret [Send $com "speed-duplex 1000-full-duplex\r" $gaSet(prompt)]
        if {$ret!=0} {return $ret}
        set ret [Send $com "exit\r" $gaSet(prompt)]
        if {$ret!=0} {return $ret}
      }
      set ret [Send $com "exit all\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      set ret [Send $com "admin license\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      set ret [Send $com "no license-enable sfp-plus-factory-10g-rate\r" $gaSet(prompt)] 
    }
  }
  puts "majSW3:$majSW ret:<$ret>"
  if {$ret!=0} {return $ret}
  if {[string match {*cli error*} $buffer]} {
    set gaSet(fail) "Configuration License fail. CLI error"
    return -1
  }
  set ret [Send $com "show summary\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  
  ## if the order is without SFPP - no need open them after close
  ## if the order for 2 SFPP - we will open them  them after close
  if {$licMode=="Close" && $np=="2SFPP"} {
    if {$majSW<6.4} {
      set ret [Send $com "license-enable four-sfp-plus-ports\r" $gaSet(prompt)] 
    } else {
      set ret [Send $com "license-enable sfp-plus-factory-10g-rate 2\r" $gaSet(prompt)] 
    }
    if {$ret!=0} {return $ret}
    set ret [Send $com "show summary\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
  }  
  if {$licMode=="Close"} {  
    ## and factory reset to activate the license
    set ret [FactDefault std noWD]
    if {$ret!=0} {return $ret}
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin license\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show summary\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    if {$majSW<6.4} {
      set res [regexp {SFP\+ Ethernet Ports\s+(\w+)\s+([\-\d\w]+) } $buffer m stat inUse]
    } else {
      set res [regexp {SFP\+ Factory 10G Rate (\w+)\s+([\-\d]+) [\-\d]+ } $buffer m stat inUse]
    }
    if {$res=="0"} {
      set gaSet(fail) "Read SFP+ Factory 10G Rate fail"
      return -1
    }
    puts "stat:<$stat> inUse:<$inUse>"  
    if {$np=="2SFPP"} {
      if {$majSW<6.4} {
        if {$stat!="Enabled" || $inUse!="No"} {
          set gaSet(fail) "Open license for 2SFP+ fail"
          return -1 
        }
      } else {
        if {$stat!="Enabled" || $inUse!="2"} {
          set gaSet(fail) "Open license for 2SFP+ fail"
          return -1 
        }  
      }
    } elseif {$np=="npo" && ($stat!="Disabled" || $inUse!="-")} {
      set gaSet(fail) "Close license for no SFP+ fail"
      return -1 
    }
  } ; # end of if Close
  
  return $ret
}
# ***************************************************************************
# ReadBootVersion
# ***************************************************************************
proc ReadBootVersion {wdMode} {
  global gaSet buffer
  puts "ReadBootVersion $wdMode"
  set com $gaSet(comDut)
  set ::buff ""
  set gaSet(uutBootVers) ""
  set ret -1
  for {set sec 1} {$sec<20} {incr sec} {
    if {$gaSet(act)==0} {return -2}
    RLSerial::Waitfor $com buffer xxx 1
    ##RLCom::Waitfor $com buffer xxx 1
    puts "sec:$sec buffer:<$buffer>" ; update
    append ::buff $buffer
    if {[string match {*to view available commands*} $::buff]==1 || \
        [string match {*available commands*} $::buff]==1 || \
        [string match {*to view available*} $::buff]==1} {      
      set ret 0
      break
    }
  }
  if {$ret!=0} {
    set gaSet(fail) "Can't read the boot"
    return $ret
  }
  set res [regexp {Boot version:\s([\d\.\(\)]+)\s} $::buff - value]
  if {$res==0} {
    set gaSet(fail) "Can't read the Boot version"
    return -1
  } else {
    set gaSet(uutBootVers) $value
    puts "gaSet(uutBootVers):$gaSet(uutBootVers)"
    set ret 0
  }
  
  if {$wdMode=="wd"} {
    set ret [EntryBootMenu]
    if {$ret!=0} {
      set gaSet(fail) "Can't entry into the boot"
      return $ret
    }
    
    Send $com "d2 00\r" boot 2
    regexp {Page 3:\s+([0-9\.A-Z]+)\s} $buffer ma val
    set pageBarcode ""
    foreach he [lrange [split $val .] 2 12] {
      append pageBarcode [format %c [scan $he %x]]
    }
    set guiBarcode [string range $gaSet(1.barcode1) 0 10]
    puts "ReadBootVersion pageBarcode:<$pageBarcode> guiBarcode:<$guiBarcode>"
    if {$pageBarcode != $guiBarcode} {
      set gaSet(fail) "Mismatch between Page3 and scanned Barcodes" 
      AddToPairLog $gaSet(pair) "Mismatch between Page3 (pageBarcode) and scanned (guiBarcode) Barcodes"
      return -1
    }
    
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
    if {$np=="8SFPP" && $up=="0_0"} {
      set ret [Send $com "wd-test\r" "disk check in progres" 40]
    } else {
      set ret [Send $com "wd-test\r" "Clock Configuration" 10]
    }
    if {$ret!=0} {
      set gaSet(fail) "WD Test fail. Verify the Dip-Switch position"
      return $ret
    }    
  }
  return $ret
}
# ***************************************************************************
# ShowPS
# ***************************************************************************
proc ShowPS {ps} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Read PS-$ps status"
  set gaSet(fail) "Read status of PS-$ps fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" Celsius]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    set res [regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val]
    if [string match *24VR* $gaSet(DutInitName)] { 
      set res [regexp {1\s+24 VDC\s+([\s\w]+)\s+2 } $buffer - val]
    }
    if {$res==0} {
      set res [regexp {1[\-\s]+([\w\s]+)\s2} $buffer - val]
      if [string match *24VR* $gaSet(DutInitName)] { 
        set res [regexp {1[\-\s]+([a-zA-Z\s]+)\s2} $buffer - val]
      }
    }
  } elseif {$ps==2} {
    set res [regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val]
    if [string match *24VR* $gaSet(DutInitName)] { 
      set res [regexp {2\s+24 VDC\s+([\s\w]+)\sFAN} $buffer - val]
    }
    if {$res==0} {
      set res [regexp {2[\-\s]+([\w\s]+)\sFAN} $buffer - val]
      if [string match *24VR* $gaSet(DutInitName)] { 
        set res [regexp {2[\-\s]+([\sa-zA-Z]+)\sFAN} $buffer - val]
      }
    }
  }
  if {$res==0} {
    set val "-1"
  }
  set val [string trim $val]
  puts "ShowPS ps-$ps val:<$val>"
  if {[lindex [split $val " "] 0] == "HP"} {
    set val [lrange [split $val " "] 1 end] 
  }
  return $val
}
# ***************************************************************************
# Loopback
# ***************************************************************************
proc Loopback {mode} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Set Loopback to \'$mode\'"
  set gaSet(fail) "Loopback configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure port ethernet 0/1\r" (0/1)]
  if {$ret!=0} {return $ret}
  if {$mode=="off"} {
    set ret [Send $com "no loopback\r" (0/1)]
  } elseif {$mode=="on"} {
    set ret [Send $com "loopback remote\r" (0/1)]
  }
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# DateTime_Set
# ***************************************************************************
proc DateTime_Set {} {
  global gaSet buffer
  OpenComUut
  Status "Set DateTime"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
  }
  if {$ret==0} {
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure system\r" >system]
  }
  if {$ret==0} {
    set gaSet(fail) "Set DateTime fail"
    set ret [Send $com "date-and-time\r" "date-time"]
  }
  if {$ret==0} {
    set pcDate [clock format [clock seconds] -format "%Y-%m-%d"]
    set ret [Send $com "date $pcDate\r" "date-time"]
  }
  if {$ret==0} {
    set pcTime [clock format [clock seconds] -format "%H:%M"]
    set ret [Send $com "time $pcTime\r" "date-time"]
  }
  CloseComUut
  RLSound::Play information
  if {$ret==0} {
    Status Done yellow
  } else {
    Status $gaSet(fail) red
  } 
}
# ***************************************************************************
# LoadDefConf
# ***************************************************************************
proc LoadDefConf {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Load Default Configuration fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DefaultCF) 
  set cfTxt "DefaultConfiguration"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  if {$ret!=0} {return $ret}
  set ret [Send $com "y\r" "successfull" 100]
  
  return $ret
}
# ***************************************************************************
# DdrTest
# ***************************************************************************
proc DdrTest {attm} {
  global gaSet buffer
  Status "DDR Test (attempt $attm)"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG (attempt $attm)"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read MEA LOG fail on attempt $attm"
  set ret [Send $com "debug mea\r\r" FPGA 11]
  if {$ret!=0} {
    set ret [Send $com "debug mea\r\r" FPGA 11]
    if {$ret!=0} {return $ret}
  }
  Send $com "\r" FPGA
  Send $com "\r" FPGA
  set ret [Send $com "mea debug log show\r" FPGA>> 30]
  if {$ret!=0} {
    set ret [Send $com "mea debug log show\r" FPGA>> 30]
    if {$ret!=0} {return $ret}
  }
  
  if {[string match {*ENTU_ERROR*} $buffer]} {   
#     if {$gaSet(dbrSW)=="6.7.1(0.58)" && ([string match {*PSBUS Read Write PSid = 2 add = 0x3b*} $buffer] || \
#         [string match {*PSBUS_write PSid = 2 add = 0x3b*} $buffer])} {}
#       #24/11/2020 13:14:09
    if {$gaSet(dbrSW)=="6.7.1(0.58)" && ([string match {*PSBUS Read Write PSid*} $buffer] || \
        [string match {*PSBUS_write PSid*} $buffer])} {  
#         14/06/2021 10:09:24
      # it's OK       
    } else {
      set gaSet(fail) "\'ENTU_ERROR\' exists in the MEA log (attempt $attm)"
      return -1
    }
  }
  if {[string match {*init DDR ..........................OK*} $buffer]==0} {
    set gaSet(fail) "\'init DDR ..OK\' doesn't exist in the MEA log (attempt $attm)"
    return -1
  }
  if {[string match {*DDR NOT OK*} $buffer]==1} {
    set gaSet(fail) "\'DDR NOT OK\' exists in the MEA log (attempt $attm)"
    return -1
  }
  
  set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]
    if {$ret!=0} {return $ret}
  }
  return $ret
}  
# ***************************************************************************
# DryContactTest
# ***************************************************************************
proc DryContactTest {} {
  global gaSet buffer
  Status "Dry Contact Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read MEA LOG"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  RLUsbPio::SetConfig $gaSet(idDrc) 11111000 ; # 3 first bits are OUT
  RLUsbPio::Set $gaSet(idDrc) xxxxx000 ; # 3 first bits are 0 
  
  set gaSet(fail) "Read MEA HW DRY fail"
  set ret [Send $com "debug mea\r" FPGA 11]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea hw dry\r" dry>>]
  if {$ret!=0} {return $ret}
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf7"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf7\'"
    return -1
  }
  
  set ret [Send $com "read 1\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x1\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 1\' fail"
    return -1
  }
  if {$val!="0xff"} {
    set gaSet(fail) "The value of 0x1 is \'$val\'. Should be \'0xff\'"
    return -1
  }
  
  RLUsbPio::Set $gaSet(idDrc) xxxxx111 ; # 3 first bits are 1
  set ret [Send $com "read 0\r" dry>>]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\[0x0\]\.+(\w+)} $buffer - val]
  if {$res==0} {
    set gaSet(fail) "Read \'read 0\' fail"
    return -1
  }
  if {$val!="0xf0"} {
    set gaSet(fail) "The value of 0x0 is \'$val\'. Should be \'0xf0\'"
    return -1
  }
     
  set ret [Send $com "exit\r\r" $gaSet(prompt) 16]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# ShowArpTable
# ***************************************************************************
proc ShowArpTable {} {
  global gaSet buffer 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Show ARP Table fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure router 1\r" (1)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show arp-table\r" (1)]
  if {$ret!=0} {return $ret}
  
  set lin1 "1.1.1.1 00-00-00-00-00-01 Dynamic"
  set lin2 "2.2.2.1 00-00-00-00-00-02 Dynamic"
   
  foreach lin [list $lin1 $lin2] {
    if {[string match *$lin* $buffer]==0} {
      set gaSet(fail) "The \'$lin\' doesn't exist"
      return -1
    }
  }

  return 0
}

# ***************************************************************************
# SoftwareDownloadTest
# ***************************************************************************
proc SoftwareDownloadTest {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  #set tail [file tail $gaSet(SWCF)]
  set tail $gaSet(pair)_[file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  # Download:   
  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
  
  catch {file delete -force c:/download/temp/$tail} cres
  after 2000
  if [file exists c:/download/temp/$tail] {
    if [catch {file delete -force c:/download/temp/$tail} cres] {
      set gaSet(fail) "The SW file (c:/download/temp/$tail) can't be deleted"
      puts "[MyTime] SoftwareDownloadTest. The file c:/download/temp/$tail ($gaSet(SWCF)) can't be deleted. cres:<$cres>"
      return -1
    }
  }
  
  if {[string match {*FTP transfer error*} $buffer]==1} {
    set gaSet(fail) "FTP transfer error"
    return -1
  }
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  
  return $ret
} 

# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {port} {
  global gaSet buffer bu glSFPs
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read EthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  set ret [Send $com "show status\r" more 11]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  set res [regexp {SFP\+?\sIn} $bu - ]
  if {$res==0} {
    set gaSet(fail) "The status of port $port is not \'SFP In\'"
    return -1
  }
  #21/04/2020 10:18:09
  set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Operational Status of port $port fail"
    return -1
  }
  set opStat [string trim $value]
  puts "opStat:<$opStat>"
  if {$opStat!="Up"} {
    set gaSet(fail) "The Operational Status of port $port is $opStat"
    return -1
  }
  
  set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)Typical} $bu - val]
  if {$res==0} {
    set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)SFP Manufacture Date} $bu - val]
    if {$res==0} {
      set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)Manufacturer CLEI} $bu - val]
      if {$res==0} {
        set gaSet(fail) "Read Manufacturer Part Number of SFP in port $port fail"
        return -1
      } 
    } 
  }
  set val [string trim $val]
  set glSFPs [list]
  set id [open ./TeamLeaderFiles/sfpList.txt r]
    while {[gets $id line]>=0} {
      lappend glSFPs $line
    }
  close $id
  puts "val:<$val> glSFPs:<$glSFPs>" ; update
  if {[lsearch $glSFPs $val]=="-1"} {
    set gaSet(fail) "The Manufacturer Part Number of SFP in port $port is \'$val\'"
    return -1  
  }
  
  return 0
}

# ***************************************************************************
# ReadUtpPortStatus
# ***************************************************************************
proc ReadUtpPortStatus {port} {
  global gaSet buffer bu 
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read UtpEthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  #set ret [Send $com "show status\r" more 8]
  set ret [Send $com "show status\r" ($port)]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  puts "ReadEthPortStatus bu:<$bu>"
  if {[string match *.12CMB.* $gaSet(DutInitName)]==1} {
    set res [regexp {Administrative Status[\s\:]+([\w]+)\s} $bu - value]
    if {$res==0} {
      set gaSet(fail) "Read Administrative Status of port $port fail"
      return -1
    }
    set adStat [string trim $value]
    puts "adStat:<$adStat>"
    if {$adStat!="Up"} {
      set gaSet(fail) "The Administrative Status of port $port is $adStat"
      return -1
    }
    if {![string match {*RJ45 Active*} $bu]} {
      set gaSet(fail) "The Connector Type of port $port is not RJ45 Active"
      return -1
    }
  } elseif {[string match *.12CMB.* $gaSet(DutInitName)]==0} {    
    set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
    if {$res==0} {
      set gaSet(fail) "Read Operational Status of port $port fail"
      return -1
    }
    set opStat [string trim $value]
    puts "opStat:<$opStat>"
    if {$opStat!="Up"} {
      set gaSet(fail) "The Operational Status of port $port is $opStat"
      return -1
    }
  }
  
  return 0
}

# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "$state\r" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc SpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  set ret [Send $com "speed-duplex 100-full-duplex\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  
# ***************************************************************************
# ReadCPLD
# ***************************************************************************
proc ReadCPLD {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Read CPLD"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read CPLD"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) ???
  } 
  set gaSet(fail) "Read CPLD fail"  
  set ret [Send $com "debug memory address c0100000 read char length 1\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set res [regexp {0xC0100000\s+(\d+)\s} $buffer - value]
  if {$res==0} {return -1}
  puts "\nReadCPLD value:<$value> gaSet(cpld):<$gaSet(cpld)>\n"; update
  if {$value!=$gaSet(cpld)} {
    set gaSet(fail) "CPLD is \'$value\'. Should be \'$gaSet(cpld)\'"  
    return -1
  }
  set gaSet(cpld) ""
  return $ret
}
# ***************************************************************************
# Boot_Download
# ***************************************************************************
proc Boot_Download {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Empty unit prompt"
  Send $com "\r\r" "=>" 2
  set ret [Send $com "\r\r" "=>" 2]
  if {$ret!=0} {
    # no:
    puts "Skip Boot Download" ; update
    set ret 0
  } else {
    # yes:   
    Status "Setup in progress ..."
    
    if {$gaSet(pair)=="SE"} {
      set pair 101
    } else {
      set pair $gaSet(pair)
    }
    set x [format %.2x $pair]
    
    # Config Setup:
    Send $com "env set ethaddr 00:20:01:02:03:$x\r" "=>"
    Send $com "env set netmask 255.255.255.0\r" "=>"
    Send $com "env set gatewayip 10.10.10.10\r" "=>"
    Send $com "env set ipaddr 10.10.10.$x\r" "=>"
    Send $com "env set serverip 10.10.10.10\r" "=>"
    
    # Download Comment: download command is: run download_vxboot
    # the download file name should be always: vxboot.bin
    # else it will not work !
    
    if {[file exists $gaSet(BootCF)]!=1} {
      set gaSet(fail) "The BOOT file ($gaSet(BootCF)) doesn't exist"
      return -1
    }
    if [file exists c:/download/temp/delete_vxboot] {
      puts "[MyTime]  delete_vxboot exists"; update
      if [file exists c:/download/temp/vxboot.bin] {
        puts "[MyTime] delete vxboot.bin"; update
        file delete -force c:/download/temp/vxboot.bin
      }
      puts "[MyTime] copy vxboot.bin"; update 
      file copy -force $gaSet(BootCF) c:/download/temp  
    } else {
      puts "[MyTime] delete_vxboot not exists, not delete, not copy"; update
    }
    
    #regsub -all {\.[\w]*} $gaSet(BootCF) "" boot_file
    
    puts "[MyTime] delete delete_vxboot"; update
    file delete -force c:/download/temp/delete_vxboot
    after 1000
    Send $com "run download_vxboot\r" stam 1
    set ret [Wait "Download Boot in progress ..." 10]
    if {$ret!=0} {return $ret}
    after 5000
    
    if [file exists c:/download/temp/delete_vxboot] {
      puts "[MyTime] delete_vxboot exists"; update
      puts "[MyTime] delete vxboot.bin"; update
      file delete -force c:/download/temp/vxboot.bin
    } else {
       puts "[MyTime] create delete_vxboot"; update
      set id [open c:/download/temp/delete_vxboot w+]
      close $id
    }
       
    
    Send $com "\r\r" "=>" 1
    set ret [Send $com "\r\r" "=>" 3]
    if {$ret!=0} {
      set gaSet(fail) "No Prompt after download_vxboot" 
      return -1
    }
    
    set ret [regexp {Error} $buffer]
    if {$ret==1} {
      set gaSet(fail) "Boot download fail" 
      return -1
    }  
    
    Status "Reset the unit ..."
    Send $com "reset\r" "stam" 1
    set ret [Wait "Wait for Reboot ..." 40]
    if {$ret!=0} {return $ret}
    
  }      
  return $ret
}

# ***************************************************************************
# FormatFlashAfterBootDnl
# ***************************************************************************
proc FormatFlashAfterBootDnl {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Format Flash after Boot Download"
  Send $com "\r\r" "Are you sure(y/n)?" 2
  set ret [Send $com "\r\r" "Are you sure(y/n)?" 2]
  if {$ret!=0} {
    puts "Skip Flash format" ; update
    set ret 0
  } else {
    Send $com "y\r" "\[boot\]:"
    puts "Format in progress ..." ; update
    set formatMax 1500
    set ret [MyWaitFor $com "boot]:" 5 $formatMax]
    if {$ret!=0} {
      if {$ret=="HW Failure"} {
        set gaSet(fail) "HW Failure"
        set ret -1
      } else {
        set gaSet(fail) "Don't reach \'boot'\ after $formatMax sec formatting" 
      }
    }
  }
  return $ret
}

# ***************************************************************************
# SetSWDownload
# ***************************************************************************
proc SetSWDownload {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  if {[file exists $gaSet(SWCF)]!=1} {
    set gaSet(fail) "The SW file ($gaSet(SWCF)) doesn't exist"
    return -1
  }
     
  set tail $gaSet(pair)_[file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail} cres] {
        set gaSet(fail) "The SW file ($gaSet(SWCF)) can't be deleted"
        puts "[MyTime] SetSWDownload. The file c:/download/temp/$tail ($gaSet(SWCF)) can't be deleted. cres:<$cres>"
        return -1
      }  
    }
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp/$tail 
  
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "vxworks\r" "(pw)" ;# vxworks 

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
  append appBuffer $buffer
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  append appBuffer $buffer
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
    append appBuffer $buffer
  }
  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  } 

  if {[string match {*MNG-ETH port failure*} $appBuffer]==1} {
    set gaSet(fail) "MNG-ETH port failure"
    return -1
  }  
  
  return $ret  
}
# ***************************************************************************
# DeleteBootFiles
# ***************************************************************************
proc DeleteBootFiles {} {
  global  gaSet buffer
  set com $gaSet(comDut)
  
  Status "Delete Boot Files"
  Send $com "dir\r" "\[boot\]:"
  set ret0 [regexp -all {No files were found} $buffer]
  set ret1 [regexp -all {sw-pack-1} $buffer]
  set ret2 [regexp -all {sw-pack-2} $buffer]
  set ret3 [regexp -all {sw-pack-3} $buffer]
  set ret4 [regexp -all {sw-pack-4} $buffer]
  set ret5 [regexp -all {factory-default-config} $buffer]
  set ret6 [regexp -all {user-default-config} $buffer]
  set ret7 [regexp {Active SW-pack is:\s*(\d+)} $buffer var ActSw]
  set ret8 [regexp -all {startup-config} $buffer]
  
  
  if {$ret7==1} {set ActSw [string trim $ActSw]}
  
  # No files were found:
  if {$ret0!=0} {
    puts "No files were found to delete" ; update
    return 0
  }
  
  foreach SwPack "1 2 3 4" {
    # Del sw-pack-X:
    if {[set ret$SwPack]!=0} {
      if {([info exist ActSw]== 1) && ($ActSw==$SwPack)} {
        # exist:  (Active SW-pack is: 1)
        Send $com "delete sw-pack-[set SwPack]\r" "y/n"
        set res [Send $com "y\r" "deleted successfully" 60]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }      
      } else {
        # not exist: ("Active SW-pack isn't: X"   or  "No active SW-pac")
        set res [Send $com "delete sw-pack-[set SwPack]\r" "deleted successfully" 60]
        if {$res!=0} {
          set gaSet(fail) "sw-pack-[set SwPack] delete fail"
          return -1      
        }       
      }
      puts "sw-pack-[set SwPack] Delete" ; update
    } else {
      puts "sw-pack-[set SwPack] not found" ; update
    }
  }

  # factory-default-config:
  if {$ret5!=0} {
    set res [Send $com "delete factory-default-config\r" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "fac-def-config delete fail"
      return -1      
    } 
    puts "factory-default-config Delete" ; update      
  } else {
    puts "factory-default-config not found" ; update
  }
  
  # user-default-config:
  if {$ret6!=0} {
    set res [Send $com "delete user-default-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-def-config delete fail"
      return -1      
    } 
    puts "user-default-config Delete" ; update      
  } else {
    puts "user-default-config not found" ; update
  }
  
  # startup-config:
  if {$ret8!=0} {
    set res [Send $com "delete startup-config\12" "deleted successfully" 20]
    if {$res!=0} {
      set gaSet(fail) "Use-str-config delete fail"
      return -1      
    } 
    puts "startup-config Delete" ; update      
  } else {
    puts "startup-config not found" ; update
  }  
    
  return 0
}

# ***************************************************************************
# FanEepromBurnTest
# ***************************************************************************
proc FanEepromBurnTest {} {
  global gaSet buffer 
  Status "Fan EEPROM Burn"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Fan EEPROM Burn"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }     
    
  set gaSet(fail) "Fan EEPROM Burn fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {
    set ret [Send $com "debug mea\r\r\r" FPGA]
    if {$ret!=0} {return $ret}
  } 
  set ret [Send $com "mea util fan\r" fan]
  if {$ret!=0} {
    set ret [Send $com "\r\r" fan]
    if {$ret!=0} {return $ret}
  } 
  foreach {reg val} {0x00 0x11 0x05 0x2D 0x20 0x00 0x21 0x00 0x22 0x00 0x23 0x00\
                     0x24 0x00 0x25 0x00 0x26 0x00 0x27 0x00 0x28 0x00 0x29 0x00\
                     0x2A 0x00 0x2B 0x00 0x2C 0x00 0x2D 0x00 0x2E 0x00 0x2F 0x00\
                     0x30 0x33 0x31 0x4C 0x32 0x66 0x33 0x80 0x34 0x99 0x35 0xB2\
                     0x36 0xCC 0x36 0xE5 0x37 0xFF 0x02 0x01 0x5B 0x1F} {
    set ret [Send $com "Write $reg $val\r" fan]
    if {$ret!=0} {return $ret}                      
  }
  return $ret
}  
    
# ***************************************************************************
# Login205
# ***************************************************************************
proc Login205 {aux} {
  global gaSet buffer gaLocal
  set ret 0
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into AUX-$aux"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  set com $gaSet(com$aux)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {([string match {*205A*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
  }
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r 205A
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r 205A
  }
  if {[string match *205A* $buffer]} {
    set ret 0
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    return 0
  } 
  if {[string match *user* $buffer]} {
    Send $com su\r stam 0.25
    set ret [Send $com 1234\r "205A"]
    $gaSet(runTime) configure -text ""
    return $ret
  }
  if {$ret!=0} {
    set ret [Wait "Wait for Aux-$aux up" 20 white]
    if {$ret!=0} {return $ret}  
  }
  for {set i 1} {$i <= 60} {incr i} { 
    if {$gaSet(act)==0} {return -2}
    Status "Login into AUX-$aux"
    puts "Login into AUX-$aux i:$i"; update
    $gaSet(runTime) configure -text $i
    Send $com \r stam 5
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*205A*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $com run\r stam 1
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $com \x1F\r\r 205A
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $com su\r stam 1
      set ret [Send $com 1234\r "205A"]
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to AUX-$aux Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# SyncELockClkTest
# ***************************************************************************
proc SyncELockClkTest {} {
  puts "[MyTime] SyncELockClkTest"
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Reading Clock's status"
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system clock\r" ">clock"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "domain 1\r" "domain(1)"]
  if {$ret!=0} {return $ret} 
  for {set i 1} {$i<=5} {incr i} {
    puts "\rattempt $i"
    set ret [Send $com "show status\r" "domain(1)"]
    if {$ret!=0} {return $ret} 
    set syst [set sysQlty [set sysClkSrc [set sysState ""]]]
    regexp {System Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+Quality[\s:]+(\w+)\s} $buffer syst sysClkSrc sysState sysQlty
    set stat [set statClkSrc [set statState ""]]
    regexp {Station Out Clock Source[\s:]+(\d)\s+State[\s:]+(\w+)\s+} $buffer stat statClkSrc statState 
    puts "sysClkSrc:<$sysClkSrc> sysState:<$sysState> sysQlty:<$sysQlty>"
    puts "statClkSrc:<$statClkSrc> statState:<$statState>"
    update
    set fail ""
    if {$sysClkSrc=="2" && $sysState=="Locked" && $sysQlty=="PRC" && $statClkSrc=="2" && $statState=="Locked"} {
      set ret 0
      break
    } else {  
      if {$sysClkSrc!="1"} {
        append fail "System Clock Source: $sysClkSrc and not 1" , " "
      }  
      if {$sysState!="Locked"} {
        append fail "System Clock State: $sysState and not Locked" , " "
      }
      if {$sysQlty!="PRC"} {
        append fail "System Clock Quality: $sysQlty and not PRC" , " "
      }
      if {$statClkSrc!="1"} {
        append fail "Station Out Clock Source: $statClkSrc and not 1" , " "
      }
      if {$statState!="Locked"} {
        append fail "Station Out Clock State: $statState and not Locked"
      }
      set ret -1
      set fail [string trimright $fail]
      set fail [string trimright $fail ,]
      after 1000
    }
  }
  if {$ret=="-1"} {
    set gaSet(fail) "$fail"
  } elseif {$ret=="0"} {
    #set ret [Send $com "no source 1\r" "domain(1)"]
    #if {$ret!=0} {return $ret}
  }
  
  return $ret
} 
# ***************************************************************************
# PingTraps
# ***************************************************************************
proc PingTraps {intf dutIp} {
  global gaSet
  Status "Wait for Ping traps"
  set resFile c:\\temp\\te_$gaSet(pair)_[clock format [clock seconds] -format  "%Y.%m.%d_%H.%M.%S"].txt
  set dur 10
  exec [info nameofexecutable] Lib_tshark.tcl $intf $dur $resFile icmp &
  after 1000
  
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  after "[expr {$dur +1}]000" ; ## one sec more then duration
  set id [open $resFile r]
    set monData [read $id]
    set ::md $monData 
  close $id  

  puts "\r---<$monData>---\r"; update
  
  set res [regexp -all "Src: $dutIp, Dst: 10.10.10.10" $monData]
  puts "res:$res"
  if {$res<2} {
    set gaSet(fail) "2 Ping traps did not sent"
    return -1
  }
  return 0
}  

# ***************************************************************************
# FanStatusTest
# ***************************************************************************
proc FanStatusTest {} {
  global gaSet buffer
  Status "Fan Status Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  
  if {$gaSet(rbTestMode) eq "Comp"} {
    ## no check it in Complementary
    set ret 0
    set lsr 0
  } else {
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure port ethernet 0/1\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show status\r" more 8]
    if {$ret!=0} {
      set gaSet(fail) "Read Laser Temperature fail"
      return $ret
    }
    set ret [Send $com "\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    if [regexp {Laser Temperature \(Celsius\)[\s\:]+([\d\.]+)\sC} $buffer m val] {
      set lsr [string trim $val]
      AddToPairLog $gaSet(pair) "$m"
    } else {
      set gaSet(fail) "Retrive Laser Temperature fail"
      return -1
    }
  }
  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" Celsius]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  regexp {FAN Status[\s-]+(.+)\sSensor} $buffer ma fanSt
  if ![info exists fanSt] {
    set gaSet(fail) "Can't read FAN Status"
    return -1
  }
  puts "fanSt:$fanSt"
  if {$np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1 && \
      $fanSt eq "-" && $gaSet(rbTestMode) eq "Full"} {
    ## no fans in OutDoor       
  } else {
    if {$b=="Half19" || $b=="Half19B"} {
      if {$fanSt!="1 OK"} {
        set gaSet(fail) "FAN Status is \'$fanSt\'"
        return -1
      }
    } elseif {$b=="19"} { 
      if {$fanSt!="1 OK 2 OK 3 OK 4 OK"} {
        set gaSet(fail) "FAN Status is \'$fanSt\'"
        return -1
      }
    } elseif {$b=="19B"} { 
      if {$np=="8SFPP" && $up=="0_0" && \
          ([string match *B.19.H.* $gaSet(DutInitName)]    || [string match *B.19.N.* $gaSet(DutInitName)] ||\
           [string match *B_C.19.H.* $gaSet(DutInitName)]  || [string match *B_ATT.H.* $gaSet(DutInitName)] ||\
           [string match *.19.H.* $gaSet(DutInitName)]     || \
           [string match *ATT.19.HN.* $gaSet(DutInitName)] || [string match *B_ATT.19.HN.* $gaSet(DutInitName)])} {
        if {$fanSt!="1 OK 2 OK 3 OK 4 OK"} {
          set gaSet(fail) "FAN Status is \'$fanSt\'"
          return -1
        }
      } else {
        if {$fanSt!="1 OK 2 OK"} {
          set gaSet(fail) "FAN Status is \'$fanSt\'"
          return -1
        }
      }
    }
  }
  
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Fan EEPROM Burn"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }     
    
  set gaSet(fail) "Fan Test fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {
    set ret [Send $com "debug mea\r\r\r" FPGA]
    if {$ret!=0} {return $ret}
  } 
  set ret [Send $com "mea util fc\r" fctl 2]
  if [string match *ENTU_ERROR* $buffer] {
    set ret [Send $com "mea util fan\r" fan 2]
  }
  if {$ret!=0} {
    set ret [Send $com "\r\r" stam 1]
    #if {$ret!=0} {return $ret}
  }        
  
  for {set i 1} {$i<=5} {incr i} {            
    set ret [Send $com "st\r" stam 1]
  }
  #if {$ret!=0} {return $ret}
  
  set lvv [RetriveFansCheckJ]
  if {$lvv=="-1"} {return $lvv}
  set lvv [string trimright $lvv "_"]
  foreach {A B D F G C E H I J fans checkJ} [split $lvv _]  {}
  foreach vv {A B D F G C E H I J fans checkJ} {
    puts "FanStatusTest $vv [set $vv]"      
  }
  
  if {$np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1} {
    set minA 30
    set minB 30
    set diffAB 4
    set maxA 70
    set maxB 70
  } else {
    set minA 20
    set minB 20
    set minC 20
    set minJ 20
    set diffAB 10
    set diffAC 10
    set maxA 70
    set maxB 70
    set maxC 70
    set maxJ 70
  }
  set gaSet(AminusLsr) [format %.2f [expr {$A - $lsr}]]
  if {$A<$minA || $A>$maxA} {
    set gaSet(fail) "A is $A. Should be between $minA and $maxA"
    return -1  
  }
  if {$B<$minB || $B>$maxB} {
    set gaSet(fail) "B is $B. Should be between $minB and $maxB"
    return -1  
  }
  if {$fans==4} {
    if {$C<$minC || $C>$maxC} {
      set gaSet(fail) "C is $C. Should be between $minC and $maxC"
      return -1  
    }
  }
  
  set diff [expr abs([expr {$A-$B}])]
  if {$diff>$diffAB} {
    set gaSet(fail) "The difference between A and B is $diff. Should be <= $diffAB"
    return -1  
  }
  if {$fans==4} {
    set diff [expr abs([expr {$A-$C}])]
    if {$diff>$diffAC} {
      set gaSet(fail) "The difference between A and C is $diff. Should be <= $diffAC"
      return -1  
    }
  }
  
  if {$D=="FF"} {
    set gaSet(fail) "D is $D"
    return -1  
  }
  if {$fans==4} {
    if {$E=="FF"} {
      set gaSet(fail) "E is $E"
      return -1  
    }
  }
  
  if {$F=="FFFF"} {
    set gaSet(fail) "F is $F"
    return -1  
  }
  if {$fans==2 || $fans==4} {
    if {$G=="FFFF"} {
      set gaSet(fail) "G is $G"
      return -1  
    }
  }
  if {$fans==4} {
    if {$H=="FFFF"} {
      set gaSet(fail) "H is $H"
      return -1  
    }
    if {$I=="FFFF"} {
      set gaSet(fail) "I is $I"
      return -1  
    }
    if {$checkJ=="yes" && ($J<$minJ || $J>$maxJ)} {
      set gaSet(fail) "J is $J. Should be between $minJ and $maxJ"
      return -1  
    }
  }
  
  set ret 0
  set ret [Send $com "exit\r\r" $gaSet(prompt) 2]
  if {$ret!=0} {
    Send $com "exit\r\r" $gaSet(prompt) 2
  }
    
  return $ret
}
# ***************************************************************************
# LicenseRead2CloseAll
# ***************************************************************************
proc LicenseRead2CloseAll {} {
  global gaSet buffer 
  Status "LicenseRead2CloseAll"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  
  set gaSet(fail) "Logon fail"
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read SFPP license"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }     
  
  set sw $gaSet(dbrSW) ; # 6.2.1(0.44)
  set majSW [string range $sw 0 [expr {[string first ( $sw] - 1}]]; # 6.2.1
  puts "sw:$sw majSW:$majSW"
  
  set gaSet(fail) "Read 4SFPP license fail"
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "admin license\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show summary\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  if {$majSW<6.4} {
    set res [regexp {SFP\+ Ethernet Ports\s+(\w+)\s+([\-\d\w]+)} $buffer m stat inUse]
  } else {
    set res [regexp {SFP\+ Factory 10G Rate (\w+)\s+([\-\d]+) [\-\d]+} $buffer m stat inUse]
  }
  if {$res=="0"} {
    set gaSet(fail) "Read SFP+ Factory 10G Rate fail"
    return -1
  }
  puts "stat:<$stat> inUse:<$inUse>"  
  
  if {$stat=="Enabled" || $inUse=="2"} {
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "configure port\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    foreach etPo {0/1 0/2 0/3 0/4} {
      set ret [Send $com "eth $etPo\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      set ret [Send $com "speed-duplex 1000-full-duplex\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
      set ret [Send $com "exit\r" $gaSet(prompt)]
      if {$ret!=0} {return $ret}
    }
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin license\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no license-enable sfp-plus-factory-10g-rate\r" $gaSet(prompt)] 
    
    set ret [FactDefault std noWD]
    if {$ret!=0} {return $ret}
    set ret [Login]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin license\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show summary\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
  }
    
  return $ret
}
# ***************************************************************************
# MirpesetStat
# ***************************************************************************
proc MirpesetStat {} {
  global gaSet buffer
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  if {$up=="24SFP_0" && $gaSet(dbrSW) eq "6.5.1(0.30)"} {
    for {set i 1} {$i <= 3} {incr i} {
      puts "\n[MyTime] ReadEthPortStatus $i 0/18 and 0/20" ; update
      set ret18 [ReadEthPortStatus 0/18]
      set res18 $gaSet(fail)
      set ret20 [ReadEthPortStatus 0/20]
      set res20 $gaSet(fail)
      puts "[MyTime] ReadEthPortStatus $i res 0/18:<$ret18> and 0/20:<$ret20>" ; update
      
      if {$ret18 eq "-2" || $ret20 eq "-2"} {return "-2"} 
      if {$ret18 ne "0" && $ret20 ne "0"} {
        AddToPairLog $gaSet(pair) "0/18 result: $res18"
        AddToPairLog $gaSet(pair) "0/20 result: $res20"
      
        Power all off
        after 3000
        Power all on
        Wait "Wait for up" 30
        set ret [Login]
        if {$ret!=0} {return $ret}
      } else {
        set ret 0
        break
      }
    }
  } else {
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# AdminFactAll
# ***************************************************************************
proc AdminFactAll {} {
  global gaSet buffer
  global gaSet buffer gaGui
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }
  Status "Admin Factory All to UUT"  
  set com $gaSet(comDut)
  set ret [Send $com "admin factory-default-all\r" "yes/no"]
  if {$ret!=0} {return $ret} 
  set ret [Send $com "y\r" "seconds" 20]
  if {$ret!=0} {return $ret} 
  Wait "Wait for UUT up" 30
  return 0
}  

# ***************************************************************************
# VerifySN
# ***************************************************************************
proc VerifySN {} {
  global gaSet buffer
  global gaSet buffer gaGui
  set ret [Login]
  if {$ret!=0} {
    set ret [Login]
    if {$ret!=0} {return $ret}
  }  
  Status "Read Serial Number at UUT"
  set com $gaSet(comDut)
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}  
  set ret [Send $com "configure system\r" system]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show device-information\r" system]
  if {$ret!=0} {return $ret}
  set res [regexp {Serial Number[\s\:]+(\d+)} $buffer ma val ]
  if {$res==0} {
    set res [string match {*Manufacturer Serial Number : Not Available*} $buffer]
    if {$res==0} {
      set gaSet(fail) "Read Serial Number fail"
      return -1
    } else {
      set val "0000000000000000"
    }
  }
  set gaSet(dutSerNum) [string trim $val]
  puts "SerNum:<$gaSet(dutSerNum)> gaSet(serialNum):<$gaSet(serialNum)>"
  if {[string length $gaSet(dutSerNum)]==16} {
    if {[string range $gaSet(dutSerNum) 6 end]=="$gaSet(serialNum)"} {
      return 0
    } else {
      set gaSet(fail) "SN is $gaSet(dutSerNum) instead of 000000$gaSet(serialNum)"
      return -1
    }
  } elseif {[string length $gaSet(dutSerNum)]==10} {
    if {$gaSet(dutSerNum)=="$gaSet(serialNum)"} {
      return 0
    } else {
      set gaSet(fail) "SN is $gaSet(dutSerNum) instead of $gaSet(serialNum)"
      return -1
    }
  }
}

# ***************************************************************************
# TstAlmLedTest
# ***************************************************************************
proc TstAlmLedTest {} {
  global gaSet buffer   
  Status "TstAlm Led Test"
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set hw 0.123
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure system\r" system]  
  set ret [Send $com "show device-information\r\r" system]  
  regexp {Hw:\s+([\.\d]+)\/} $buffer - hw
  if ![info exists hw] {
    set gaSet(fail) "Can't read the HW version"
    return -1
  }
  
  Send $com "\r\r" stam 0.25 
  Send $com "exit all\r" stam 0.25 
  puts "hw:$hw"
  
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  } 
  
  if {[package vcompare $hw 0.4]>=0} {
    set ret [Send $com "debug mea\r\r\r" FPGA]
    if {$ret!=0} {
      set ret [Send $com "debug mea\r\r\r" FPGA]
      if {$ret!=0} {return $ret}
    } 
  }
  
  foreach regVal {84 88 80} stt {"lights red" "lights orange" "is off"} {
    if {[package vcompare $hw 0.4]<0} {
      ## $hw < 0.4  
      Send $com "debug memory address 92000019 write char value $regVal\r" stam 0.1
    } else {
      ## $hw >= 0.4  
      Send $com "mea util comp gp gpr 19 $regVal\r" stam 0.1
    }
    set txt "Verify that TST/ALR led $stt"
    RLSound::Play information
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
    update
    if {$res!="OK"} {
      set gaSet(fail) "TST/ALR led lights wrong"
      return -1
    } else {
     set ret 0
    }
  }
  
  set ret [Send $com "exit\r\r" $gaSet(prompt) 2]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r" $gaSet(prompt) 2]
  }
  
  return $ret
}

# ***************************************************************************
# SetJatPllDownload
# ***************************************************************************
proc SetJatPllDownload {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set JAT_PLL Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  set ret [PrepareDwnlJatPll]
  if {$ret=="-1"} {return $ret}
  set tail $ret
  
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "\r" "(pw)" ;# vxworks

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
  }
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  }

  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail}] {
         set gaSet(fail) "The SW file ($SWCF) can't be deleted"
         return -1
      }
    
    }
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  return $ret     
}

# ***************************************************************************
# Load_Jat_Pll_Perf
# ***************************************************************************
proc Load_Jat_Pll_Perf {} {
  global gaSet gaGui buffer
  set com $gaSet(comDut)
  Status "Loading Jat_Pll"
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
    
  set gaSet(fail) "Logon fail"
  Send $com "exit all\r" stam 0.25 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$np=="8SFPP" && $up=="0_0"} {
    ## 07:18 06/02/2022 in Itzik's product we need the password
    Send $com "logon\r" stam 0.25 
    if {[string match {*command not recognized*} $buffer]==0} {
      set ret [Send $com "logon debug\r" password]
      if {$ret!=0} {return $ret}
      regexp {Key code:\s+(\d+)\s} $buffer - kc
      catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
      set ret [Send $com "$password\r" $gaSet(prompt) 1]
      if {$ret!=0} {return $ret}
    }     
  }
  set gaSet(fail) "Load_Jat_Pll_Perf Test fail"
  set ret [Send $com "debug mea\r\r\r" FPGA]
  if {$ret!=0} {
    set ret [Send $com "debug mea\r\r\r" FPGA]
    if {$ret!=0} {return $ret}
  } 
    
  if {$gaSet(enJat)==1} {
    set gaSet(fail) "Load JAT fail"
    set ret [Send $com "mea util jat\r" "jat"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show\r" "jat"]
    if {$ret!=0} {return $ret}
    set res [regexp {banks[\.\s]+(\d)\s} $buffer ma value]
    if {$res==0} {
      set gaSet(fail) "Read JAT show fail"
      return -1
    }
    puts "Load_Jat_Perf ma:{$ma} value:{$value}"
    
    if {$value==0} {
      set gaSet(fail) "No empty JAT user banks"
      return -1
    }
    set ret [Send $com "load\r" "y/n"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "Programming succeeded" 20]
    if {$ret!=0} {return $ret}
    set ret [Send $com "top\r" "FPGA"]
    if {$ret!=0} {return $ret}
  }  
  
  if {$gaSet(enPll)==1} {
    set gaSet(fail) "Load PLL fail"
    set ret [Send $com "mea util pll\r" "pll"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show\r" "pll"]
    if {$ret!=0} {return $ret}
    set res [regexp {banks[\.\s]+(\d)\s} $buffer ma value]
    if {$res==0} {
      set gaSet(fail) "Read PLL show fail"
      return -1
    }
    puts "Load_Pll_Perf ma:{$ma} value:{$value}"
    if {$value==0} {
      set gaSet(fail) "No empty PLL user banks"
      return -1
    }
    
    set ret [Send $com "load\r" "y/n"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "Programming succeeded" 20]
    if {$ret!=0} {return $ret}
    set ret [Send $com "top\r" "FPGA"]
    if {$ret!=0} {return $ret}
  }  
  
  return $ret  
}

# ***************************************************************************
# Dyigasp_ClearLog
# ***************************************************************************
proc Dyigasp_ClearLog {} {
  global gaSet buffer
  Status "PS_ID Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut) 
  set gaSet(fail) "Clear Log fail"  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "reporting\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "clear-alarm-log  all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show brief-log\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# Dyigasp_ReadLog
# ***************************************************************************
proc Dyigasp_ReadLog {} {
  global gaSet buffer
  Status "Dyigasp ReadLog "
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set gaSet(fail) "Read Log fail"  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "reporting\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  Send $com "show brief-log\r" "stam 0.5"
  set ret -1
  for {set i 1} {$i<=5} {incr i} {
    if {[string match *dying_gasp* $buffer]} {
      set ret [Send $com "\3\r\r\r"  $gaSet(prompt)]
      set ret 0
      break
    }
    if {[string match *reporting* $buffer]} {
      break
    }
  }
  if {$ret eq "-1"} {
    set gaSet(fail) "No \'dying_gasp\' event in the Log" 
  }
  return $ret
}

# ***************************************************************************
# PtpClock_conf_perf
# ***************************************************************************
proc PtpClock_conf_perf {} {
  global gaSet buffer
  Status "PtpClock_conf Test"
  Power all on
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set gaSet(fail) "Load PTP Clock Configuration fail"  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  
  set cf "C:/AT-ETX-2i-10G/ConfFiles/PtpClkRcvr.txt"
  set cfTxt "PTP Clock Configuration"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  return $ret  
}

# ***************************************************************************
# PtpClock_run_perf
# ***************************************************************************
proc PtpClock_run_perf {} {
  global gaSet buffer
  Status "PtpClock_run Test"
  Power all on
  set sec1 [clock seconds]
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }   
  set com $gaSet(comDut)  
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show con sys clock recovered 0/1 ptp g.8275-1 statistics running\r" $gaSet(prompt)]
  if {$ret!=0} {
    set gaSet(fail) "Read recovered g.8275-1 statistics fail"
    return $ret
  }
  set ret [ReadPtpStats recovered]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "show con sys clock master 0/1 ptp g.8275-1 statistics running\r" $gaSet(prompt)]
  if {$ret!=0} {
    set gaSet(fail) "Read master g.8275-1 statistics fail"
    return $ret
  }
  set ret [ReadPtpStats master]
  if {$ret!=0} {return $ret}
  
  for {set i 1} {$i<=20} {incr i} {
    Status "Read recovered g.8275-1 status ($i)"
    set ret [Send $com "show con sys clock recovered 0/1 ptp g.8275-1 status\r" $gaSet(prompt)]
    if {$ret!=0} {
      set gaSet(fail) "Read recovered g.8275-1 status fail"
      return $ret
    }
    set res [regexp {Clock State Time : (\w+) Clock} $buffer ma val]
    puts "i:<$i> res:<$res> ma:<$ma> val:<$val>"
    if {$res==0} {
      set gaSet(fail) "Read Clock State Time fail"
      return -1
    } 
    if {$val=="Locked"} {
      set ret 0
      break
    }
    after 4000
  }
  set sec2 [clock seconds]
  AddToPairLog $gaSet(pair) "After [expr {$sec2 - $sec1}] seconds Clock State Time : $val. "
  if {$val!="Locked"} {
    set gaSet(fail) "Clock State Time : $val"
    return -1
  }
  
  return $ret
}

# ***************************************************************************
# ReadPtpStats
# ***************************************************************************
proc ReadPtpStats {clk} {
  global gaSet buffer
  puts "ReadPtpStats $clk"
  set res [regexp {Announce[\s\:]+(\d+)} $buffer ma ann]
  if {$res==0} {
    set gaSet(fail) "Read Rx Announce of $clk clk fail"
    return -1
  }
  set res [regexp {Sync[\s\:]+(\d+)} $buffer ma sync]
  if {$res==0} {
    set gaSet(fail) "Read Rx Sync of $clk clk fail"
    return -1
  }
  set res [regexp {Request[\s\:]+(\d+)} $buffer ma req]
  if {$res==0} {
    set gaSet(fail) "Read Tx Request of $clk clk fail"
    return -1
  }
  set res [regexp {Response[\s\:]+(\d+)} $buffer ma resp]
  if {$res==0} {
    set gaSet(fail) "Read Tx Response of $clk clk fail"
    return -1
  }
  foreach txt {"Rx Announce" "Rx Sync" "Tx Request" "Tx Response" } val [list $ann $sync $req $resp] {
    set ttxxtt "Clock [set clk], [set txt]: $val"
    AddToPairLog $gaSet(pair) $ttxxtt
    puts $ttxxtt
  }
  # AddToPairLog $gaSet(pair) "Rx Announce: $ann"
  # AddToPairLog $gaSet(pair) "Rx Sync: $sync"
  # AddToPairLog $gaSet(pair) "Tx Request: $req"
  # AddToPairLog $gaSet(pair) "Tx Response: $resp"
  if {$ann==0 || $sync==0 || $req==0 || $resp==0} {
    set gaSet(fail) "Not all counters of $clk g.8275-1 are nonzero"
    return -1
  }
  return 0
}
# ***************************************************************************
# DoorSwitchSetSWDownload
# ***************************************************************************
proc DoorSwitchSetSWDownload {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Set DoorSwitch SW Download"
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DeleteBootFiles]
  if {$ret!=0} {return $ret}
  
  set doorSwApp "C:/download/SW/2_door_C5/sw-pack_2i_10g_b_8sfpp.bin"
  set gaSet(doorSwApp) $doorSwApp
  if {[file exists $doorSwApp]!=1} {
    set gaSet(fail) "The SW file ($doorSwApp) doesn't exist"
    return -1
  }
     
  set tail $gaSet(pair)_[file tail $doorSwApp]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail} cres] {
        set gaSet(fail) "The SW file ($doorSwApp)) can't be deleted"
        puts "[MyTime] SetSWDownload. The file c:/download/temp/$tail ($doorSwApp)) can't be deleted. cres:<$cres>"
        return -1
      }  
    }
  }
    
  file copy -force $doorSwApp c:/download/temp/$tail 
    
  Send $com "\r\r" "\[boot\]:"
  set ret [Send $com "\r\r" "\[boot\]:"]  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail"
    return -1
  }
  #Send $com "c\r" "file name" 
  #Send $com "$tail\r" "device IP"
  Send $com "c\r" "device IP"
  if {$gaSet(pair)==5} {
    set ip 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set ip 10.10.10.111
    } else {
      set ip 10.10.10.1[set gaSet(pair)]
    }  
  }
  Send $com "$ip\r" "device mask"
  Send $com "255.255.255.0\r" "server IP"
  Send $com "10.10.10.10\r" "gateway IP"
  Send $com "10.10.10.10\r" "user"
  Send $com "vxworks\r" "(pw)" ;# vxworks 

  # device name: 8313
  set ret [Send $com "\r" "quick autoboot"]  
  if {$ret!=0} {  
    Send $com "\r" "quick autoboot"
  } 

  Send $com "n\r" "protocol" 
  #Send $com "tftp\12" "baud rate" ;# 9600
  Send $com "ftp\r" "baud rate" ;# 9600
  Send $com "\r" "\[boot\]:"
  
  # Reboot:
  Status "Reset the unit ..."
  Send $com "reset\r" "y/n"
  Send $com "y\r" "\[boot\]:" 10
  append appBuffer $buffer
                                                               
  set i 1
  set ret [Send $com "\r" "\[boot\]:" 2]  
  append appBuffer $buffer
  while {($ret!=0)&&($i<=4)} {
    incr i
    set ret [Send $com "\r" "\[boot\]:" 2]  
    append appBuffer $buffer
  }
  
  if {$ret!=0} {
    set gaSet(fail) "Boot Setup fail."
    return -1 
  } 

  if {[string match {*MNG-ETH port failure*} $appBuffer]==1} {
    set gaSet(fail) "MNG-ETH port failure"
    return -1
  }  
  
  return $ret  
}

# ***************************************************************************
# DoorSwitchAppDownloadTest
# ***************************************************************************
proc DoorSwitchAppDownloadTest {} {
  global gaSet buffer 
  set com $gaSet(comDut)
  
  set tail $gaSet(pair)_[file tail $gaSet(doorSwApp)]
  set rootTail [file rootname $tail]
  
  Status "Wait for download / writing to flash .."
  set gaSet(fail) "Application download fail"
  Send $com "download 1,[set tail]\r" "stam" 3
  if {[string match {*Are you sure(y/n)?*} $buffer]==1} {
    Send $com "y" "stam" 2
  }
  
  if {[string match {*Error*} $buffer]==1} {
    return -1
  }
   
  set ret [MyWaitFor $com "boot" 5 820]
  if {$ret!=0} {return $ret}
  
  catch {file delete -force c:/download/temp/$tail} cres
  after 2000
  if [file exists c:/download/temp/$tail] {
    if [catch {file delete -force c:/download/temp/$tail} cres] {
      set gaSet(fail) "The SW file (c:/download/temp/$tail) can't be deleted"
      puts "[MyTime] SoftwareDownloadTest. The file c:/download/temp/$tail ($gaSet(doorSwApp)) can't be deleted. cres:<$cres>"
      return -1
    }
  }
  
  if {[string match {*FTP transfer error*} $buffer]==1} {
    set gaSet(fail) "FTP transfer error"
    return -1
  }
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
  if {$ret!=0} {return $ret}
  
  set ret [Login]
  if {$ret!=0} {return $ret}
  return $ret
} 

# ***************************************************************************
# DoorSwitchTestPerf
# ***************************************************************************
proc DoorSwitchTestPerf {} {
  global gaSet gaGui buffer
  set com $gaSet(comDut)
  Status "Door Switch Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }

  Send $com "\r\r" stam 0.25 
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure terminal\r" ss 1]  
  set ret [Send $com "console-timeout forever\r\r" ss 1]
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure system\r" ss 1]  
  set ret [Send $com "show device-information\r\r" system]  
  regexp {Hw:\s+([\.\d]+)\/} $buffer - hw
  if ![info exists hw] {
    set gaSet(fail) "Can't read the HW version"
    return -1
  }
  
  Send $com "\r\r" stam 0.25 
  Send $com "exit all\r" stam 0.25 
  puts "hw:$hw"
  
  set gaSet(fail) "Logon fail"

  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 2.25 
  Status "Read Door Switch Register"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  } 
  set ret [Send $com "debug mea\r\r" "FPGA"]
      
  
  if {[package vcompare $hw 0.4]=="-1"} {
    ## if hw < 0.4
    set regSBL {C4 E4 C4}
  } else {
    set regSBL {84 A4 84}
  }
  
  foreach doorState {"Pull Out" "Release" "Push"} regSB $regSBL {
    RLSound::Play information
    set txt "$doorState the Door Button"
    set res [DialogBox -type "Ok Stop" -icon /images/info -title "Door Switch" -message $txt]
    if {$res=="Stop"} {
      return -2
    }
    set ret 0
    set gaSet(fail) "Read Door Switch Register fail"  
    #set ret [Send $com "debug memory address 92000005 read char length 1\r" $gaSet(prompt)]
    set ret [Send $com "mea util comp gp gpr 5\r" FPGA]
    if {$ret!=0} {return $ret}
    #set res [regexp {92000005:\s+(\w+)\s} $buffer - value]
    set res [regexp {05\-\>([\w]+)\s} $buffer m value]
    if {$res==0} {return -1}
    puts "\nRead Door Switch Register value:<$value>\n"; update
    if {$value!=$regSB} {
      set gaSet(fail) "Door Switch Register is \'$value\'. Should be \'$regSB\'"  
      return -1
    }
  }
  
  return $ret
}
# ***************************************************************************
# ReadP1015Code
# ***************************************************************************
proc ReadP1015Code {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Read P1015 Code"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  Status "Read P1015 Code"
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  set gaSet(fail) "Read P1015 Code fail"  
  set ret [Send $com "debug memory address e00e00a0 read long length 10\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set lst  [split $buffer { }]
  set value [lindex $lst [expr {2+[lsearch $lst 0xE00E00A0]}]]
  puts "\ReadP1015Code value:<$value> DutInitName:<$gaSet(DutInitName)>\n"; update
  AddToPairLog $gaSet(pair) "P1015Code: $value"
  if {$value=="80E50011" && ([string match *OD* $gaSet(DutInitName)] || [string match *.H.* $gaSet(DutInitName)])} {
    set gaSet(fail) "P1015 code is \'$value\'. Shouldn't be used on OD or Hardend device"  
    return -1
  }
  if {$value!="80E50011" && $value!="80ED0011"} { 
    set gaSet(fail) "P1015 code is \'$value\'. Shouldn't be used"  
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# SaveRunningConf
# ***************************************************************************
proc SaveRunningConf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Save Running Configuration"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  Send $com "exit all\r" stam 1 
  
  set ret [Send $com "admin save\r" "successfull" 120]
  if {$ret!=0} {set gaSet(fail) "Admin Save fail"; return $ret}
  
  # set ret [Send $com "file copy running-config user-default-config\r" "yes/no" ]
  # if {$ret!=0} {set gaSet(fail) "Copy Running to UserDefault fail"; return $ret}
  # set ret [Send $com "y\r" "successfull" 100]
  return $ret 
}   
# ***************************************************************************
# CheckUserDefaultFilePerf
# ***************************************************************************
proc CheckUserDefaultFilePerf {} {
  global gaSet buffer
  set com $gaSet(comDut)
  Status "Check User Default File"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "file dir\r" more 5]
  if {$ret == 0} {
    set buff $buffer
    Send $com "\r" more 5
    append buff $buffer
    Send $com "\r" $gaSet(prompt)
    append buff $buffer
    set buffer $buff
  }
  puts "\n CheckUserDefaultFilePerf buffer:<$buffer>"
  if [string match {*user-default-config*} $buffer] {
    set ret 0
    set res [regexp {user-default-config[\sa-zA-Z]+(\d+)\s} $buffer ma val]
    if $res {
      AddToPairLog $gaSet(pair) "user-default-config: $val"
    }
  } else {
    set ret -1
    set gaSet(fail) "No \'user-default-config\' in File Dir"
  }
  return $ret
}
# ***************************************************************************
# BistPerf
# ***************************************************************************
proc BistPerf {} {
  global gaSet buffer
  Status "BIST Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  set ret [Send $com "debug mea\r\r" FPGA 11]
  if {$ret!=0} {return $ret}
  
  set dur 30
  set ret [BistRun $dur]
  puts "BistPerf ret of BistRun $dur sec: <$ret>"
  if {$ret==0} {
    set dur 100
    set ret [BistRun $dur]
    puts "BistPerf ret of BistRun $dur sec: <$ret>"
  }
  if {$ret!=0} {
    return $ret
  }
  
  set gaSet(fail) "Exit from MEA fail"
  set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]
    if {$ret!=0} {return $ret}
  }
  
  return $ret
}  

# ***************************************************************************
# BistRun
# ***************************************************************************
proc BistRun {dur} {
  global gaSet buffer
  
  if {$gaSet(act)==0} {return -2}
  set com $gaSet(comDut)
  set ret [Send $com "mea test gen on\r\r" FPGA 30]
  set gaSet(fail) "Start BIST fail"
  if {$ret!=0} {return $ret}
  set ret [Wait "BIST is performing..." $dur]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "mea test gen off\r\r" FPGA]
  set gaSet(fail) "Stop BIST fail"
  if {$ret!=0} {return $ret}
  set ret [Send $com "mea test show\r" FPGA]
  set gaSet(fail) "Check BIST fail"
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1G ports in 8SFPP
    set res1g 1
  } else {
    set res1g [string match {*Nicanor Pass 1G*} $buffer]
  }
  set res10g [string match {*Nicanor Pass 10G*} $buffer]
  puts "\n[MyTime] BistRun 15 res1g:$res1g res10g:$res10g"
  set fail "No Nicanor Pass "
  set ret 0
  if {$res1g==0} {
    append fail "1G "
    set ret -1
  }
  if {$res10g==0} {
    if [string match *1G* $fail] {
      append fail "and "
    }
    append fail "10G "
    set ret -1
  }
  append fail "in BIST result"
  
  if {$ret!=0} {
    set gaSet(fail) $fail
  }
  return $ret
}

# ***************************************************************************
# BistStartStop
# ***************************************************************************
proc BistStartStop {mode} {
  global gaSet buffer
  Status "BIST StartStop $mode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  Send $com "logon\r" stam 0.25 
  if {[string match {*command not recognized*} $buffer]==0} {
    set ret [Send $com "logon debug\r" password]
    if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" $gaSet(prompt) 1]
    if {$ret!=0} {return $ret}
  }      
  
  set ret [Send $com "debug mea\r\r" FPGA 11]
  if {$ret!=0} {return $ret}
  Send $com "mea test gen $mode\r\r" FPGA 
  
  set gaSet(fail) "Exit from MEA fail"
  set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]
  if {$ret!=0} {
    set ret [Send $com "exit\r\r\r" $gaSet(prompt) 16]    
  }
  
  return $ret
}
  
# ***************************************************************************
# ExtClkTxTest
# ***************************************************************************
proc ExtClkTxTest {mode} {
  global gaSet buffer
  Status "ExtClkTxTest $mode"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  if {$mode=="en"} {
    set frc "force-t4-as-t0"
  } else {
    set frc "no force-t4-as-t0"
  }
  set ret [Send $com "con sys clock domain 1 $frc\r" $gaSet(prompt)]
  
}