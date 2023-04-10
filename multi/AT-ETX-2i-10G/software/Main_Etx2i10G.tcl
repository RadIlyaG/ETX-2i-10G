# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  set gaSet(lWidthTests1)     [list]
  set gaSet(lTogetherTests1)  [list]
  #set gaSet(lSerialTests1)    [list]
  set gaSet(lTogetherTests2)  [list]
  set gaSet(lWidthTests2)     [list]
  set gaSet(lWidthTests3)     [list]
  set glTests [list]
  
  RetriveDutFam 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  if {$gaSet(chBAH)==0} {
    set gaSet(lWidthTests1) [list BootDownload SetDownload Pages SoftwareDownload]
  
    if {$b=="Half19" || $b=="Half19B" || $b=="19B"} {
      lappend gaSet(lWidthTests1) FanEepromBurn
    } 
    
  ## 09/01/2018 07:43:31 All products should be tested with 4 10GbE ports open
  ## therefor we open the license to all
    if {$np=="8SFPP" && $up=="0_0"} {
      ## in Itzik's product there is no License
    } else {
      lappend gaSet(lWidthTests1) OpenLicense
    }
  }
  
  lappend gaSet(lWidthTests1) SetToDefault_beforeLeds
  lappend gaSet(lWidthTests1) Leds_FAN_conf 
  
  lappend gaSet(lTogetherTests1) Leds_FAN
  
  ## start lSerialTests1
  lappend gaSet(lWidthTests2) FanTemperature SetToDefaultWD
  if {[string match *.12CMB.* $gaSet(DutInitName)]==0} {
    ## if a product is NOT CMB, we cheeck ID now
    ## CMB will be checked after download its SW
    lappend gaSet(lWidthTests2) ID
    if {$np=="8SFPP" && $up=="0_0"} {
      ## in Itzik's product there are only SFPs, no UTP
    } else {
      lappend gaSet(lWidthTests2) UTP_ID
    }
    lappend gaSet(lWidthTests2) SFP_ID
  }
    
  ## from 23/07/2020 08:08:40 USB port is not checked
#   if {$b=="Half19" || $b=="19"} {
#     lappend lTestNames USBport
#   } 
  lappend gaSet(lWidthTests2) DyingGasp_conf DyingGasp_run
  lappend gaSet(lWidthTests2) DataTransmission_conf DataTransmission_run
  
  if {$p=="P"} {
    lappend gaSet(lWidthTests2) ExtClk SyncE_conf SyncE_run
  }
  lappend gaSet(lWidthTests2) DDR 
     
  lappend gaSet(lWidthTests2) SetToDefault
  
#   15/11/2020 07:54:23 Leds were checked on start
#   lappend lTestNames Leds_FAN_conf Leds_FAN
  
#   if {$np=="8SFPP" && $up=="0_0"} {
#     lappend lTestNames FD_button
#   } 
  
  if {[string match *.12CMB.* $gaSet(DutInitName)]==1} {
    lappend gaSet(lWidthTests2) Combo_PagesSW ID Combo_SFP_ID Combo_UTP_ID
  }
  if {$np=="npo" || $np=="2SFPP"} {
    lappend gaSet(lWidthTests2) CloseLicense
  } 
  
  
  if {$gaSet(DefaultCF)!="" && $gaSet(DefaultCF)!="c:/aa"} {
    lappend gaSet(lWidthTests2) LoadDefaultConfiguration
  }
  ### end of lSerialTests1
  lappend gaSet(lTogetherTests2) Leds_AllCablesOFF Mac_BarCode
  #lappend gaSet(lWidthTests3) 
  
#   set lTests [concat $gaSet(lWidthTests1)  $gaSet(lTogetherTests1) $gaSet(lSerialTests1) $gaSet(lTogetherTests2) $gaSet(lWidthTests2)]
  set lTests [concat $gaSet(lWidthTests1)  $gaSet(lTogetherTests1) $gaSet(lWidthTests2) $gaSet(lTogetherTests2)]
    
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}
# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests glPassPair glFailPair gaGui

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  set glPassPair [list]
  set glFailPair [list]
    
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  
#   foreach pair [PairsToTest] {    
#     set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
#     set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   }

  if {$gaSet(oneTest)==1} {
    set lRunTests [lindex  [split $gaSet(startFrom) .] end]
    set gaSet(oneTest) 0
  }   
  
  puts "\n[MyTime] Testing gaSet(lWidthTests1):$gaSet(lWidthTests1) \nlRunTests:<$lRunTests>\n"
  foreach WidthTests1 $gaSet(lWidthTests1) {
    if {$gaSet(act)==0} {return -2}
    puts "gaSet(lWidthTests1) PairsToTest:[PairsToTest]"
    if {[llength [PairsToTest]]==0} {break}
    set WidthTests1indx [lsearch -glob $lRunTests *$WidthTests1]
    if {$WidthTests1indx=="-1"} {
      puts "Start after $WidthTests1"
      continue
    }  
    set numberedTest [lindex $lRunTests $WidthTests1indx]
    set testName [lindex [split $numberedTest ..] end]
    puts "\n[MyTime] WidthTests1 WidthTests1:$WidthTests1 WidthTests1indx:$WidthTests1indx numberedTest:$numberedTest"
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
    #$gaSet(startTime) configure -text "$startTime ."
    
    foreach pair [PairsToTest] {
      if {$gaSet(act)==0} {return -2}
      
      set ::pair $pair
#       if {$gaSet(pair)=="5"} {
#         AddToPairLog $::pair "Test \'$testName\' start"
#       } else {   
#         AddToPairLog $gaSet(pair) "Test \'$testName\' start"    
#       }
      AddToPairLog $::pair "Test \'$testName\' start"
      puts "\n **** DUT ${pair}. Test $numberedTest start; [MyTime] "
      $gaSet(runTime) configure -text ""
      update
      PairPerfLab $pair yellow
      MassConnect $pair
      
      set ret [$testName 1]
      if {$ret==0} {
        set retTxt "PASS."
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"
      }
#       if {$gaSet(pair)=="5"} {
#         AddToPairLog $::pair "Test \'$testName\' $retTxt"
#       } else {   
#         AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"    
#       }
      AddToPairLog $::pair "Test \'$testName\' $retTxt"
         
      puts "\n **** DUT $pair. Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
      if {$ret==0} {
        PairPerfLab $pair #ddffdd ; #$gaSet(halfPassClr) ; # #ccffcc ; #green  ; #ddffdd
        lappend glPassPair $pair      
        set retTxt Pass
      } else {
        PairPerfLab $pair red
        set retTxt Fail
        lappend glFailPair $pair
        set gaSet(runStatus) Fail
        SQliteAddLine $pair
      }            
    } 
#     if {$gaSet(oneTest)==1} {
#       set ret 1
#       set gaSet(oneTest) 0
#       break
#     } 
  } 
  
  puts "\n[MyTime] gaSet(lTogetherTests1):$gaSet(lTogetherTests1) \nlRunTests:<$lRunTests>\n"
  foreach TogetherTests1 $gaSet(lTogetherTests1) {
    if {$gaSet(act)==0} {return -2}
    puts "gaSet(lTogetherTests1) PairsToTest:[PairsToTest]"
    if {[llength [PairsToTest]]==0} {break}
    set TogetherTests1indx [lsearch -glob $lRunTests *$TogetherTests1]
    if {$TogetherTests1indx=="-1"} {
      puts "Start after $TogetherTests1"
      continue
    }  
    set numberedTest [lindex $lRunTests $TogetherTests1indx]
    set testName [lindex [split $numberedTest ..] end]
    puts "\n[MyTime] lTogetherTests1 TogetherTests1:$TogetherTests1 TogetherTests1indx:$TogetherTests1indx numberedTest:$numberedTest"
    set gaSet(curTest) $numberedTest
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
    #$gaSet(startTime) configure -text "$startTime ."
    
#     if {$gaSet(pair)=="5"} {
#       foreach pair [PairsToTest] {
#         AddToPairLog $pair "Test \'$testName\' start"
#       }
#     } else {   
#       AddToPairLog $gaSet(pair) "Test \'$testName\' start"    
#     } 
    foreach pair [PairsToTest] {
      AddToPairLog $pair "Test \'$testName\' start"
    }     
    $gaSet(runTime) configure -text ""
    update
    set ret [$testName 1]
    puts "********* TogetherTests1 $TogetherTests1 finish ret:<$ret> *********..[MyTime]..\n\n"
  }  
    
    ################
