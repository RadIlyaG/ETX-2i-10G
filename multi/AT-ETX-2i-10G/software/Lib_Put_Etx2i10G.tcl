# ***************************************************************************
# EntryBootMenu
# ***************************************************************************
proc EntryBootMenu {} {
  global gaSet buffer
  puts "[MyTime] EntryBootMenu"; update
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
  if {$ret==0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:" 2]
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
  set ret [Send $gaSet(comDut) \r "stop auto-boot.." 20]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) \r\r "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  return 0
}

# ***************************************************************************
# DownloadUsbPortApp
# ***************************************************************************
proc DownloadUsbPortApp  {} { 
  global gaSet buffer
  puts "[MyTime] DownloadUsbPortApp"; update
  set gaSet(fail) "Config IP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c ip\r" "(ip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.1$gaSet(pair)\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
    
  set gaSet(fail) "Config DM in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c dm\r" "(dm)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "255.255.255.0\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config SIP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c sip\r" "(sip)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config GW in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c g\r" "(g)"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "10.10.10.10\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Config TFTP in Boot Menu fail"
  set ret [Send $gaSet(comDut) "c p\r" "ftp\]"]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "ftp\r" "\[boot\]:"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $gaSet(comDut) "\r" "\[boot\]:"]
  if {$ret!=0} {return $ret} 
  
  set ret [Send $gaSet(comDut) "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $gaSet(comDut) "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Start \'download 3,sw-pack_2i_USB_test.bin\' fail"
  set ret [Send $gaSet(comDut) "download 3,sw-pack_2i_USB_test.bin\r" "transferring" 3]
  if [string match {*you sure(y/n)*} $buffer] {
    set ret [Send $gaSet(comDut) "y\r" "transferring"]    
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
    set ret [RLSerial::Waitfor $gaSet(comDut) buffer "\[boot\]:" 2]
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
  set ret [Send $gaSet(comDut) "\r" "\[boot\]:" 1]
  set ret [Send $gaSet(comDut) "\r" "\[boot\]:" 1]
  set ret [Send $gaSet(comDut) "set-active 3\r" "\[boot\]:" 25]
  if {$ret!=0} {return $ret}  
  Status "Wait for Loading/un-compressing sw-pack-3"
  set ret [Send $gaSet(comDut) "run 3\r" "sw-pack-3.." 50]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
  set gaSet(fail) "Delete UsbPort App fail"
  set ret [Send $gaSet(comDut) "set-active 1\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret} 
  set ret [Send $gaSet(comDut) "delete sw-pack-3\r" "\[boot\]:" 35]
  if {$ret!=0} {return $ret}
  set ret [Send $gaSet(comDut) "run\r" "sw-pack-1.." 55]
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
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
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
  set ret [Send $com "configure chassis\r" >chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" >chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ps=="ACDC"} {
    set psQty 0
    incr psQty [regexp -all AC $buffer]
    incr psQty [regexp -all DC $buffer]
  } else {
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
#     AddToLog $gaSet(fail)
    return -1
  }
  #regexp {\-+\s(.+)\s+FAN} $buffer - psStatus
  regexp {\-+\s(.+\s+FAN)} $buffer - psStatus
  if {$b=="Half19" || $b=="Half19B"} {
    regexp {1\s+\w+\s+([\s\w]+)\s+FAN} $psStatus - ps1Status
  } elseif {$b=="19" || $b=="19B"} { 
    regexp {1\s+\w+\s+([\s\w]+)\s+2} $psStatus - ps1Status
  }
  set ps1Status [string trim $ps1Status]
  
  if {$ps1Status!="OK"} {
    set gaSet(fail) "Status of PS-1 is \'$ps1Status\'. Should be \'OK\'"
#     AddToLog $gaSet(fail)
    return -1
  }
  
  if {$b=="19" || $b=="19B"} {
    regexp {2\s+\w+\s+([\s\w]+)\s+} $psStatus - ps2Status
    set ps2Status [string trim $ps2Status]
    if {$ps2Status!="OK"} {
      set gaSet(fail) "Status of PS-2 is \'$ps2Status\'. Should be \'OK\'"
  #     AddToLog $gaSet(fail)
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
    puts "swSR:$sw"
    set sw [string range $sw 0 end-2]  
  }
  puts "sw:<$sw>"
  puts gaSet(dbrSW):<$gaSet(dbrSW)>
  if {$gaSet(dbrSW)==""} {
    set barcode $gaSet($::pair.barcode1)
    catch {exec $gaSet(javaLocation)\\java -jar c:/RADapps/SWVersions4IDnumber.jar $barcode} b
    puts "GetDbrSW b:<$b>" ; update
    after 1000
    if ![info exists gaSet(swPack)] {
      set gaSet(swPack) ""
    }
    set swIndx [lsearch $b $gaSet(swPack)]  
    if {$swIndx<0} {
      set gaSet(fail) "There is no SW ID for $gaSet(swPack) ID:$barcode. Verify the Barcode."
      return -1
    }
    set dbrSW [string trim [lindex $b [expr {1+$swIndx}]]]
    puts dbrSW:<$dbrSW>
    set gaSet(dbrSW) $dbrSW
  }
  
  if {$sw!=$gaSet(dbrSW)} {
    set gaSet(fail) "SW is \"$sw\". Should be \"$gaSet(dbrSW)\""
    return -1
  }
  
  ## meantime tsi test is performed at Leds_FAN
#   regexp {FAN Status[\s-]+(.+)\sSensor} $buffer ma fanSt
#   if ![info exists fanSt] {
#     set gaSet(fail) "Can't read FAN Status"
#     return -1
#   }
#   puts "fanSt:$fanSt"
#   if {$b=="Half19"} {
#     if {$fanSt!="1 OK"} {
#       set gaSet(fail) "FAN Status is \'$fanSt\'"
#       return -1
#     }
#   } elseif {$b=="19"} { 
#     if {$fanSt!="1 OK 2 OK 3 OK 4 OK"} {
#       set gaSet(fail) "FAN Status is \'$fanSt\'"
#       return -1
#     }
#   }
  
#   set ret [ReadCPLD]
#   if {$ret!=0} {return $ret}
  
  if {![info exists gaSet(uutBootVers)] || $gaSet(uutBootVers)==""} {
    set ret [Send $com "exit all\r" $gaSet(prompt)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "admin reboot\r" "yes/no"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "y\r" "seconds" 20]
    if {$ret!=0} {return $ret}
    set ret [ReadBootVersion noWD noDelBootFiles]
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
# DyingGaspSetup
# ***************************************************************************
proc neDyingGaspSetup {} {
  global gaSet buffer gRelayState
  Status "DyingGaspTest"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set cf $gaSet(DGaspCF)
  set cfTxt "Dying Gasp"
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
#   set dutIp 10.10.10.1[set gaSet(pair)]  
#   for {set i 1} {$i<=20} {incr i} {   
#     set ret [Ping $dutIp]
#     puts "DyingGaspSetup ping after download i:$i ret:$ret"
#     if {$ret!=0} {return $ret}
#   }
  
  foreach {b r p d ps} [split $gaSet(dutFam) .] {}
  if {$b=="19V"} {
    set ret [DnfvPower off] 
    if {$ret!=0} {return $ret} 
  }  
#   if {$ps=="DC"} {
#     Power all off
#     set gRelayState red
#     IPRelay-LoopRed
#     SendEmail "ETX-2I" "Manual Test"
#     RLSound::Play information
#     set txt "Remove the DC PSs and insert AC PSs"
#     set res [DialogBox -type "OK Cancel" -icon /images/question -title "Change PS" -message $txt]
#     update
#     if {$res!="OK"} {
#       return -2
#     } else {
#       set ret 0
#     }
#     Power all on
#     set gRelayState green
#     IPRelay-Green
#   } elseif {$ps=="AC" || $ps=="AC HP"} {
#     Power all off
#     after 1000
#     Power all on
#   }
  Power all off
  after 1000
  Power all on
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }

#   set snmpId [RLScotty::SnmpOpen $dutIp]
#   RLScotty::SnmpConfig $snmpId -version SNMPv3 -user initial
  return $ret
}    
 
# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc DyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
  puts "[MyTime] DyingGaspPerf $psOffOn $psOff"
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
#   set com $gaSet(comDut)
#   Send $com "exit all\r" stam 0.25 

   
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
  #set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [PingTraps $intf $dutIp]
  if {$ret=="-1"} {
    set ret [Wait "Wait Management up" 20 white]
    if {$ret!=0} {return $ret}
    set ret [PingTraps $intf $dutIp]
    if {$ret!=0} {return $ret}
  }

  #file delete -force $resFile
  
  catch {exec arp.exe -d $dutIp} resArp
  puts "[MyTime] resArp:$resArp"
  
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
    if {[string match "*Src: $dutIp*" $fram] && \
       ([string match *4479696e672067617370* $fram] || [string match {*Dying gasp*} $fram] ||\
        [string match *Dyinggasp* [regsub -all \[.\n\ \] [regsub -all \[0-9a-f\]{2} $fram "."] ""]]) } {
      set res 1
      #file delete -force $resFile
      break
    }
  } 
  if {$res} {
    puts "\rFrameB---<$fram>---\r"; update
  }
#   set frameQty [expr {[regexp -all "Frame " $monData] - 1}]
#   for {set fFr 1; set nextFr 2} {$fFr <= $frameQty} {incr fFr} {
#     puts "fFr:$fFr  nextFr:$nextFr"
#     if [regexp "Frame $fFr:.*\\sFrame $nextFr" $monData m] {
#       if [regexp "Src: [set dutIp].*" $m mm] {
#         if [string match *4479696e672067617370* $mm] {
#           puts $mm
#           set res 1
#         }
#       }
#     }
#     puts ""
#     
#     incr nextFr
#     if {$nextFr>$frameQty} {set nextFr 99}
#   }
# 
#   

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

# ***************************************************************************
# DyingGaspPerf
# ***************************************************************************
proc neDyingGaspPerf {psOffOn psOff} {
  global trp tmsg gaSet
#   set ret [OpenSession $dutIp]
#   if {$ret!=0} {return $ret}
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set dutIp 10.10.10.1[set gaSet(pair)]
  set ret [Ping $dutIp]
  if {$ret!=0} {return $ret}
  
  RLScotty::SnmpCloseAllTrap
  for {set wc 1} {$wc<=10} {incr wc} {
    set trp(id) [RLScotty::SnmpOpenTrap tmsg]
    puts "wc:$wc trp(id):$trp(id)"
    if {$trp(id)=="-1"} {
      set ret -1
      set gaSet(fail) "Open Trap failed"
      set ret [Wait "Wait for SNMP session" 5 white]
      if {$ret!=0} {return $ret}
    } else {
      set ret 0
      break
    }
  }
  if {$ret!=0} {return $ret}
  RLScotty::SnmpConfigTrap $trp(id) -version SNMPv3 -user initial ; #SNMPv2c ;# SNMPv1 , SNMPv2c , SNMPv3
  
  set tmsg ""
  #Power $psOff off
  set ret [Send $com "configure port ethernet 0/1\r" "0/1"]
  if {$ret!=0} {
    RLScotty::SnmpCloseTrap $trp(id)
    return $ret
  }
  
  set ret -1
  for {set i 1} {$i<=5} {incr i} {
    set ret [Send $com "shutdown\r" "0/1"]
      if {$ret==0} {
      after 1000
      set ret [Send $com "no shutdown\r" "0/1"]
      if {$ret!=0} {
        RLScotty::SnmpCloseTrap $trp(id)
        return $ret
      }
    }
    puts "tmsgStClk:<$tmsg>"
    if {$tmsg!=""} {
      set ret 0
      break
    }
    after 1000
  }
  if {$ret=="-1"} {
    set gaSet(fail) "Trap is not sent"
    RLScotty::SnmpCloseTrap $trp(id)
    return -1
  }
  
  after 1000
  set tmsg ""
  
  Power $psOffOn on
  Power $psOff off
  Wait "Wait for trap 1" 3 white
  puts "tmsgDG 1.1:<$tmsg>"
  set tmsg ""
  puts "tmsgDG 1.2:<$tmsg>"
  
  foreach {b r p d ps} [split $gaSet(dutFam) .] {}
  if {$b=="19V"} {
    set ret [DnfvPower off] 
    if {$ret!=0} {return $ret} 
  }  
  
  Power $psOffOn off
  Wait "Wait for trap 2" 3 white 
   
  #set ret [regexp -all "$dutIp\[\\s\\w\\:\\-\\.\\=\]+\\\"\\w+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\:\\-\\.\]+\\\"\[\\s\\w\\:\\-\\.\\=\]+\\\"\[\\w\\-\]+\\\"" $tmsg v]  
  puts "tmsgDG 2:<$tmsg>"
  set res [regexp "from\\s$dutIp:\\s\.\+\:systemDyingGasp" $tmsg -]
  Power $psOffOn on
  
  # Close sesion:
  RLScotty::SnmpCloseTrap $trp(id)  

  if {$res==1} {
    set ret 0
  } elseif {$res==0} {
    set ret -1
    set gaSet(fail) "No \"DyingGasp\" trap was detected"
  }
  return $ret
  
}

# ***************************************************************************
# XFP_ID_Test
# ***************************************************************************
proc XFP_ID_Test {} {
  global gaSet buffer
  Status "XFP_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 10Gp {3/1 3/2 4/1 4/2} {
    if {$gaSet(10G)=="2" && ($10Gp=="3/1" || $10Gp=="3/2")} {
      continue
    }
    if {$gaSet(10G)=="3" && $10Gp=="3/2"} {
      continue
    }
    Status "XFP $10Gp ID Test"
    set gaSet(fail) "Read XFP status of port $10Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $10Gp\r" #]
    if {$ret!=0} {return $ret}
    set ret [Send $com "show status\r" "MAC Address" 20]
    if {$ret!=0} {return $ret}
    set b $buffer
    set ::b1 $b
      
    set ret [Send $com "\r" #]
    if {$ret!=0} {return $ret}
    append b $buffer
    set ::b2 $b
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $b - connType]
    set connType [string trim $connType]
    if {$connType!="XFP In"} {
      set gaSet(fail) "XFP status of port $10Gp is \"$connType\". Should be \"XFP In\"" 
      set ret -1
      break 
    }
    set xfpL [list "XFP-1D" XPMR01CDFBRAD]
    regexp {Part Number[\s:]+([\w\-]+)\s} $b - xfp
    if ![info exists xfp] {
      puts "b:<$b>"
      puts "b1:<$::b1>"
      puts "b2:<$::b2>"
      set gaSet(fail) "Port $10Gp. Can't read XFP's Part Number"
      return -1
    }
#     if {$xfp!="XFP-1D"} {}
    if {[lsearch $xfpL $xfp]=="-1"} {
      set gaSet(fail) "XFP Part Number of port $10Gp is \"$xfp\". Should be one from $xfpL" 
      set ret -1
      break 
    }    
  }
  return $ret  
}

# ***************************************************************************
# SfpUtp_ID_Test
# ***************************************************************************
proc neSfpUtp_ID_Test {} {
  global gaSet buffer
#   if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#     ## don't check ports UTP
#     return 0
#   }
  Status "SfpUtp_ID_Test"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  
  foreach 1Gp {1/1 1/2 1/3 1/4 1/5 1/6 1/7 1/8 1/9 1/10 2/1 2/2 2/3 2/4 2/5 2/6 2/7 2/8 2/9 2/10} {
    if {($gaSet(1G)=="10SFP" || $gaSet(1G)=="10UTP") && [lindex [split $1Gp /] 0]==2} {
      ## dont check ports 2/x
      continue
    }
#     if {$gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP"} {
#       ## dont check ports UTP
#       set ret 0
#       break
#     }
#     if {$gaSet(1G)=="10SFP_10UTP" && [lindex [split $1Gp /] 0]==2} {
#       ## dont check ports UTP  2/x
#       continue
#     }
    Status "SfpUtp $1Gp ID Test"
    set gaSet(fail) "Read SfpUtp status of port $1Gp fail"
    Send $com "exit all\r" stam 0.25 
    set ret [Send $com "configure port ethernet $1Gp\r" #]
    if {$ret!=0} {return $ret}
    if [string match {*Entry instance doesn't exist*} $buffer] {
      set gaSet(fail) "Status of port $1Gp is \"Entry instance doesn't exist\"." 
      set ret -1
      break
    }
    set ret [Send $com "show status\r\r" "#" 20]
    if {$ret!=0} {return $ret}    
    set res [regexp {Connector Type\s+:\s+(.+)Auto} $buffer - connType]
    set connType [string trim $connType]
    if {([lindex [split $1Gp /] 0]==1 && ($gaSet(1G)=="10UTP" || $gaSet(1G)=="20UTP")) ||\
        ([lindex [split $1Gp /] 0]==2 && ($gaSet(1G)=="10SFP_10UTP" || $gaSet(1G)=="20UTP"))} {
      ## 1/x ports
      ## 2/x ports
      set conn "RJ45" 
      set name "UTP"
    } else {
      set conn "SFP In"
      set name "SFP"
    } 
    
    if {$connType!=$conn} {
      set gaSet(fail) "$name status of port $1Gp is \"$connType\". Should be \"$conn\"" 
      set ret -1
      break 
    }
    if {$name=="SFP"} {
      regexp {Part Number[\s:]+([\w\-]+)\s} $buffer - sfp
      if ![info exists sfp] {
        set gaSet(fail) "Can't read SFP's Part Number"
        return -1
      }
      set sfpL [list "SFP-5D" "SFP-6D" "SFP-6H" "SFP-30" "SFP-6" "SPGBTXCNFCRAD" "EOLS-1312-10-RAD" "EOLS131210RAD"]
      if {[lsearch $sfpL $sfp]=="-1"} {
        set gaSet(fail) "SFP Part Number of port $1Gp is \"$sfp\". Should be one from $sfpL" 
        set ret -1
        break 
      }
    }
    
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
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
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
  regexp {MAC\s+Address[\s:]+([\w\-]+)} $buffer - mac
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
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
#   set ret [MyWaitFor $gaSet(comDut) {ETX-2I user>} 5 1]
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $gaSet(comDut) "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $gaSet(comDut) n\r stam 1
   append gaSet(loginBuffer) "$buffer"
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $gaSet(comDut) \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $gaSet(comDut) exit\r\r -2I
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $gaSet(comDut) \x1F\r\r -2I
  }
  if {[string match *-2I* $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    return 0
  }
  if {[string match *ETX-2i* $buffer]} {
    set gaSet(prompt) "ETX-2i"
    set ret 0
    return 0
  }
  if {[string match *ztp* $buffer]} {
    set ret 0
    set gaSet(prompt) "ztp"
    return 0
  }
  if {[string match *CUST-LAB* $buffer]} {
    set ret 0
    set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
    return 0
  }
  if {[string match *WallGarden_TYPE-5* $buffer]} {
    set ret 0
    set gaSet(prompt) "WallGarden_TYPE-5"
    return 0
  }
  if {[string match *BOOTSTRAP-2I10G* $buffer]} {
    set ret 0
    set gaSet(prompt) "BOOTSTRAP-2I10G"
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    set gaSet(prompt) "ETX-2I"
    return 0
  } 
  if {[string match *user* $buffer]} {
    Send $gaSet(comDut) su\r stam 0.25
    puts "login user1 prmpt:<$gaSet(prompt)>"
    set ret [Send $gaSet(comDut) 1234\r $gaSet(prompt)]
    if {[string match *ETX-2i* $buffer]} {
      set gaSet(prompt) "ETX-2i"
      set ret 0
    }
    $gaSet(runTime) configure -text ""
    #set gaSet(prompt) "ETX-2I"
    puts "login user2 prmpt:<$gaSet(prompt)> ret:<$ret>"
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
    Send $gaSet(comDut) \r stam 5
    
    append gaSet(loginBuffer) "$buffer"
    puts "<$gaSet(loginBuffer)>\n" ; update
    foreach ber $gaSet(bootErrorsL) {
      if [string match "*$ber*" $gaSet(loginBuffer)] {
       set gaSet(fail) "\'$ber\' occured during ETX's up"  
        return -1
      } else {
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $gaSet(comDut) {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {      
      puts "if1 <$buffer>"
      set ret 0
      break
    }
    ## exit from boot menu 
    if {[string match *boot* $buffer]} {
      Send $gaSet(comDut) run\r stam 1
      append gaSet(loginBuffer) "$buffer"
    }   
    if {[string match *login:* $buffer]} { }
    if {[string match *:~$* $buffer] || [string match *login:* $buffer] || [string match *Password:* $buffer]} {
      Send $gaSet(comDut) \x1F\r\r -2I
      return 0
    }
    if {[string match {*C:\\*} $buffer]} {
      set ret 0
      return 0
    } 
  }
  if {$ret==0} {
    if {[string match *user* $buffer]} {
      Send $gaSet(comDut) su\r stam 1
      set ret [Send $gaSet(comDut) 1234\r "2I" 3]
      if {[string match *220* $buffer]} {
        set gaSet(prompt) "ETX-220"
        set ret 0
      }
      if {[string match *203* $buffer]} {
        set gaSet(prompt) "ETX-203"
        set ret 0
      }
      if {[string match *ztp* $buffer]} {
        set gaSet(prompt) "ztp"
        set ret 0
      }
      if {[string match *ETX-2I* $buffer]} {
        set gaSet(prompt) "ETX-2I"
        set ret 0
      }
      if {[string match *CUST-LAB* $buffer]} {
        set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        set ret 0
      }
      if {[string match *WallGarden_TYPE-5* $buffer]} {
        set gaSet(prompt) "WallGarden_TYPE-5"
        set ret 0
      }
      if {[string match *BOOTSTRAP-2I10G* $buffer]} {
        set gaSet(prompt) "BOOTSTRAP-2I10G"
        set ret 0
      } 
      if {[string match *ETX-2i* $buffer]} {
        set gaSet(prompt) "ETX-2i"
        set ret 0
      }    
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to ETX-2I Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# FormatFlash
# ***************************************************************************
proc FormatFlash {} {
  global gaSet buffer
  set com $gaSet(comDut)
  
  Power all on 
  
  return $ret
}
# ***************************************************************************
# FactDefault
# ***************************************************************************
proc FactDefault {mode wdMode delBootFiles} {
  global gaSet buffer 
  Status "FactDefault $mode $wdMode $delBootFiles"
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set com $gaSet(comDut)
  
  
  set gaSet(fail) "Set to Default fail"
  Send $com "exit all\r" stam 0.25 
  Status "Factory Default..."
  if {$mode=="std"} {
    set ret [Send $com "admin factory-default\r" "yes/no" ]
  } elseif {$mode=="stda"} {
    set ret [Send $com "admin factory-default-all\r" "yes/no" ]
  }
  if {$ret!=0} {return $ret}
  #set ret [Send $com "y" "stam" 1]
  set ret [Send $com "y\r\r" "seconds" 20]
  if {$ret!=0} {return $ret}
  
  set ret [ReadBootVersion $wdMode $delBootFiles]
  if {$ret!=0} {return $ret}
  
  if {$gaSet(pair)==5 && [llength [PairsToTest]]>1} {
    ## in multi with more than 1 unit - don't wait
    set ret 0
  } else {
    set ret [Wait "Wait DUT down" 20 white]
  }
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    set ret [FactDefault stda noWD noDelBootFiles]
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
proc ReadBootVersion {wdMode delBootFiles} {
  global gaSet buffer
  puts "ReadBootVersion $wdMode $delBootFiles"
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
  
  if {$delBootFiles=="yes"} {
    set ret [EntryBootMenu]
    if {$ret!=0} {
      set gaSet(fail) "Can't entry into the boot"
      return $ret
    }
    Status "Delete Boot Files"
    Send $com "dir\r" "\[boot\]:"
    set ret6 [regexp -all {user-default-config} $buffer]
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
  }
  if {$wdMode=="wd"} {
    set ret [EntryBootMenu]
    if {$ret!=0} {
      set gaSet(fail) "Can't entry into the boot"
      return $ret
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
  Send $com "run\r" stam 2
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
  set gaSet(fail) "Read PS status fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  if {$ps==1} {
    regexp {1\s+[AD]C\s+([\w\s]+)\s2} $buffer - val
  } elseif {$ps==2} {
    regexp {2\s+[AD]C\s+([\w\s]+)\sFAN} $buffer - val
  }
  set val [string trim $val]
  puts "ShowPS val:<$val>"
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
#   Send $com "exit\r" stam 0.25 
#   set ret [Send $com "ethernet 4/2\r" (4/2)]
#   if {$ret!=0} {return $ret}
#   if {$mode=="off"} {
#     set ret [Send $com "no loopback\r" (4/2)]
#   } elseif {$mode=="on"} {
#     set ret [Send $com "loopback remote\r" (4/2)]
#   }
#   if {$ret!=0} {return $ret}
  
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
  set ret [Send $com "y\r" "successfull" 60]
  
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    if {$gaSet(dbrSW)=="6.7.1(0.58)" && ([string match {*PSBUS Read Write PSid = 2 add = 0x3b*} $buffer] || \
        [string match {*PSBUS_write PSid = 2 add = 0x3b*} $buffer])} {
      #24/11/2020 13:14:09
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
  
  set tail [file tail $gaSet(SWCF)]
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
 
  Status "Wait for set active 1 .."
  set ret [Send $com "set-active 1\r" "SW set active 1 completed successfully" 30] 
  if {$ret!=0} {
    set gaSet(fail) "Activate SW Pack1 fail"
    return -1
  }
  
  Status "Wait for loading start .."
  set ret [Send $com "run\r" "Loading" 30]
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
  set ret [Send $com "show status\r" more 8]
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
      set gaSet(fail) "Read Manufacturer Part Number of SFP in port $port fail"
      return -1
    } 
  }
  set val [string trim $val]
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
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    
    #dec to Hex
    set x [format %.2x $::pair]
    
    # Config Setup:
    Send $com "env set ethaddr 00:20:01:02:03:$x\r" "=>"
    Send $com "env set netmask 255.255.255.0\r" "=>"
    Send $com "env set gatewayip 10.10.10.10\r" "=>"
    Send $com "env set ipaddr 10.10.10.1[set ::pair]\r" "=>"
    Send $com "env set serverip 10.10.10.10\r" "=>"
    
    # Download Comment: download command is: run download_vxboot
    # the download file name should be always: vxboot.bin
    # else it will not work !
    if [file exists c:/download/temp/vxboot.bin] {
      file delete -force c:/download/temp/vxboot.bin
    }
    if {[file exists $gaSet(BootCF)]!=1} {
      set gaSet(fail) "The BOOT file ($gaSet(BootCF)) doesn't exist"
      return -1
    }
    file copy -force $gaSet(BootCF) c:/download/temp              
    #regsub -all {\.[\w]*} $gaSet(BootCF) "" boot_file
    
    
        
    # Download:   
    Send $com "run download_vxboot\r" stam 1
    set ret [Wait "Download Boot in progress ..." 10]
    if {$ret!=0} {return $ret}
    
    file delete -force c:/download/temp/vxboot.bin
    
    
    Send $com "\r\r" "=>" 1
    Send $com "\r\r" "=>" 3
    
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
# SetDownload
# ***************************************************************************
proc SetDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer
  set ret [GetPageFile $gaSet($::pair.barcode1)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload {run} {
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [SoftwareDownloadTest]
  if {$ret!=0} {return $ret}
  
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
    set ret [MyWaitFor $com "boot]:" 5 1200]
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
     
  ## C:/temp/SW/6.0.1_0.32/etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin -->> \
  ## etxa_6.0.1(0.32)_sw-pack_2iB_10x1G_sr.bin
  set tail [file tail $gaSet(SWCF)]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 1000
  }
    
  file copy -force $gaSet(SWCF) c:/download/temp 
  
  #gaInfo(TftpIp.$::ID) = 10.10.8.1 (device IP)
  #gaInfo(PcIp) = "10.10.10.254" (gateway IP/server IP)
  #gaInfo(mask) = "255.255.248.0"  (device mask)  
  #gaSet(Apl) = C:/Apl/4.01.10sw-pack_203n.bin

  
  # Config Setup:
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
      set gaSet(fail) "Use-str-config delete fail
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
# SpeedEthPort
# ***************************************************************************
proc neSpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
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
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "exit all\r" $gaSet(prompt)]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure chassis\r" chassis]
  if {$ret!=0} {return $ret}
  set ret [Send $com "show environment\r" chassis]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  regexp {FAN Status[\s-]+(.+)\sSensor} $buffer ma fanSt
  if ![info exists fanSt] {
    set gaSet(fail) "Can't read FAN Status"
    return -1
  }
  puts "fanSt:$fanSt"
  AddToPairLog $::pair "FAN Status: $fanSt"
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
    if {$fanSt!="1 OK 2 OK"} {
      set gaSet(fail) "FAN Status is \'$fanSt\'"
      return -1
    }
  }
  
  if {$np=="8SFPP" && $up=="0_0"} {}
  if 1 {
    Send $com "exit all\r" stam 0.25 
    Send $com "logon\r" stam 0.25 
    Status "Fan EEPROM Burn"
    if {[string match {*command not recognized*} $buffer]==0} {
      set ret [Send $com "logon debug\r" password]
      if {$ret!=0} {return $ret}
      regexp {Key code:\s+(\d+)\s} $buffer - kc
      catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    set ret [Send $com "st\r" stam 1]
    #if {$ret!=0} {return $ret}
    
    foreach vv {A B D F G C E H I J} {set $vv na}
    if {($np=="8SFPP" && $up=="0_0" && [string match *B.8.5.* $gaSet(DutInitName)]) || $b=="Half19B" || $b=="Half19"} {
      set fans 1
      set res [regexp {st\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F]
    } elseif {($np=="8SFPP" && $up=="0_0" && [string match *B.19.* $gaSet(DutInitName)] && ![string match *B.19.N.* $gaSet(DutInitName)]) ||\
              ($b=="19B")} {
      set fans 2
      set res [regexp {st\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G]
    } elseif {($np=="8SFPP" && $up=="0_0" && [string match *B.19.N.* $gaSet(DutInitName)])} {
      set fans 4
      set checkJ no
      set res [regexp {st\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G x1 J C E H I]    
    } elseif {($b=="19")} {
      set fans 4
      set checkJ yes
      set res [regexp {st\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G x1 J C E H I]    
    }
    puts "ST fans-$fans"
    if {$res==0} {
      set gaSet(fail) "Read ST fail"
      return -1
    }
    foreach vv {A B D F G C E H I J} {
      puts "ST fans-$fans $vv [set $vv]"
      AddToPairLog $::pair "$vv [set $vv]"
    }
    
    if {$A<20 || $A>70} {
      set gaSet(fail) "A is $A. Should be between 20 and 70"
      return -1  
    }
    if {$B<20 || $B>70} {
      set gaSet(fail) "B is $B. Should be between 20 and 70"
      return -1  
    }
    if {$fans==4} {
      if {$C<20 || $C>70} {
        set gaSet(fail) "C is $C. Should be between 20 and 70"
        return -1  
      }
    }
    
    set diff [expr abs([expr {$A-$B}])]
    if {$diff>8} {
      set gaSet(fail) "The difference between A and B is $diff. Should be <= 10"
      return -1  
    }
    if {$fans==4} {
      set diff [expr abs([expr {$A-$C}])]
      if {$diff>10} {
        set gaSet(fail) "The difference between A and C is $diff. Should be <= 10"
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
      if {$checkJ=="yes" && ($J<20 || $J>70)} {
        set gaSet(fail) "J is $J. Should be between 20 and 70"
        return -1  
      }
    }
    set ret 0
    
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
    catch {exec c:/RADapps/atedecryptor.exe $kc pass} password
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
    
    set ret [FactDefault stda noWD noDelBootFiles]
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
# Login8Sfpp
# ***************************************************************************
proc Login8Sfpp {} {
  global gaSet buffer gaLocal
  set ret 0
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into ETX-2i"
#   set ret [MyWaitFor $com {ETX-2I user>} 5 1]
  set com $gaSet(comMicroUsb)
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  if {([string match {*-2I*} $buffer]==0) && ([string match {*user>*} $buffer]==0)} {
    set ret -1  
  } else {
    set ret 0
  }
  if {[string match {*Are you sure?*} $buffer]==1} {
   Send $com n\r stam 1
   append gaSet(loginBuffer) "$buffer"
  }
   
   
  if {[string match *password* $buffer] || [string match {*press a key*} $buffer]} {
    set ret 0
    Send $com \r stam 0.25
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *FPGA* $buffer]} {
    set ret 0
    Send $com exit\r\r -2I
    append gaSet(loginBuffer) "$buffer"
  }
  if {[string match *:~$* $buffer] || [string match *login:* $buffer] || \
      [string match *Password:* $buffer]  || [string match *rad#* $buffer]} {
    set ret 0
    Send $com \x1F\r\r -2I
  }
  if {[string match *-2I* $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "ETX-2I"
    return 0
  }
  if {[string match *ETX-2i* $buffer]} {
    set gaSet(prompt8Sfpp) "ETX-2i"
    set ret 0
    return 0
  }
  if {[string match *ztp* $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "ztp"
    return 0
  }
  if {[string match *CUST-LAB* $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "CUST-LAB-ETX203PLA-1"
    return 0
  }
  if {[string match *WallGarden_TYPE-5* $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "WallGarden_TYPE-5"
    return 0
  }
  if {[string match *BOOTSTRAP-2I10G* $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "BOOTSTRAP-2I10G"
    return 0
  }
  if {[string match {*C:\\*} $buffer]} {
    set ret 0
    set gaSet(prompt8Sfpp) "ETX-2I"
    return 0
  } 
  if ![info exists gaSet(prompt8Sfpp)] {
    set gaSet(prompt8Sfpp)  "ETX-2i"
  }
  if {[string match *user* $buffer]} {
    Send $com su\r stam 0.25
    puts "login user1 prmpt:<$gaSet(prompt8Sfpp)>"
    set ret [Send $com 1234\r $gaSet(prompt8Sfpp)]
    if {[string match *ETX-2i* $buffer]} {
      set gaSet(prompt8Sfpp) "ETX-2i"
      set ret 0
    }
    $gaSet(runTime) configure -text ""
    #set gaSet(prompt8Sfpp) "ETX-2I"
    puts "login user2 prmpt:<$gaSet(prompt8Sfpp)> ret:<$ret>"
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
        puts "[MyTime] \'$ber\' was not found"
      } 
    }
    
    #set ret [MyWaitFor $com {ETX-2I user> } 5 60]
    if {([string match {*-2I*} $buffer]==1) || ([string match {*user>*} $buffer]==1)} {      
      puts "if1 <$buffer>"
      set ret 0
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
      set ret [Send $com 1234\r "2I" 3]
      if {[string match *220* $buffer]} {
        set gaSet(prompt8Sfpp) "ETX-220"
        set ret 0
      }
      if {[string match *203* $buffer]} {
        set gaSet(prompt8Sfpp) "ETX-203"
        set ret 0
      }
      if {[string match *ztp* $buffer]} {
        set gaSet(prompt8Sfpp) "ztp"
        set ret 0
      }
      if {[string match *ETX-2I* $buffer]} {
        set gaSet(prompt8Sfpp) "ETX-2I"
        set ret 0
      }
      if {[string match *CUST-LAB* $buffer]} {
        set gaSet(prompt8Sfpp) "CUST-LAB-ETX203PLA-1"
        set ret 0
      }
      if {[string match *WallGarden_TYPE-5* $buffer]} {
        set gaSet(prompt8Sfpp) "WallGarden_TYPE-5"
        set ret 0
      }
      if {[string match *BOOTSTRAP-2I10G* $buffer]} {
        set gaSet(prompt8Sfpp) "BOOTSTRAP-2I10G"
        set ret 0
      } 
      if {[string match *ETX-2i* $buffer]} {
        set gaSet(prompt8Sfpp) "ETX-2i"
        set ret 0
      }    
    }
  }  
  if {$ret!=0} {
    set gaSet(fail) "Login to 8SFPP Fail"
  }
  $gaSet(runTime) configure -text ""
  if {$gaSet(act)==0} {return -2}
  Status $statusTxt
  return $ret
}
# ***************************************************************************
# 8SfppPortState
# ***************************************************************************
proc 8SfppPortState {opL} {
  global gaSet buffer
  set com $gaSet(comMicroUsb)
  set ret [Login8Sfpp]
  if {$ret!=0} {return $ret}
  
  for {set po 1} {$po <= 7} {incr po} {
    Status "Shutdown port 0/$po"
    set gaSet(fail) "Shutdown port $po of the 8SFPP Fail"
    set ret [Send $com "exit all\r" $gaSet(prompt8Sfpp)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "config port ethernet 0/$po\r" "(0/$po)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "shutdown\r" "(0/$po)"]
    if {$ret!=0} {return $ret}
  }
  
  foreach po $opL {
    Status "No shutdown port 0/$po"
    set gaSet(fail) "No shutdown port $po of the 8SFPP Fail"
    set ret [Send $com "exit all\r" $gaSet(prompt8Sfpp)]
    if {$ret!=0} {return $ret}
    set ret [Send $com "config port ethernet 0/$po\r" "(0/$po)"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "no shutdown\r" "(0/$po)"]
    if {$ret!=0} {return $ret}
  }
  return $ret
}