#   foreach pair [PairsToTest] {
#     if {$gaSet(act)==0} {return -2}
#       
#     set ::pair $pair
#     puts "\n\n ********* DUT-$pair start *********..[MyTime].."
#     
#     set gaSet(curTest) ""
#     update
#       
# #     if {$gaSet(pair)=="5"} {
# #       AddToPairLog $::pair "********* DUT $pair start *********"
# #     } else {
# #       AddToPairLog $gaSet(pair) "********* DUT start *********"
# #     }
#     AddToPairLog $pair "********* DUT $pair start *********"
#     
#     PairPerfLab $pair yellow
#     MassConnect $pair
#     
#     puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"    
#   
#     #foreach numberedTest $lRunTests {}
#     foreach SerialTests1 $gaSet(lSerialTests1) {
#       if {$gaSet(act)==0} {return -2}
#       set SerialTests1indx [lsearch -glob $lRunTests *$SerialTests1]
#       if {$SerialTests1indx=="-1"} {
#         puts "Start after $SerialTests1"
#         continue
#       }  
#       set numberedTest [lindex $lRunTests $SerialTests1indx]
#       set testName [lindex [split $numberedTest ..] end]
#       puts "\n[MyTime] lSerialTests1 SerialTests1:$SerialTests1 SerialTests1indx:$SerialTests1indx numberedTest:$numberedTest"
#       set gaSet(curTest) $numberedTest
#       update
#     
#       MuxMngIO ioToGenMngToPc ioToGen
#         
#       $gaSet(startTime) configure -text "$startTime ."
# #       if {$gaSet(pair)=="5"} {
# #         AddToPairLog $::pair "Test \'$testName\' start"
# #       } else {   
# #         AddToPairLog $gaSet(pair) "Test \'$testName\' start"    
# #       }
#       AddToPairLog $pair "Test \'$testName\' start"
#       $gaSet(runTime) configure -text ""
#       update
#       
#       set ret [$testName 1]
#       
#       if {$ret==0} {
#         set retTxt "PASS."
#       } else {
#         set retTxt "FAIL. Reason: $gaSet(fail)"
#       }
# #       if {$gaSet(pair)=="5"} {
# #         AddToPairLog $::pair "Test \'$testName\' $retTxt"
# #       } else {   
# #         AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"    
# #       }
#       AddToPairLog $pair "Test \'$testName\' $retTxt"
#          
#       puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
#       update
#       if {$ret!=0} {
#         break
#       }
#       if {$gaSet(oneTest)==1} {
#         set ret 1
#         set gaSet(oneTest) 0
#         break
#       }
#     }
#   
#     if {$ret==0} {
#       PairPerfLab $pair #ddffdd ; #$gaSet(halfPassClr) ; # #ccffcc ; #green  ; #ddffdd
#       lappend glPassPair $pair      
#       set retTxt Pass
#       #set logText "All tests pass"
#     } else {
#       set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
#       PairPerfLab $pair red
#       set retTxt Fail
#     }
#     
#     if {($ret!=0) && ($pair==[lindex [PairsToTest] end])} {
#       ## the test failed and the pair is last (or single) and  - do nothing
#     } else {
#       if {$gaSet(nextPair)=="begin"} {
#         # the next pair will start from first test
#         set gaSet(startFrom) [lindex $gaSet(lSerialTests1) 0]
#         set startIndx [lsearch $gaSet(lSerialTests1) $gaSet(startFrom)]
#         set lRunTests [lrange $gaSet(lSerialTests1) $startIndx end]
#         puts "gaSet(lSerialTests1):$gaSet(lSerialTests1)   lRunTests:$lRunTests"
#         update
#       } elseif {$gaSet(nextPair)=="same"} {
#         ## do nothing
#       }
#         
#     }
# #     if {$gaSet(pair)=="5"} {
# #       set pa $pair
# #     } else {
# #       set pa $gaSet(pair)
# #     }
#     puts "********* DUT $pair finish lSerialTests1 *********..[MyTime]..\n\n" 
#     AddToPairLog $pair " ********* DUT $pair $retTxt   *********\n" 
# #     AddToPairLog $pair "$logText \n    ********* DUT $pair $retTxt   *********\n"
# #     if {$ret!=0} {
# #       file rename $gaSet(log.$pair) [file rootname $gaSet(log.$pair)]-Fail.txt
# #     }
#      
#     if {$gaSet(nextPair)=="begin"} {
#       set gaSet(oneTest) 0
#     } elseif {$gaSet(nextPair)=="same"} {
#       ## do nothing
#     }      
#   }
  ######################
  
  puts "\n[MyTime] gaSet(lWidthTests2):$gaSet(lWidthTests2) lRunTests:<$lRunTests>\n"
  foreach WidthTests2 $gaSet(lWidthTests2) {
    if {$gaSet(act)==0} {return -2}
    puts "gaSet(lWidthTests2) PairsToTest:[PairsToTest]"
    if {[llength [PairsToTest]]==0} {break}
    set WidthTests2indx [lsearch -glob $lRunTests *$WidthTests2]
    if {$WidthTests2indx=="-1"} {
      puts "Start after $WidthTests2"
      continue
    }  
    set numberedTest [lindex $lRunTests $WidthTests2indx]
    set testName [lindex [split $numberedTest ..] end]
    puts "\n[MyTime] WidthTests2 WidthTests2:$WidthTests2 WidthTests2indx:$WidthTests2indx numberedTest:$numberedTest"
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
    #$gaSet(startTime) configure -text "$startTime ."
    
    foreach pair [PairsToTest] {
      if {$gaSet(act)==0} {return -2}
      
      set ::pair $pair
      AddToPairLog $::pair "Test \'$testName\' start"
      puts "\n **** DUT ${pair}. Test $numberedTest start; [MyTime] "
      $gaSet(runTime) configure -text ""
      update
      PairPerfLab $pair yellow
      MassConnect $pair
      
      set ret [$testName 1]
      if {$ret==0} {
        set retTxt "PASS."
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"
      }
      AddToPairLog $::pair "Test \'$testName\' $retTxt"
         
      puts "\n **** DUT $pair. Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
      if {$ret==0} {
        PairPerfLab $pair #ddffdd ; #$gaSet(halfPassClr) ; # #ccffcc ; #green  ; #ddffdd
        lappend glPassPair $pair      
        set retTxt Pass
      } else {
        set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
        PairPerfLab $pair red
        set retTxt Fail
        lappend glFailPair $pair
        set gaSet(runStatus) Fail
        SQliteAddLine $pair
      }            
    } 
#     if {$gaSet(oneTest)==1} {
#       set ret 1
#       set gaSet(oneTest) 0
#       break
#     } 
  } 
  
  puts "\n[MyTime] gaSet(lTogetherTests2):$gaSet(lTogetherTests2) \nlRunTests:<$lRunTests>\n"
  foreach TogetherTests2 $gaSet(lTogetherTests2) {
    if {$gaSet(act)==0} {return -2}
    puts "gaSet(lTogetherTests2) PairsToTest:[PairsToTest]"
    if {[llength [PairsToTest]]==0} {break}
    set TogetherTests2indx [lsearch -glob $lRunTests *$TogetherTests2]
    if {$TogetherTests2indx=="-1"} {
      puts "Start after $TogetherTests2"
      continue
    }  
    set numberedTest [lindex $lRunTests $TogetherTests2indx]
    set testName [lindex [split $numberedTest ..] end]
    puts "\n[MyTime] lTogetherTests2 TogetherTests2:$TogetherTests2 TogetherTests2indx:$TogetherTests2indx numberedTest:$numberedTest"
    set gaSet(curTest) $numberedTest
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
    #$gaSet(startTime) configure -text "$startTime ."
    
    foreach pair [PairsToTest] {
      AddToPairLog $pair "Test \'$testName\' start"
    }     
    $gaSet(runTime) configure -text ""
    update
    set ret [$testName 1]
    puts "********* TogetherTests1 $TogetherTests1 finish ret:<$ret> *********..[MyTime]..\n\n"
  }  
    
  
#   set gaSet(oneTest) 0
    
  #set lPassPair [lsort -unique -dict $lPassPair]
  puts "glPassPair:<$glPassPair>, llength $glPassPair:[llength $glPassPair]"
  
  if {$gaSet(act)==0} {return -2}
  
  puts "\n[MyTime] gaSet(lWidthTests3):$gaSet(lWidthTests3) \nlRunTests:<$lRunTests>\n"
  foreach WidthTests3 $gaSet(lWidthTests3) {
    if {$gaSet(act)==0} {return -2}
    puts "gaSet(lWidthTests3) PairsToTest:[PairsToTest]"
    if {[llength [PairsToTest]]==0} {break}
    set WidthTests3indx [lsearch -glob $lRunTests *$WidthTests3]
    if {$WidthTests3indx=="-1"} {
      puts "Start after $WidthTests3"
      continue
    }  
    set numberedTest [lindex $lRunTests $WidthTests3indx]
    set testName [lindex [split $numberedTest ..] end]
    puts "\n[MyTime] WidthTests3 WidthTests3:$WidthTests3 WidthTests3indx:$WidthTests3indx numberedTest:$numberedTest"
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
    #$gaSet(startTime) configure -text "$startTime ."
    
    foreach pair [PairsToTest] {
      if {$gaSet(act)==0} {return -2}
      
      set ::pair $pair
      AddToPairLog $::pair "Test \'$testName\' start"
      puts "\n **** DUT ${pair}. Test $numberedTest start; [MyTime] "
      $gaSet(runTime) configure -text ""
      update
      PairPerfLab $pair yellow
      MassConnect $pair
      
      set ret [$testName 1]
      if {$ret==0} {
        set retTxt "PASS."
      } else {
        set retTxt "FAIL. Reason: $gaSet(fail)"
      }
      AddToPairLog $::pair "Test \'$testName\' $retTxt"
         
      puts "\n **** DUT $pair. Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
      if {$ret==0} {
        PairPerfLab $pair #ddffdd ; #$gaSet(halfPassClr) ; # #ccffcc ; #green  ; #ddffdd
        lappend glPassPair $pair      
        set retTxt Pass
      } else {
        set logText "Test $numberedTest fail. Reason: $gaSet(fail)" 
        PairPerfLab $pair red
        set retTxt Fail
        lappend glFailPair $pair
        set gaSet(runStatus) Fail
        SQliteAddLine $pair
      }            
    } 
#     if {$gaSet(oneTest)==1} {
#       set ret 1
#       set gaSet(oneTest) 0
#       break
#     } 
  } 
  
  
#   if {$gaSet(pair)=="5"} {}
    for {set pair 1} {$pair <= $gaSet(maxMultiQty)} {incr pair} {
      set bg [$gaGui(labPairPerf$pair) cget -bg]
      if {$bg=="green" || $bg=="#ddffdd"} {
        set endFlag Pass
        PairPerfLab $pair green
         AddToPairLog $pair ""
        if {[llength $lRunTests]==[llength $glTests]} {
          AddToPairLog $pair "All Tests PASS"
        } else {
          AddToPairLog $pair "Tests PASS"
        }
      } elseif {$bg=="red"} {
        set endFlag Fail
      } else {
        continue
      }
      set pa $pair
      if {[string index [file rootname $gaSet(log.$pa)] end]=="s" ||\
          [string index [file rootname $gaSet(log.$pa)] end]=="l"} {
        ## in case of -Pass or -Fail
        set newLog [string range [file rootname $gaSet(log.$pa)] 0 end-5]
        file rename -force $gaSet(log.$pa) $newLog.txt    
      }
      set nName [file rootname $gaSet(log.$pa)]-$endFlag.txt
      file rename -force $gaSet(log.$pa) $nName; #[file rootname $gaSet(log.$pa)]-$endFlag.txt
      set gaSet(log.$pa) $nName
      set gaSet(runStatus) $endFlag
      if {$endFlag=="Pass"} {
        SQliteAddLine $pa
      }
    }  
#   {} else {}
#     set pa $gaSet(pair)
#     if {[string index [file rootname $gaSet(log.$pa)] end]=="s" ||\
#         [string index [file rootname $gaSet(log.$pa)] end]=="l"} {
#       ## in case of -Pass or -Fail
#       set newLog [string range [file rootname $gaSet(log.$pa)] 0 end-5]
#       file rename -force $gaSet(log.$pa) $newLog.txt    
#     }
#     file rename -force $gaSet(log.$pa) [file rootname $gaSet(log.$pa)]-$endFlag.txt
#     set gaSet(runStatus) $endFlag
#     SQliteAddLine $pa
#   {}
  
  
  
  #AddToLog "********* TEST FINISHED  *********" 

  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# USBport
# ***************************************************************************
proc USBport {run} {
  global gaSet
  set ret 0
   ### 13/07/2016 15:06:43 6.0.1 reads the USB port without a special app
  
  set ret [CheckUsbPort]
  if {$ret!=0} {return $ret}
  
#   set ret [EntryBootMenu]
#   if {$ret!=0} {return $ret}
#   
#   set ret [DeleteUsbPortApp]
#   if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# PS_ID
# ***************************************************************************
proc ID {run} {
  global gaSet
  MassConnect $::pair $::pair
  Power all on
  set ret [PS_IDTest]
  return $ret
}

# ***************************************************************************
# SFPPlic
# ***************************************************************************
proc SFPPlic {run} {
  global gaSet
  Power all on
  set ret [SFPPlicTest]
  return $ret
}

# ***************************************************************************
# DyingGasp_conf
# ***************************************************************************
proc DyingGasp_conf {run} {
  global gaSet  buffer gRelayState
  Power all on
  Status "DyingGasp_conf"
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
  
  Power all off
  after 1000
  Power all on
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  ##set ret [DyingGaspSetup]
  return $ret
}
# ***************************************************************************
# DyingGasp_run
# ***************************************************************************
proc DyingGasp_run {run} {
  global gaSet
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  MuxMngIO ioToPc ioToGen
  
  if {$up=="4SFP_0"} {
    ## uut with 4 sfp only connected to the ATE net by port 0/6
    set mngPort 0/6
  } else {
    ## all the rest products are connected to the ATE net by port 0/9
    set mngPort 0/9
  }
  set ret [SpeedEthPort $mngPort 100]
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait Port $mngPort up" 140 white]
  if {$ret!=0} {return $ret}
  
  set ret [DyingGaspPerf 1 2]
  if {$ret!=0} {
    set ret [SpeedEthPort $mngPort 100]
    if {$ret!=0} {return $ret}
    
#     set ret [Wait "Wait Port $mngPort up" 140 white]
#     if {$ret!=0} {return $ret}
    
    set ret [DyingGaspPerf 1 2]
    if {$ret!=0} {return $ret}
  }
  
  Power all on
  set ret [Wait "Wait for ETX up" 20 white]
  if {$ret!=0} {return $ret}
  
  set ret [FactDefault std noWD noDelBootFiles]
  if {$ret!=0} {return $ret}
  
  MuxMngIO ioToGenMngToPc ioToGen
  
  return $ret
}



# ***************************************************************************
# DateTime
# ***************************************************************************
proc DateTime {run} {
  global gaSet
  Power all on
  set ret [DateTime_Test]
  return $ret
} 

# ***************************************************************************
# DataTransmission_conf
# ***************************************************************************
proc DataTransmission_conf {run} {
  global gaSet
  Power all on    
  set ret [DataTransmissionSetup]
  return $ret
} 

# ***************************************************************************
# SFP_ID
# ***************************************************************************
proc SFP_ID {run} {
  global gaSet glSFPs 
  MassConnect $::pair $::pair
  
  set glSFPs [list]
  set id [open sfpList.txt r]
    while {[gets $id line]>=0} {
      lappend glSFPs $line
    }
  close $id
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
 
 set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
      
  if {$b=="19"} {
    if {$up=="12SFP_12UTP"} {
      set portsL [list 0/1 0/2 0/3 0/4 \
          0/17 0/18 0/19 0/20 0/21 0/22 0/23 0/24 0/25 0/26 0/27 0/28]
    } elseif {$up=="12SFP_12SFP" || $up=="24SFP_0"} {
      set portsL [list 0/1 0/2 0/3 0/4 \
          0/5  0/6  0/7  0/8  0/9  0/10 0/11 0/12 0/13 0/14 0/15 0/16 \
          0/17 0/18 0/19 0/20 0/21 0/22 0/23 0/24 0/25 0/26 0/27 0/28]
    } 
  } elseif {$b=="Half19" || $b=="Half19B" || $b=="19B"} {
    if {$np=="2SFPP"} {
      ## in option of 2sfpp - all 4 ports are existsing and we check them 
      set portsL [list 0/1 0/2 0/3 0/4]
    } elseif {$np=="4SFPP"} {
      set portsL [list 0/1 0/2 0/3 0/4]
    } elseif {$np=="8SFPP" && $up=="0_0"} {
      set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8]
    }
    if {$up=="4SFP_0"} {
      lappend portsL 0/5 0/6 0/7 0/8   
    } elseif {$up=="4SFP_4UTP"} {
      lappend portsL 0/5 0/6 0/7 0/8   
    } elseif {$up=="8SFP_0"} {
      lappend portsL 0/5 0/6 0/7 0/8 0/9 0/10 0/11 0/12   
    }
  }
  
  foreach port $portsL {
    set ret [ReadEthPortStatus $port]
    if {$ret!="0"} {return $ret}
  }
  return $ret
} 
# ***************************************************************************
# Combo_SFP_ID
# ***************************************************************************
proc Combo_SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open sfpList.txt r]
    while {[gets $id line]>=0} {
      lappend glSFPs $line
    }
  close $id
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
 
 set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
      
  set portsL [list 0/5 0/6 0/7 0/8 0/9 0/10 0/11 0/12 0/13 0/14 0/15 0/16]
  
  foreach port $portsL {
    set ret [ReadEthPortStatus $port]
    if {$ret!="0"} {return $ret}
  }
  return $ret
} 
# ***************************************************************************
# UTP_ID
# ***************************************************************************
proc UTP_ID {run} {
  global gaSet 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  
        
  if {$b=="19"} {
    if {$up=="12SFP_12UTP"} {
      set portsL [list 0/5 0/6 0/7 0/8 0/9 0/10 0/11 0/12 0/13 0/14 0/15 0/16]
    } elseif {$up=="12SFP_12SFP" || $up=="24SFP_0"} {
      set portsL [list]
    } 
  } elseif {$b=="Half19" || $b=="Half19B" || $b=="19B"} {
    set portsL [list]
    if {$up=="4SFP_0"} {
      # no rj  
    } elseif {$up=="4SFP_4UTP"} {
      lappend portsL 0/9 0/10 0/11 0/12   
    } elseif {$up=="8SFP_0"} {
      # no rj   
    }
  }
  
  if [llength $portsL] {
    set ret [Login]
    if {$ret!=0} {
      #set ret [Login]
      if {$ret!=0} {return $ret}
    }
  
    set ret [Wait "Wait for UDP ports UP" 15]
    if {$ret!=0} {return $ret}
  
    foreach port $portsL {
      set ret [ReadUtpPortStatus $port]
      if {$ret!="0"} {return $ret}
    }
  } else {
    set ret 0
  }
  return $ret
} 
# ***************************************************************************
# Combo_UTP_ID
# ***************************************************************************
proc Combo_UTP_ID {run} {
  global gaSet 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  RLSound::Play information
  set txt "Disconnect all cables and optic fibers (except POWER and CONTROL) and verify GREEN leds are OFF"
  set res [DialogBox -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
  update
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    return -1
  } else {
    set ret 0
  }
 
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set portsL [list 0/5 0/6 0/7 0/8 0/9 0/10 0/11 0/12 0/13 0/14 0/15 0/16]
  
  
  if [llength $portsL] {
    foreach port $portsL {
      set ret [ReadUtpPortStatus $port]
      if {$ret!="0"} {return $ret}
    }
  }
  return $ret
}  
# ***************************************************************************
# DataTransmission_run
# ***************************************************************************
proc DataTransmission_run {run} {
  global gaSet gRelayState
  MassConnect $::pair  $::pair
  Status "Init GENERATOR"
  set ret [RL10GbGen::Init $gaSet(id220)]  
  if {$ret!=0} {
    set gaSet(fail) "Init GENERATOR fail"
    return $ret
  } 
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  switch -exact -- $b {
    19 {
      set 10GlineRate 50%
      set 1GlineRate  50%
    }
    Half19 - Half19B - 19B {
      set 10GlineRate 90%
      set 1GlineRate  100%
    }
  }
  if {$np=="8SFPP" && $up=="0_0"} {
    set 10GlineRate 50%
 }
  Status "Config GENERATOR"
  
  Etx220Config 1 $10GlineRate
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1 G Ports
  } else {
    Etx220Config 5 $1GlineRate
  }
  set ret [DataTransmissionTestPerf 10]  
  if {$ret!=0} {return $ret} 
  
  Etx220Config 1 $10GlineRate
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1 G Ports
  } else {
    Etx220Config 5 $1GlineRate
  }
  set ret [DataTransmissionTestPerf 120]  
  if {$ret!=0} {
#     Etx220Config 1 $10GlineRate
#     Etx220Config 5 $1GlineRate
#     set ret [DataTransmissionTestPerf 10]  
#     if {$ret!=0} {return $ret}
#     
#     Etx220Config 1 $10GlineRate
#     Etx220Config 5 $1GlineRate
#     set ret [DataTransmissionTestPerf 120]  
#     if {$ret!=0} {return $ret}
  } 
  return $ret
}
# ***************************************************************************
# DataTransmissionTestPerf
# ***************************************************************************
proc DataTransmissionTestPerf {checkTime} {
  global gaSet
  Power all on 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set ret [Wait "Waiting for stabilization" 10 white]
  if {$ret!=0} {return $ret}
  
  Etx220Start 1
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1 G Ports
  } else {
    Etx220Start 5
  }  
  set ret [Wait "Data is running" $checkTime white]
  if {$ret!=0} {return $ret}
  Etx220Stop 1
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1 G Ports
  } else {
    Etx220Stop 5
  }  
  set ret [Etx220Check 1]
  if {$ret!=0} {return $ret}
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no 1 G Ports
  } else {
    set ret [Etx220Check 5]
    if {$ret!=0} {return $ret}
  }
 
  return $ret
}  
# ***************************************************************************
# ExtClkUnlocked 
# ***************************************************************************
# proc ExtClkUnlocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Unlocked]
#   return $ret
# }
# ***************************************************************************
# ExtClkLocked
# ***************************************************************************
# proc ExtClkLocked {run} {
#   global gaSet
#   Power all on
#   set ret [ExtClkTest Locked]
#   return $ret
#}
# ***************************************************************************
# ExtClk
# ***************************************************************************
proc ExtClk {run} {
  global gaSet
  if {$gaSet(pair)!="SE"} {
    set gaSet(fail) "It is no possible to perform ExtClk test on this Tester"
    return -1
  }
  Power all on
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  return $ret
}
# ***************************************************************************
# Leds_FAN_conf
# ***************************************************************************
proc Leds_FAN_conf {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
   set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  set cf C:/AT-ETX-2i-10G/ConfFiles/mng_5.9.1.txt
  set cfTxt "MNG port"
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set cf $gaSet([set b]CF) 
  set cfTxt "$b"    
  set ret [DownloadConfFile $cf $cfTxt 0 $com]
  if {$ret!=0} {return $ret}
  
  set ret [RL10GbGen::Init $gaSet(id220)]  
  if {$ret!=0} {
    set gaSet(fail) "Init GENERATOR fail"
    return $ret
  } 
  
  switch -exact -- $b {
    19 {
      set 10GlineRate 50%
      set 1GlineRate  50%
    }
    Half19 - Half19B - 19B {
      set 10GlineRate 90%
      set 1GlineRate  100%
    }
  }
  Status "Config GENERATOR"
  
  Etx220Config 1 $10GlineRate
  Etx220Config 5 $1GlineRate
  
  Etx220Start 1
  Etx220Start 5
  
  return $ret
}
# ***************************************************************************
# Leds
# ***************************************************************************
proc Leds_FAN {run} {
  global gaSet gaGui gRelayState gaDBox
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  
  set gRelayState red
  #IPRelay-LoopRed
  #SendEmail "ETX-2I" "Manual Test"
  
  foreach pair [PairsToTest] {
    PairPerfLab $pair yellow
    MassConnect $pair
    if {$gaSet(pair)==5} {
      set dutIp 10.10.10.1[set pair]
    } else {
      if {$gaSet(pair)=="SE"} {
        set dutIp 10.10.10.111
      } else {
        set dutIp 10.10.10.1[set gaSet(pair)]
      } 
    }
    catch {set pingId [exec ping.exe $dutIp] -t &]}
  }
  
  ## 21/06/2020 07:29:24
  if {[llength [PairsToTest]]} {
    if {[string match *.24SFP.PTP* $gaSet(DutInitName)]==1 && $gaSet(pair)!="5"} {
      ## in Multi (pair==5) Ext & SyncE tests are not preformed
      RLSound::Play information
      set txt "On UUT/s [join [PairsToTest] {, }]:\n\n Disconnect the 3 fiber optics and \n\
      connect the 3 regular cables of the tester to ports 9, 11, 17"
      set res [DialogBox -type "Continue Stop" -icon /images/info -title "Sync_E in 24SFP/PTP"\
        -message $txt]
      puts "[MyTime] res:<$res>"; update  
      if {$res=="Stop"} {
        set gaSet(fail) "User stop"
        set retTxt "FAIL. Reason: User stop"
  #       if {$gaSet(pair)=="5"} {
  #         foreach pair [PairsToTest] {
  #           AddToPairLog $pair "Test \'Leds_FAN\' $retTxt"
  #           PairPerfLab $pair red
  #         }
  #       } else {   
  #         AddToPairLog $gaSet(pair) "Test \'Leds_FAN\' $retTxt"
  #       }
        foreach pair [PairsToTest] {
          AddToPairLog $pair "Test \'Leds_FAN\' $retTxt"
          PairPerfLab $pair red 
          set gaSet(runStatus) Fail 
          SQliteAddLine $pair
        }
        return -2
      }
      set ret 0
    } 
  }
  
  foreach pair [PairsToTest] {
    PairPerfLab $pair yellow
    MassConnect $pair  $pair
    if {$gaSet(pair)=="5"} {
      set ttt "On UUT $pair: \n\n"
    } else {
      set ttt ""
    }
    set txt ""; append txt $ttt "1. Check 0.95V\n"
    RLSound::Play information
    if {$p=="P"} {
      set tstLedState ON
    } elseif {$p=="0"} {
      set tstLedState OFF ; # 21/11/2018 09:45:38
    }
    set txt1 "2. Verify that:\n\
    GREEN \'PWR\' led is ON\n\
    GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON and Blinking respectively\n"
  
    set txt2_19 "On each PS GREEN \'PWR\' led is ON\n"
    set txt2_9 "" ; #"On PS GREEN \'PWR\' led is ON\n"
  
    set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
    GREEN \'LINK/ACT\' leds of 1GbE ports are Blinking  (if exists)\n\
    EXT CLK's GREEN \'SD\' led is ON (if exists)\n\
    FAN rotates"
  
    append txt $txt1
    if {$b=="19" || $b=="19B"} {
      append txt ${txt2_19}
    } elseif {$b=="Half19" || $b=="Half19B"} {
      append txt ${txt2_9}
    } 
    append txt $txt3
  
    set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
    puts "[MyTime] res:<$res>"; update  
    catch {exec pskill.exe -t $pingId}
    if {$res!="OK"} {
      PairPerfLab $pair red
      AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
      set gaSet(fail) "LED Test failed"
      set gaSet(runStatus) Fail
      SQliteAddLine $pair
      set ret -1
    } else {
      set ret 0
      PairPerfLab $pair #ddffdd
    }
  }  
  
  if {($b=="19" || $b=="19B") && [llength [PairsToTest]]} {
    foreach ps {2 1} {
      if {[llength [PairsToTest]]==0} {break}
      Power $ps off
      set ret [Wait "Wait for PS-$ps is OFF" 4 white]
      if {$ret!=0} {return $ret}
      
      foreach pair [PairsToTest] {
        PairPerfLab $pair yellow
        MassConnect $pair
        set val [ShowPS $ps]
        puts "pair-$pair val:<$val>"
        if {$val=="-1"} {
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: $gaSet(fail)"
          set gaSet(runStatus) Fail
          set ret -1
          SQliteAddLine $pair
        }
        if {$val!="Failed"} {
          set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Failed\""
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: $gaSet(fail)"
          set gaSet(runStatus) Fail
          set ret -1
          SQliteAddLine $pair
        }
      }  
      
      if {[llength [PairsToTest]]} {
        RLSound::Play information
        if {$gaSet(pair)=="5"} {
          set ttt "On UUT/s [join [PairsToTest] {, }]: \n\n"
        } else {
          set ttt ""
        }
        set txt ""; append txt $ttt "Verify on PS-$ps that RED led is ON"
        if {$gaSet(pair)=="5"} {
          set radButInvoke [list]
          set radButQty [expr {2 * [llength [PairsToTest]]}]
          for {set inv 1} {$inv<=$radButQty} {incr inv 2} {
            lappend radButInvoke $inv
          }
          set radButLab [list]
          set radButVar [list]
          set radButVal [list]
          foreach pair [PairsToTest] {  
            lappend radButLab "UUT-$pair OK" "UUT-$pair Fail"
            lappend radButVar "$pair" "$pair"
            lappend radButVal OK Fail
          }
          set res [DialogBox -type "Continue Stop" -icon /images/question -title "LED_FAN Test" -message $txt \
            -RadButQty $radButQty -RadButPerRow 2 -RadButLab $radButLab \
            -RadButVar $radButVar -RadButVal $radButVal -RadButInvoke $radButInvoke]
        } else {    
          set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
        }
        puts "[MyTime] res:<$res>"; update  
        if {$gaSet(pair)=="5"} {
          if {$res!="Continue"} {
            foreach pair [PairsToTest] {
              set gaDBox($pair) "Fail"  
            }
          }
          foreach pair [PairsToTest] {
            if {$gaDBox($pair)=="OK"} {
              PairPerfLab $pair #ddffdd
            } else {
              set gaSet(fail) "LED Test failed"
              PairPerfLab $pair red
              AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
              set gaSet(runStatus) Fail
              set ret -1
              SQliteAddLine $pair
            }
          }
        } else {
          if {$res!="OK"} {
            set gaSet(fail) "LED Test failed"
            set gaSet(runStatus) Fail
            SQliteAddLine 1
            return -1
          } else {
            set ret 0
          }
        }
      }
      
      if {($b=="19" || ($b=="19B" && $np=="8SFPP" && $up=="0_0")) && [llength [PairsToTest]]} {
        RLSound::Play information
        if {$gaSet(pair)=="5"} {
          set ttt "On UUT/s [join [PairsToTest] {, }]: \n\n"
        } else {
          set ttt ""
        }
        set txt ""; append txt $ttt "Remove PS-$ps and verify that led is OFF"
        if {$gaSet(pair)=="5"} {
          set radButInvoke [list]
          set radButQty [expr {2 * [llength [PairsToTest]]}]
          for {set inv 1} {$inv<=$radButQty} {incr inv 2} {
            lappend radButInvoke $inv
          }
          set radButLab [list]
          set radButVar [list]
          set radButVal [list]
          foreach pair [PairsToTest] {  
            lappend radButLab "UUT-$pair OK" "UUT-$pair Fail"
            lappend radButVar "$pair" "$pair"
            lappend radButVal OK Fail
          }
          set res [DialogBox -type "Continue Stop" -icon /images/question -title "LED_FAN Test" -message $txt \
            -RadButQty $radButQty -RadButPerRow 2 -RadButLab $radButLab \
            -RadButVar $radButVar -RadButVal $radButVal -RadButInvoke $radButInvoke]
        } else {    
          set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
        }
        puts "[MyTime] res:<$res>"; update  
        if {$gaSet(pair)=="5"} { 
          if {$res!="Continue"} {
            foreach pair [PairsToTest] {
              set gaDBox($pair) "Fail"  
            }
          }
          foreach pair [PairsToTest] {
            if {$gaDBox($pair)=="OK"} {
              PairPerfLab $pair #ddffdd
            } else {
              set gaSet(fail) "LED Test failed"
              PairPerfLab $pair red
              AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
              set gaSet(runStatus) Fail
              set ret -1
              SQliteAddLine $pair
            }
          }
        } else {
          if {$res!="OK"} {
            set gaSet(fail) "LED Test failed"
            set gaSet(runStatus) Fail
            SQliteAddLine 1
            return -1
          } else {
            set ret 0
          }
        }
               
        foreach pair [PairsToTest] {
          PairPerfLab $pair yellow
          MassConnect $pair
          set val [ShowPS $ps]
          puts "pair-$pair val:<$val>"
          if {$val=="-1"} {
            PairPerfLab $pair red
            AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: $gaSet(fail)"
            set gaSet(runStatus) Fail
            set ret -1
            SQliteAddLine $pair
          }
          if {$val!="Not exist"} {
            set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
            PairPerfLab $pair red
            AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: $gaSet(fail)"
            set gaSet(runStatus) Fail
            set ret -1
            SQliteAddLine $pair
          }
        } 
                
        if {[llength [PairsToTest]]} {
          RLSound::Play information 
          set txt ""; append txt $ttt "Assemble PS-$ps"
          set res [DialogBox -type "Continue Stop" -icon /images/info -title "LED Test" -message $txt]
          puts "[MyTime] res:<$res>"; update  
          if {$res!="Continue"} {
            set gaSet(fail) "LED Test failed"
            foreach pair [PairsToTest] {
              AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
              PairPerfLab $pair red
              set gaSet(runStatus) Fail
              set ret -1
              SQliteAddLine $pair
            }
          } else {
            set ret 0
          }
        }
      }  
      Power $ps on
      after 2000      
    }
  }
  
  
  
  return $ret
}
# ***************************************************************************
# Leds_AllCablesOFF
# ***************************************************************************
proc Leds_AllCablesOFF {run} {
  global gaSet gaGui gRelayState  gaDBox
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  RLSound::Play information  
  if {$p=="P" && $gaSet(pair)!="5"} {
    ## in Multi (pair==5) Ext & SyncE tests are not preformed
    ## in the following lines if {$gaSet(pair)=="5"} {}  never will be TRUE,
    ## but I do not delete them for a case
    RLSound::Play information
    if {$gaSet(pair)=="5"} {
      set ttt "On UUT/s [join [PairsToTest] {, }]: \n\n"
    } else {
      set ttt ""
    }
    set txt ""; append txt $ttt "Remove the EXT CLK cable and verify the SD led is OFF"
    if {$gaSet(pair)=="5"} {
      set radButInvoke [list]
      set radButQty [expr {2 * [llength [PairsToTest]]}]
      for {set inv 1} {$inv<=$radButQty} {incr inv 2} {
        lappend radButInvoke $inv
      }
      set radButLab [list]
      set radButVar [list]
      set radButVal [list]
      foreach pair [PairsToTest] {  
        lappend radButLab "UUT-$pair OK" "UUT-$pair Fail"
        lappend radButVar "$pair" "$pair"
        lappend radButVal OK Fail
      }
      set res [DialogBox -type "Continue Stop" -icon /images/question -title "LED_FAN Test" -message $txt \
        -RadButQty $radButQty -RadButPerRow 2 -RadButLab $radButLab \
        -RadButVar $radButVar -RadButVal $radButVal -RadButInvoke $radButInvoke]
    } else {    
      set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
    }
    puts "[MyTime] res:<$res>"; update  
    if {$gaSet(pair)=="5"} {
      set ret 0
      foreach pair [PairsToTest] {
        if {$res!="Continue"} {
          foreach pair [PairsToTest] {
            set gaDBox($pair) "Fail"  
          }
        }
        if {$gaDBox($pair)=="OK"} {
          PairPerfLab $pair #ddffdd          
        } else {
          set gaSet(fail) "LED Test failed"
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
          set gaSet(runStatus) Fail
          SQliteAddLine $pair      
          set ret -1    
        }
      }
    } else {
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        SQliteAddLine 1
        return -1
      } else {
        set ret 0
      }
    }
      
  }
 

  if {[string match *.12CMB.* $gaSet(DutInitName)]==0} {
    ## if an UUT is not CMB we should pull out all the cables
    ## if the product is CMB, we will pull out them later in UTP_ID
    RLSound::Play information
    if {$gaSet(pair)=="5"} {
      set ttt "On UUT/s [join [PairsToTest] {, }]: \n\n"
    } else {
      set ttt ""
    }
    set txt ""; append txt $ttt "Disconnect all cables and optic fibers (except POWER and CONTROL) \nand verify GREEN leds are OFF"
    if {$gaSet(pair)=="5"} {
      set radButInvoke [list]
      set radButQty [expr {2 * [llength [PairsToTest]]}]
      for {set inv 1} {$inv<=$radButQty} {incr inv 2} {
        lappend radButInvoke $inv
      }
      set radButLab [list]
      set radButVar [list]
      set radButVal [list]
      foreach pair [PairsToTest] {  
        lappend radButLab "UUT-$pair OK" "UUT-$pair Fail"
        lappend radButVar "$pair" "$pair"
        lappend radButVal OK Fail
      }
      set res [DialogBox -type "Continue Stop" -icon /images/question -title "LED_FAN Test" -message $txt \
        -RadButQty $radButQty -RadButPerRow 2 -RadButLab $radButLab \
        -RadButVar $radButVar -RadButVal $radButVal -RadButInvoke $radButInvoke]
    } else {    
      set res [DialogBox -type "OK Fail" -icon /images/question -title "LED_FAN Test" -message $txt]
    }
    puts "[MyTime] res:<$res>"; update  
    if {$gaSet(pair)=="5"} {
      set ret 0
      if {$res!="Continue"} {
        foreach pair [PairsToTest] {
          set gaDBox($pair) "Fail"  
        }
      }
      foreach pair [PairsToTest] {
        if {$gaDBox($pair)=="OK"} {
          PairPerfLab $pair #ddffdd
        } else {
          set gaSet(fail) "LED Test failed"
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Leds_FAN\' FAIL. Reason: \"LED Test failed\" "
          set gaSet(runStatus) Fail
          SQliteAddLine $pair
          set ret -1
        }
      }
    } else {
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        SQliteAddLine 1
        return -1
      } else {
        set ret 0
      }
    }    
  }  
  return $ret
}


# ***************************************************************************
# SetToDefault
# ***************************************************************************
proc SetToDefault {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda noWD noDelBootFiles]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefault_beforeLeds
# ***************************************************************************
proc SetToDefault_beforeLeds {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda noWD yes]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultWD
# ***************************************************************************
proc SetToDefaultWD {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda wd noDelBootFiles]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# OpenLicense
# ***************************************************************************
proc OpenLicense {run} {
  global gaSet gaGui
  MassConnect $::pair $::pair
  Power all on
  set ret [LicenseRead2CloseAll]
  puts "[MyTime] ret of LicenseRead2CloseAll: <$ret>"
  if {$ret!=0} {return $ret}
  set ret [LicensePerf Open]
  puts "[MyTime] ret of LicensePerf Open: <$ret>"
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefault_CloseLicense
# ***************************************************************************
proc SetToDefault_CloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault stda Close noDelBootFiles]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# CloseLicense
# ***************************************************************************
proc CloseLicense {run} {
  global gaSet gaGui
  Power all on
  set ret [LicensePerf Close]
  puts "[MyTime] ret of LicensePerf Close: <$ret>"
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  if {[llength [PairsToTest]]==0} {return -1}
  foreach pair [PairsToTest]  {
    set ::pair $pair
    PairPerfLab $pair yellow
    MassConnect $pair
    puts "Mac_BarCode \"$pair\" "
    mparray gaSet *$pair*mac* ; update
    mparray gaSet *$pair*barcode* ; update
    set badL [list]
    set ret -1
    foreach unit {1} {
      if ![info exists gaSet($pair.mac$unit)] {
        set ret [ReadMac]
        if {$ret!=0} {
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Mac_BarCode\' FAIL. Reason: $gaSet(fail)"
          set gaSet(runStatus) Fail
          SQliteAddLine $pair
          set ret -1
        } else {
          set ret 0
          PairPerfLab $pair #ddffdd
        }       
      }  
    }  
  
    foreach unit {1} {
      if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
        set ret [ReadBarcode [PairsToTest] ]
        if {$ret!=0} {
          PairPerfLab $pair red
          AddToPairLog $pair "Test \'Mac_BarCode\' FAIL. Reason: $gaSet(fail)"
          set gaSet(runStatus) Fail
          SQliteAddLine $pair
          set ret -1
        } else {
          set ret 0
          PairPerfLab $pair #ddffdd
        }
      }
    }    
  }
  
  if {[llength [PairsToTest]]==0} {return -1}  
  foreach pair [PairsToTest] {
    PairPerfLab $pair yellow
    MassConnect $pair
    set ret [RegBC $pair]
    if {$ret!=0} {
      PairPerfLab $pair red
      AddToPairLog $pair "Test \'Mac_BarCode\' FAIL. Reason: $gaSet(fail)"
      set gaSet(runStatus) Fail
      SQliteAddLine $pair
      set ret -1
    } else {
      set ret 0
      PairPerfLab $pair #ddffdd
      AddToPairLog $pair "Test \'Mac_BarCode\' PASS"
    }
  }  
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [FactDefault stda noWD noDelBootFiles]
  if {$ret!=0} {return $ret}
  set ret [LoadDefConf]
  return $ret
}
 

# ***************************************************************************
# MacSwID
# ***************************************************************************
proc MacSwID {run} {
   set ret [MacSwIDTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DDR
# ***************************************************************************
proc DDR {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_single
# ***************************************************************************
proc DDR_single {run} {
  global gaSet
  Power all on
  set ret [DdrTest 1]
  return $ret
}
# ***************************************************************************
# DDR_multi
# ***************************************************************************
proc DDR_multi {run} {
  global gaSet
  Power all on
  for {set i 1} {$i<=$gaSet(ddrMultyQty)} {incr i} {
    set ret [DdrTest $i]
    if {$ret!=0} {break}
    Power all off
    after 2000
    Power all on
  }  
  return $ret
}
# ***************************************************************************
# BootDownload
# ***************************************************************************
proc BootDownload {run} {
  set ret [Boot_Download]
  if {$ret!=0} {return $ret}
  
  set ret [FormatFlashAfterBootDnl]
  if {$ret!=0} {return $ret}
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
# FanEepromBurn
# ***************************************************************************
proc FanEepromBurn {run} {
  set ret [FanEepromBurnTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}  
# ***************************************************************************
# SyncE_conf
# ***************************************************************************
proc SyncE_conf {run} {
  global gaSet  buffer
  if {$gaSet(pair)!="SE"} {
    set gaSet(fail) "It is no possible to perform SyncE test on this Tester"
    return -1
  }
  Power all on 
  
  ## 21/06/2020 07:29:24
  if {[string match *.24SFP.PTP* $gaSet(DutInitName)]==1} {
    set txt "Connect 3 fiber optics between:\n\
    Port 1 of AUX 2 (A) to Port 11 of the UUT\n\
    Port 1 of AUX 1 (B) to Port 17 of the UUT\n\
    Port 3 of AUX 1 (C) to Port 9 of the UUT"
    set res [DialogBox -type "Ok Stop" -icon /images/info -title "Sync_E in 24SFP/PTP"\
      -message $txt]
    if {$res=="Stop"} {
      return -2
    }
    set ret 0
  }   
  
  ##23/02/2020 11:09:26 Check AUXes config
  foreach aux {Aux1 Aux2} {
    set com $gaSet(com$aux)
    catch {RLSerial::Close $com}
    after 100
    set ret [RLSerial::Open $com 9600 n 8 1]
    ##set ret [RLCom::Open $com 9600 8 NONE 1]
    set ret [Login205 $aux]
    if {$ret!=0} {
      set ret [Login205 $aux]
    }
    if {$ret!=0} {
      set gaSet(fail) "Logon to $aux fail"
      return -1
    }
    
    Send $com "exit all\r" stam 0.25
    set ret [Send $com "configure system clock domain 1\r" domain(1)] 
    if {$ret!=0} {
      set gaSet(fail) "Read Domain 1 at $aux fail"
      return -1
    }
    set ret [Send $com "info\r" domain(1)] 
    if {$ret!=0} {
      set gaSet(fail) "Read Info of Domain 1 at $aux fail"
      return -1
    }
    if {[string match *force-t4-as-t0* $buffer]} {
      ## the aux is configured
      set ret 0
      Status "$aux is configured"
      catch {RLSerial::Close $com}
      break
    } else {
      Send $com "exit all\r" stam 0.25 
      set cf $gaSet([set aux]CF) 
      set cfTxt "$aux"
      set ret [DownloadConfFile $cf $cfTxt 1 $com] 
      if {$ret==0} {
        Status "$aux passed configuration"
      } else {
        set gaSet(fail) "Configuration of $aux failed" 
        return $ret 
      }
      catch {RLSerial::Close $com}
    }
  }
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  set cf $gaSet([set b]SyncECF) 
  set cfTxt "$b"
      
  set ret [DownloadConfFile $cf $cfTxt 1 $com]
  if {$ret!=0} {return $ret}
  
  MuxMngIO ioToCnt ioToCnt
    
  return $ret
} 

# ***************************************************************************
# SyncE_run
# ***************************************************************************
proc SyncE_run {run} {
  global gaSet
  if {$gaSet(pair)!="SE"} {
    set gaSet(fail) "It is no possible to perform SyncE test on this Tester"
    return -1
  }
  Power all on  
  after 2000
  MuxMngIO ioToCnt ioToCnt
  
  set ret [SyncELockClkTest] 
  if {$ret!=0} {return $ret}
  
  set ret [GpibOpen]
  if {$ret!=0} {
    set gaSet(fail) "Open channel to TDS fail"
    return $ret
  }
  
  set ret [ExistTds520B]
  if {$ret!=0} {return $ret}
  
  DefaultTds520b
  ##ClearTds520b
  after 2000
  SetLockClkTds   
  
  after 3000
  set ret [ChkLockClkTds]
  if {$ret!=0} {
    after 1000
    DefaultTds520b
    ##ClearTds520b
    after 2000
    SetLockClkTds 
    set ret [ChkLockClkTds]
    if {$ret!=0} {
      GpibClose
      return $ret
    }
  }
   
  set ret [SyncELockClkTest]
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [CheckJitter 100]
  GpibClose
  if {$ret=="-1" || $ret=="-2"} {return $ret}
  if {$ret>30} {
    set gaSet(fail) "Jitter: $ret nSec, should not exceed 30 nSec"
    set ret -1
  } else {
    set ret 0
  }
     
  return $ret
} 

# ***************************************************************************
# Combo_PagesSW
# ***************************************************************************
proc Combo_PagesSW {run} {
  global gaSet
  if ![info exist gaSet(logTime)] {
    set gaSet(logTime) [clock format  [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]
  }
  
  set ret 0
#   while 1 {
#     ## for ReadBarcode as CMB
#     set gaSet(DutInitName) 12CMB
#     set ret [ReadBarcode]
#     if {$ret!="0"} {return $ret}
#     set ret [RetriveDutFam]
#     set gaSet(entDUT) $gaSet(1.barcode1)
#     set ret [GetDbrName CMB]
#     if {$ret!=0} {return $ret}
#     if {[string match *.12CMB.* $gaSet(DutInitName)]==1} {
#       set ret 0
#       break
#     } else {
#       DialogBox -text "The Barcode [string range $gaSet(1.barcode1) 0 10] is not CMB" \
#           -type OK -icon images/error.gif
#     }
#   }
  if {$ret==0} {
    set ret [SetSWDownload]
    if {$ret!=0} {return $ret}
    set ret [Pages $run]
    if {$ret!=0} {return $ret}
    set ret [EntryBootMenu]
    if {$ret!=0} {return $ret}
    set ret [SoftwareDownloadTest]
    if {$ret!=0} {return $ret}
  }
  return $ret
}
# ***************************************************************************
# FD_button
# ***************************************************************************
proc FD_button {run} {
  global gaSet gaGui buffer
  RLSound::Play information
  set txt "Press the \'FD\' button for 8-10 seconds and verify the UUT is resetting"
  set res [DialogBox -type "Ok Stop" -icon /images/info -title "FD button Test" -message $txt]
  if {$res=="Stop"} {
    return -1
  }
  set ret 0
  return $ret
}
# ***************************************************************************
# FanTemperature
# ***************************************************************************
proc FanTemperature {run} {
  global gaSet gaGui buffer
  
  set ret [FanStatusTest]
  if {$ret!=0} {
    after 2000
    set ret [FanStatusTest]
    if {$ret!=0} {
      after 2000
      set ret [FanStatusTest]        
    }
  }  
  return $ret
}