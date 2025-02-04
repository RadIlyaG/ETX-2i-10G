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
  
  if ![info exist ::uutIsPs] {
    set ::uutIsPs 0
  }
  if $::uutIsPs {
    PS_RetriveDutFam
  } else {
    RetriveDutFam
  }
  
  ## 17/09/2024 12:55:57
  if {$gaSet(dbrSW)=="" || $gaSet(dbrSW)=="??"} {
    if {[string match {*There is no SW ID for SW*} $gaSet(fail)]} {
      regexp {:([A-Z0-9]+)\.} $gaSet(fail) ma val
      set gaSet(1.barcode1) $val
    }
    set ret [GetDbrSWAgain]
    if {$ret!=0} {return $ret}
  }
  set sw_norm [join [regsub -all {[\(\)A-Z]} $gaSet(dbrSW) " "]  . ] ; # 6.8.5(1.27T5) -> 6.8.5.1.27T5
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$gaSet(rbTestMode) eq "BP"} {
    set lTests BP_test
  } elseif {$gaSet(rbTestMode) eq "On_Off"} {
    set lTests On_Off
  } else {  
    if {$gaSet(cleiCodeMode) == 1} {
      set lTests WriteCleiCode
    } else {   
      if $::uutIsPs {
        set lTests [list PS_ID  PS_DataTransmission_run]; # PS_DataTransmission_conf
      } else {      
        set lTests [list BootDownload]
        if {$gaSet(rbTestMode) eq "Comp_Half19_8SFPP"} {
          ## no Pages
        } else {
          lappend lTests Pages
        }  
        
        if {$gaSet(enJat)==1 || $gaSet(enPll)==1} {
          lappend lTests Download_Jat_Pll Load_Jat_Pll
        }
        
        
        ## 13:19 11/09/2022
        if {$gaSet(rbTestMode) eq "Full" && $np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1} {
          puts "BuildTests gaSet(dbrSW):<$gaSet(dbrSW)>"
          if {$gaSet(dbrSW)=="" || $gaSet(dbrSW)=="??"} {
            if {[string match {*There is no SW ID for SW*} $gaSet(fail)]} {
              regexp {:([A-Z0-9]+)\.} $gaSet(fail) ma val
              set gaSet(1.barcode1) $val
            }
            set ret [GetDbrSWAgain]
            if {$ret!=0} {return $ret}
          }
          set sw_norm [join [regsub -all {[\(\)A-Z]} $gaSet(dbrSW) " "]  . ] ; # 6.8.5(1.27T5) -> 6.8.5.1.27T5
          
          set doorTestApp1 "6.8.2.2.75" ; ## 07:29 17/04/2023 "6.8.2.2.76"  
          set doorTestApp2 "6.8.2.0.75" ; ## 08:37 18/04/2023   
          set doorTestApp3 "6.8.2.0.999" ; ## 07:32 19/04/2023       
          if {[package vcompare $sw_norm $doorTestApp1] == "-1" &&\
              ([package vcompare $sw_norm $doorTestApp2] == "-1" || [package vcompare $sw_norm $doorTestApp3] == "1")} {
            ## If sw_norm < doorTestApp1 and (sw_norm < doorTestApp2 or w_norm < doorTestApp3), 
            ## then download special APP before DoorSwitchTest
            ## After the Test - download regular APP after DoorSwitchTest
            set appSupportsSwitch 0
          } else {
            set appSupportsSwitch 1
          }
          puts "\nsw_norm:<$sw_norm>, doorTestApp1:<$doorTestApp1>, \
            doorTestApp2:<$doorTestApp2>, doorTestApp3:<$doorTestApp3>, \
            appSupportsSwitch:<$appSupportsSwitch>\n"
          if !$appSupportsSwitch {
            lappend lTests DoorSwitchAppDownload
          } else {
            ## if sw_norm >= doorTestApp, then download regular APP
            lappend lTests SoftwareDownload
          }
          
          lappend lTests  DoorSwitchTest
          
          if !$appSupportsSwitch {
            ## if sw_norm < doorTestApp and != doorTestApp2, then download regular APP after DoorSwitchTest
            lappend lTests SoftwareDownload
          }
        } else {
          lappend lTests SoftwareDownload
        }
        
        if {$np=="8SFPP" && $up=="0_0"} {
          ## 27/01/2021 07:30:56 in Itzik's product there is no FanEepromBurn
        } else {
          if {$b=="Half19" || $b=="Half19B" || $b=="19B"} {
            lappend lTests FanEepromBurn
          }  
        } 
        
        ## 09/01/2018 07:43:31 All products should be tested with 4 10GbE ports open
        ## therefor we open the license to all
        if {$np=="8SFPP" && $up=="0_0"} {
          ## in Itzik's product there is no License
        } else {
          lappend lTests  OpenLicense
        }

        if {$gaSet(rbTestMode) eq "Comp"} {
          lappend lTests SetToDefaultWD ; # 07:19 01/08/2023 SetToDefault 
        } else {  
          lappend lTests SetToDefaultWD
        }
        
        if {($gaSet(rbTestMode) eq "Full" || $gaSet(rbTestMode) eq "MainBoard") && \
            [string match {*ATT*} $gaSet(DutInitName)] && [package vcompare $sw_norm "6.8.5.4.46"] >= "0"} {
          lappend lTests DownLoad_PsCleiCodeFile
        }
        
         
        if {[string match *.12CMB.* $gaSet(DutInitName)]==0} {
          ## if a product is NOT CMB, we cheeck ID now
          ## CMB will be checked after download its SW
          lappend lTests ID
          if {$np=="8SFPP" && $up=="0_0"} {
            ## in Itzik's product there are only SFPs, no UTP
          } else {
            lappend lTests UTP_ID
          }
          lappend lTests SFP_ID
        }
        
        ## from 23/07/2020 08:08:40 USB port is not checked
      #   if {$b=="Half19" || $b=="19"} {
      #     lappend lTestNames USBport
      #   } 
      
        set ::DG_log 1
        set sw_norm [join [regsub -all {[\(\)A-Z]} $gaSet(dbrSW) " "]  . ] 
        if {[package vcompare $sw_norm "6.8.5.1.44"] == "0" || [package vcompare $sw_norm "6.8.5.1.38"] == "0"} {
          set ::DG_log 0
        }
        if {$np=="8SFPP" && $up=="0_0"} {
            if {$gaSet(rbTestMode) eq "Comp"} {
            # no DG 
          } elseif {$gaSet(rbTestMode) eq "Full" || $gaSet(rbTestMode) eq "MainBoard"} {
            
            #if {$gaSet(DutFullName)=="ETX-2I-10G-B/8.5/AC/8SFPP" && [package vcompare $sw_norm "6.8.5.1.44"] == "0" } { }
            if {[string match {*8.5*8SFPP*} $gaSet(DutFullName)] && [package vcompare $sw_norm "6.8.5.1.44"] == "0"} {
              lappend lTests DyingGasp_conf DyingGasp_run
              set ::DG_log 0
            } else {
              lappend lTests DyingGasp_Log
            }
          }
        } else {
          if {$gaSet(rbTestMode) eq "Partial_444P"} {
            ## no DyingGasp at Ionics for 4SFPP/4SFP4UTP/PTP
          } else {
            lappend lTests DyingGasp_conf DyingGasp_run
          }
        }  
        
        if {$gaSet(rbTestMode) eq "Partial_444P"} {
          lappend lTests BIST
        } else {
          if {$::repairMode} {
            if {$gaSet(Etx220exists)} {
              lappend lTests DataTransmission_conf DataTransmission_run
            } else {
              ## no gen - no data tests
            }
          } else {
            lappend lTests DataTransmission_conf DataTransmission_run
          }
        }
        
        if {$p=="P"} {
          if {$np=="8SFPP" && $up=="0_0"} {
            if {$gaSet(rbTestMode) eq "Comp"} {
              # no PtpClock  
            } elseif {$gaSet(rbTestMode) eq "Full" || $gaSet(rbTestMode) eq "MainBoard"} {
              lappend lTests PtpClock_conf PtpClock_run
              lappend lTests ExtClk SyncE_conf SyncE_run
            }
          } else {
            if {$gaSet(rbTestMode) eq "Partial_444P"} {
              ## no ExtClk and SyncE at Ionics for 4SFPP/4SFP4UTP/PTP
            } else {
              lappend lTests PtpClock_conf PtpClock_run ; # 08:52 12/10/2023
              lappend lTests ExtClk SyncE_conf SyncE_run 
            }
          }
          
        }
        lappend lTests DDR 

        if {$np=="8SFPP" && $up=="0_0"} {
          if {$gaSet(rbTestMode) eq "Comp" || $gaSet(rbTestMode) eq "Comp_Half19_8SFPP"} {
            lappend lTests SetToDefaultAll_Save
          } elseif {$gaSet(rbTestMode) eq "Full" || $gaSet(rbTestMode) eq "MainBoard"} {
            lappend lTests SetToDefault
          }
        } else {
          lappend lTests SetToDefault
        }
        
        # if {$gaSet(rbTestMode) eq "Partial_444P"} {
          # ## no Leds_Fan at Ionics for 4SFPP/4SFP4UTP/PTP
        # } else {
          # lappend lTests Leds_FAN_conf Leds_FAN
        # }  
        ## 10:13 19/07/2023
        lappend lTests Leds_FAN_conf Leds_FAN
          
        if {[string match *.12CMB.* $gaSet(DutInitName)]==1} {
          lappend lTests Combo_PagesSW ID Combo_SFP_ID Combo_UTP_ID
        }
        if {$np=="npo" || $np=="2SFPP"} {
          lappend lTests CloseLicense
        } 

        #set ::tmpLocalUCF [clock format [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"]_${gaSet(DutInitName)}_$gaSet(pair).txt
        #set ret [GetUcFile $gaSet(DutFullName) $::tmpLocalUCF]
        #puts "BuildTests ret of GetUcFile  $gaSet(DutFullName) $gaSet(DutInitName): <$ret>"
        #if {$ret=="-1"} {
        #  set gaSet(fail) "Get User Configuration File Fail"
        #  return -1
        #}
        if {$gaSet(DefaultCF)!="" && $gaSet(DefaultCF)!="c:/aa"} {
          # if {$ret=="0"} {
            # set gaSet(fail) "No User Configuration File at Agile"
            # return -1
          # }
          lappend lTests LoadDefaultConfiguration CheckUserDefaultFile
        }
        
        if [IsOptionReqsSerNum] {    
          set gaSet(enSerNum) 1
        } else {
          set gaSet(enSerNum) 0
        }
        if {$gaSet(enSerNum) eq "1" } {
          lappend lTests WriteSerialNumber
        }
        
        if {$::repairMode} {        
          ## 08:25 13/06/2022 don't do it at David's
          ## 08:29 22/06/2023 don't do it at AviBi's
          ## 08:21 26/07/2023 don't do it if repairMode ## [string match *david-ya* [info host]] || [string match *avraham-bi* [info host]]
        } else {
          lappend lTests Mac_BarCode 
        }
        
        
        ## remove unnecessary tests for Complementary
        if {$np=="8SFPP" && $up=="0_0"} {
          if {$gaSet(rbTestMode) eq "Comp"} {
            foreach tst {"BootDownload" "SetDownload" "SoftwareDownload" "DDR" \
                          "SFP_ID" "DataTransmission_conf" "DataTransmission_run"\
                          "LoadDefaultConfiguration"} {
              set lTests [lreplace $lTests [lsearch $lTests $tst]  [lsearch $lTests $tst]]
            }
          }
          if {$gaSet(rbTestMode) eq "Comp_Half19_8SFPP"} {
            foreach tst {"BootDownload" "SetDownload" "SoftwareDownload" "DDR" \
                          "SFP_ID" "DataTransmission_conf" "DataTransmission_run"\
                          "Leds_FAN_conf" "LoadDefaultConfiguration"} {
              set lTests [lreplace $lTests [lsearch $lTests $tst]  [lsearch $lTests $tst]]
            }
          }
        }

        if {$gaSet(DutFullName)=="ETX-2I-10G-B_FT/ACDC/4SFPP/4SFP4UTP/PTP"} {
          if {$gaSet(rbTestMode) eq "Comp_444P"} {
            foreach tst {"BootDownload" "Pages" "SetDownload" "SoftwareDownload" "FanEepromBurn" "DDR" \
                          "SetToDefaultWD" "OpenLicense" "ID" "UTP_ID"  "SFP_ID" \
                          "LoadDefaultConfiguration"} {
              set lTests [lreplace $lTests [lsearch $lTests $tst]  [lsearch $lTests $tst]]
            }
          }
        }
      }
    }
  }
  set glTests [list]
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }
  
  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
  return {}
}

# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
#   AddToLog "********* DUT start *********"
  AddToPairLog $gaSet(pair) "********* DUT start *********"
  AddToPairLog $gaSet(pair) "$gaSet(rbTestMode) Tests"
#   if {$gaSet(dutBox)!="DNFV"} {
#     AddToLog "$gaSet(1.barcode1)"
#   }     
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
    
    MuxMngIO ioToGenMngToPc ioToGen
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
#     AddToLog "Test \'$testName\' started"
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
#     AddToLog "Test \'$testName\' $retTxt"
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }

  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$ret == 0 && $ps eq "noPS"} {
    Power all off
    RLSound::Play information
    set txt "Remove PS-1 and PS-2"
    set res [DialogBoxRamzor -type "OK" -icon /images/info -title "No PS option" \
          -message $txt -bg yellow -font {TkDefaultFont 11}]
    update
  }
  
  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"

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
  set ret [Wait "Wait UUT up" 30 white]
  if {$ret!=0} {return $ret}
  
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
  if {$np=="8SFPP" && $up=="0_0"} {
    if {$gaSet(rbTestMode) eq "Full"} {
      set mngPort 0/8
      MuxMngIO mngToPc nc
      RLSound::Play information
      set txt "Connect the MNG cable with SFP-30 to port 8"
      set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Dying Gasp"\
        -message $txt]
      if {$res=="Stop"} {
        return -2
      }
      set ret 0  
    } elseif {$gaSet(rbTestMode) eq "Comp"} {
      set ret 0
    }
  } else { 
    set ret 0
#     10/02/2021 08:13:53                
#     set ret [SpeedEthPort $mngPort 100]
#     if {$ret!=0} {return $ret}
    set ret [ShutDown $mngPort "shutdown"]
    if {$ret!=0} {return $ret}
    after 2000
    set ret [ShutDown $mngPort "no shutdown"]
    if {$ret!=0} {return $ret}

    
  }  
  if {$ret!=0} {return $ret}
  
  set ret [Wait "Wait Port $mngPort up" 140 white]
  if {$ret!=0} {return $ret}
  
  set ret [DyingGaspPerf 1 2]
  if {$ret!=0} {return $ret}
  
  Power all on
  set ret [Wait "Wait for ETX up" 20 white]
  if {$ret!=0} {return $ret}
  
  set ret [FactDefault std noWD]
  if {$ret!=0} {return $ret}
  
  if {$np=="8SFPP" && $up=="0_0"} {
    ## no need
    if {$gaSet(rbTestMode) eq "Full"} {
      RLSound::Play information
      set txt "Connect the MNG cable to MNG-ETH port and the SFP-P with optic loop to port 8"
      set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Dying Gasp"\
        -message $txt]
      if {$res=="Stop"} {
        return -2
      }
      set ret 0
    } elseif {$gaSet(rbTestMode) eq "Comp"} {
      set ret 0
    }   
  }
  
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
  set ret [DataTransmissionSetup 1]
  return $ret
} 

# ***************************************************************************
# SFP_ID
# ***************************************************************************
proc SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open ./TeamLeaderFiles/sfpList.txt r]
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
    } elseif {$np=="8SFPP" && $up=="0_0"} {
      set portsL [list 0/1 0/2 0/3 0/4 0/5 0/6 0/7 0/8]
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
  
  set ret [MirpesetStat]
  if {$ret!=0} {return $ret}
  
  foreach port $portsL {
    set ret [ReadEthPortStatus $port]
    if {$ret!="0"} {break}
  }
  puts "[MyTime] After try 1 of ReadEthPortStatus  ret:<$ret> port:<$port>"
  if {$ret=="-1"} {
    foreach port $portsL {
      set ret [ReadEthPortStatus $port]
      if {$ret!="0"} {return $ret}
    }
  }
  return $ret
} 
# ***************************************************************************
# Combo_SFP_ID
# ***************************************************************************
proc Combo_SFP_ID {run} {
  global gaSet glSFPs 
  
  set glSFPs [list]
  set id [open ./TeamLeaderFiles/sfpList.txt r]
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
  
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  
  set ret [Wait "Wait for UDP ports UP" 15]
  if {$ret!=0} {return $ret}
        
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
    foreach port $portsL {
      set ret [ReadUtpPortStatus $port]
      if {$ret!="0"} {return $ret}
    }
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
  set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
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
  if {$ret!=0} {
    for {set tr 1} {$tr <= 5} {incr tr} {
      puts "\nDataTransmission_run tr:$tr"
      Etx220Config 1 $10GlineRate
      if {$np=="8SFPP" && $up=="0_0"} {
        ## no 1 G Ports
      } else {
        Etx220Config 5 $1GlineRate
      }
      set ret [Wait "Waiting for data stabilization" 10 white]
      if {$ret!=0} {return $ret}
      set ret [DataTransmissionTestPerf 10]  
      puts "DataTransmission_run tr:$tr ret::$ret\n"
      if {$ret!=0} {
        if [LY_wait] {
          set ret [Wait "Wait for LY" 40]
          if {$ret!=0} {return $ret}
        } else {
          return $ret
        }
      } 
    }
  } 
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
  if !$::uutIsPs {
    Power all on 
  }
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
  Power all on
  set ret [ExtClkTxTest dis]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Unlocked]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTxTest en]
  if {$ret!=0} {return $ret}
  set ret [ExtClkTest Locked]
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on  
    Wait "Wait for UP" 40
    set ret [ExtClkTxTest en]
    if {$ret!=0} {return $ret}
    set ret [ExtClkTest Locked]
  }
  return $ret
}
# ***************************************************************************
# Leds_FAN_conf
# ***************************************************************************
proc Leds_FAN_conf {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$gaSet(rbTestMode) eq "Partial_444P"} {
    set ret [BistStartStop on]
    return $ret
  }
  
  if {$gaSet(rbTestMode) eq "MainBoard" || \
      $gaSet(rbTestMode) eq "Full" || \
      $gaSet(rbTestMode) eq "Comp_444P" || \
      $gaSet(rbTestMode) eq "Comp_Half19_8SFPP"} {
    set ret [Login]
    if {$ret!=0} {
      #set ret [Login]
      if {$ret!=0} {return $ret}
    }
    set gaSet(fail) "Logon fail"
    set com $gaSet(comDut)
    
    set ret [MirpesetStat]
    if {$ret!=0} {return $ret}
    
    Send $com "exit all\r" stam 0.25 
    set cf C:/AT-ETX-2i-10G/ConfFiles/mng_5.9.1.txt
    set cfTxt "MNG port"
    set ret [DownloadConfFile $cf $cfTxt 0 $com]
    if {$ret!=0} {return $ret}
    
    set cf $gaSet([set b]CF) 
    set cfTxt "$b"    
    set ret [DownloadConfFile $cf $cfTxt 0 $com]
    if {$ret!=0} {return $ret}
    
    set ret [ExtClkTxTest en]
    if {$ret!=0} {return $ret}
  }
  
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
  global gaSet gaGui gRelayState buffer
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  # 07:26 17/05/2023  Always check the FANs
  # if {$np=="8SFPP" && $up=="0_0"} {
    # if {$gaSet(rbTestMode) eq "MainBoard" || $gaSet(rbTestMode) eq "Full"} {
      # for {set i 1} {$i<=5} {incr i} {
        # set ret [FanStatusTest]
        # if {$ret!=0} {
          # after 2000
        # } else {
          # break
        # } 
      # }
    # } else {
      # ## don't check it in Complementary tests
      # set ret 0
    # }  
  # } else {
    # ## Not Itzik's product
    # for {set i 1} {$i<=5} {incr i} {
      # set ret [FanStatusTest]
      # if {$ret!=0} {
        # after 2000
      # } else {
        # break
      # } 
    # }
  # }  
  
  for {set i 1} {$i<=5} {incr i} {
    set ret [FanStatusTest]
    puts "\n i:$i ret:<$ret> fail:<$gaSet(fail)>"; update
    if {$ret!=0} {
      after 2000
    } else {
      break
    } 
  }
  if {$ret!=0} {return $ret}

  set gRelayState red
  IPRelay-LoopRed
  SendEmail "ETX-2I" "Manual Test"
  
  if {$gaSet(pair)==5} {
    set dutIp 10.10.10.1[set ::pair]
  } else {
    if {$gaSet(pair)=="SE"} {
      set dutIp 10.10.10.111
    } else {
      set dutIp 10.10.10.1[set gaSet(pair)]
    }  
  }
  catch {set pingId [exec ping.exe $dutIp -t &]}
  
  ## 21/06/2020 07:29:24
  if {[string match *.24SFP.PTP* $gaSet(DutInitName)]==1} {
    RLSound::Play information
    set txt "Disconnect the 3 fiber optics and \n\
    connect the 3 regular cables of the tester to ports 9, 11, 17 of the UUT"
    set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Sync_E in 24SFP/PTP"\
      -message $txt]
    if {$res=="Stop"} {
      return -2
    }
    set ret 0
  } 
  if {$np=="8SFPP" && $up=="0_0" && $p=="P"} {
    RLSound::Play information
    set txt "Disconnect the 3 fiber optics and \n\
    connect the 3 regular cables of the tester to ports 1, 3, 5 of the UUT"
    set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Sync_E in 8SFPP"\
      -message $txt]
    if {$res=="Stop"} {
      return -2
    }
    set ret 0
  } 
  
  ## 10/03/2021 15:23:48 set txt "1. Check 0.95V\n"
  set txt ""
  
  RLSound::Play information
  if {$p=="P"} {
    set tstLedState ON
  } elseif {$p=="0"} {
    set tstLedState OFF ; # 21/11/2018 09:45:38
  }
  
  if [LY_wait] {
    set ret [Wait "Wait for LY" 300]
    if {$ret!=0} {return $ret}
  }  
  
 
  if {$np=="8SFPP" && $up=="0_0" && ($gaSet(rbTestMode) eq "Comp") } {
    set txt1 "Verify that:\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'Port 7\' are ON and Blinking respectively\n"
  } elseif {$np=="8SFPP" && $up=="0_0" && ($gaSet(rbTestMode) eq "Comp_Half19_8SFPP") } {
    set txt1 "Verify that:\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'Port 5\' are ON and Blinking respectively\n"
  }  elseif {$gaSet(rbTestMode) eq "Partial_444P"} {
    set txt1 "Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  GREEN \'LINK\' led of \'MNG-ETH\' is ON\n"
  } else {
     set txt1 "Verify that:\n\
  GREEN \'PWR\' led is ON\n\
  GREEN \'LINK\' and ORANGE \'ACT\' leds of \'MNG-ETH\' are ON and Blinking respectively\n"
  }
  
  set txt2_19 "On each PS GREEN \'POWER\' led is ON\n"
  set txt2_9 "" ; #"On PS GREEN \'PWR\' led is ON\n"
  
  if {$np=="8SFPP" && $up=="0_0"} {
    if {$gaSet(rbTestMode) eq "Comp" || $gaSet(rbTestMode) eq "Comp_Half19_8SFPP"} {
      set txt3 "FAN(-s) rotate"
    } elseif {$gaSet(rbTestMode) eq "MainBoard" || $gaSet(rbTestMode) eq "Full"} {
       set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
       FAN(-s) rotate (if exists)"
    }
  } elseif {$gaSet(rbTestMode) eq "Partial_444P"}  {
    set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
  GREEN \'LINK/ACT\' leds of 1GbE ports are Blinking  (if exists)\n\
  FAN(-s) rotate"
  } else {
    set txt3 "GREEN \'LINK\' leds of 10GbE ports are ON and ORANGE \'ACT\' leds are Blinking\n\
  GREEN \'LINK/ACT\' leds of 1GbE ports are Blinking  (if exists)\n\
  EXT CLK's GREEN \'SD\' led is ON (if exists)\n\
  FAN(-s) rotate"
  }
  
  append txt $txt1
  if {$b=="19" || $b=="19B"} {
    append txt ${txt2_19}
  } elseif {$b=="Half19" || $b=="Half19B"} {
    append txt ${txt2_9}
  } 
  append txt $txt3
  
  set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LEDs_FAN Test" -message $txt]
  update
  
  if {$res!="OK"} {
    set gaSet(fail) "LED Test failed"
    if [LY_wait] {
      set trQty 10
      for {set tr 1} {$tr <= $trQty} {incr tr} {
        set res [DialogBoxRamzor -type [list "OK" "Repeat ($tr/$trQty)" "Fail"] -icon /images/question -title "LEDs_FAN Test" -message $txt]
        update
        if {$res=="OK"} {
          set ret 0
          #catch {exec pskill.exe -t $pingId}
          ::twapi::end_process $pingId -force
          break
        } elseif {$res=="Fail"} {
          set ret -1
        } else {
          set ret -1
          continue
        }
        if {$ret!=0} {
          #catch {exec pskill.exe -t $pingId}
          ::twapi::end_process $pingId -force
          return $ret
        }
      }
      if {$ret!=0} {
        #catch {exec pskill.exe -t $pingId}
        ::twapi::end_process $pingId -force
        return $ret
      }
    } else {
      #catch {exec pskill.exe -t $pingId}
      ::twapi::end_process $pingId -force
      return -1
    }
  } else {
    set ret 0
    #catch {exec pskill.exe -t $pingId}
    ::twapi::end_process $pingId -force
  }
  
  if {$np=="8SFPP" && $up=="0_0" && ($gaSet(rbTestMode) eq "Full" || $gaSet(rbTestMode) eq "MainBoard")} {
    set ret [TstAlmLedTest]
    if {$ret!=0} {return $ret} 
  } else {
    set ret 0
  }
  
  if {$b=="19" || $b=="19B"} {
    foreach ps {2 1} {
      Power $ps off
      #after 10000
      # set ret [Wait "Wait for PS-$ps is OFF" 5 white]
      # if {$ret!=0} {return $ret}
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
      
      if {$gaSet(rbTestMode) eq "MainBoard"} {
        set res "OK"
      } else {  
        RLSound::Play information
        set txt "Verify on PS-$ps that RED led is ON"
        set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      }
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
      
      if {$b=="19" || ($b=="19B" && $np=="8SFPP" && $up=="0_0") || \
          ($b=="19B" && [string match *.ACDC.* $gaSet(DutInitName)]) || \
          ($b=="19B" && [string match *.ACAC.* $gaSet(DutInitName)]) || \
          ($b=="19B" && [string match *.DCDC.* $gaSet(DutInitName)]) || \
          ($b=="19B" && [string match *B_*.ACR.* $gaSet(DutInitName)])|| \
          ($b=="19B" && [string match *B_*.DCR.* $gaSet(DutInitName)])|| \
          ($b=="19B" && [string match *B.19.ACR.* $gaSet(DutInitName)])|| \
          ($b=="19B" && [string match *B.19.DCR.* $gaSet(DutInitName)])|| \
          ($b=="19B" && [string match *B_VT.19.NULL.* $gaSet(DutInitName)])} {
        
        # if {$np=="8SFPP" && $up=="0_0" && $gaSet(rbTestMode) eq "MainBoard" || \
            # $np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1 && $gaSet(rbTestMode) eq "Full"} {}
        if {$np=="8SFPP" && $up=="0_0" && $gaSet(rbTestMode) eq "MainBoard"} {    
          set res "OK"        
        } else {
          RLSound::Play information
          set txt "Remove PS-$ps and verify that led is OFF"
          set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
        }
        update
        if {$res!="OK"} {
          set gaSet(fail) "PS_ID Test failed"
          return -1
        } else {
          set ret 0
        }
        
        # if {$np=="8SFPP" && $up=="0_0" && $gaSet(rbTestMode) eq "MainBoard" || \
            # $np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1 && $gaSet(rbTestMode) eq "Full"} {}
        if {$np=="8SFPP" && $up=="0_0" && $gaSet(rbTestMode) eq "MainBoard"} {      
          set ret 0
        } else {  
          set val [ShowPS $ps]
          puts "val:<$val>"
          if {$val=="-1"} {return -1}
          if {$val!="Not exist"} {
            set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"Not exist\""
      #       AddToLog $gaSet(fail)
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
        }
      }  
      Power $ps on
      after 2000      
    }
    if {$np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1 && $gaSet(rbTestMode) eq "Full"} {
      RLSound::Play information
      set txt "Close the screws of both PSs firmly and verify PSs are ON"
      set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "PS_ID Test failed"
        return -1
      } else {
        set ret 0
      }
      
      set val [ShowPS 1]
      foreach {b r p d psType np up} [split $gaSet(dutFam) .] {}
      if {$psType eq "DC"} {
        set res [regexp {1\s+DC\s+OK\s+2\s+DC\s+OK} $buffer ma]
      } elseif {$psType eq "AC"} {
        set res [regexp {1\s+AC\s+OK\s+2\s+AC\s+OK} $buffer ma]
      }
      if {$res!=1} {
        set gaSet(fail) "Status of PSs is not \"1 $psType OK 2 $psType OK\""
        return -1
      }
      
    }
  }
  
  if {$p=="P"} {
    if {$gaSet(rbTestMode) eq "Partial_444P"}  {
      set ret 0
    } else {
      RLSound::Play information
      set txt "Remove the EXT CLK cable and verify the SD led is OFF"
      set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
    }
  }
 

  if {[string match *.12CMB.* $gaSet(DutInitName)]==0} {
    ## if an UUT is not CMB we should pull out all the cables
    ## if the product is CMB, we will pull out them later in UTP_ID
    if {$np=="8SFPP" && $up=="0_0" &&  ($gaSet(rbTestMode) eq "Comp" || $gaSet(rbTestMode) eq "Comp_Half19_8SFPP")} {
      ## don't check leds
      set ret 0
    } else {
      RLSound::Play information
      set txt "Disconnect all cables and optic fibers (except POWER and CONTROL) and verify GREEN leds are OFF"
      
      set res [DialogBoxRamzor -type "OK Fail" -icon /images/question -title "LED Test" -message $txt]
      update
      if {$res!="OK"} {
        set gaSet(fail) "LED Test failed"
        return -1
      } else {
        set ret 0
      }
    }
    
    set res [regexp {\.[AD]{1,2}C\.} $gaSet(DutInitName)]
    puts "Leds_Fan $gaSet(DutInitName) res:<$res>"
    if {$res==0} {
      # if two PSs - no message
      set ret 0
    } else {
      if {$b=="Half19" || $b=="Half19B"} {
        # if Box is half - no PS-2  
        set ret 0
      } elseif {$np=="8SFPP" && $up=="0_0" && $gaSet(rbTestMode) eq "MainBoard"} {
        # if TestMode is MainBoard - no message  
        set ret 0
      } else {
        # if not 8SFPP, or 8SFPP but not Mainboard
        Power 2 off
        RLSound::Play information
        set txt "Remove PS-2"
        set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" \
          -message $txt -bg yellow -font {TkDefaultFont 11}]
        update
        
        if {$res!="OK"} {
          set gaSet(fail) "LED Test failed"
          return -1
        } else {
          set ret 0
        }
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
  set ret [FactDefault stda noWD]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# SetToDefaultWD
# ***************************************************************************
proc SetToDefaultWD {run} {
  global gaSet gaGui
  Power all on
  set ret [FactDefault std wd]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# OpenLicense
# ***************************************************************************
proc OpenLicense {run} {
  global gaSet gaGui
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
  set ret [FactDefault stda Close]
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
  set pair $::pair 
  puts "Mac_BarCode \"$pair\" "
  mparray gaSet *mac* ; update
  mparray gaSet *barcode* ; update
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [ReadMac]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  
  set ret [GuiReadVneNum]
  if {$ret!=0} {return $ret}
  
  #set ret [ReadBarcode [PairsToTest]]
#   set ret [ReadBarcode]
#   if {$ret!=0} {return $ret}
  set ret [RegBC]
      
  return $ret
}

# ***************************************************************************
# LoadDefaultConfiguration
# ***************************************************************************
proc LoadDefaultConfiguration {run} {
  global gaSet  
  Power all on
  set ret [FactDefault std noWD]
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
  global gaSet buffer gaGet
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [GetPageFile $gaSet($::pair.barcode1) $gaSet($::pair.traceId)]
  if {$ret!=0} {return $ret}
  
   set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if {$np=="8SFPP" && $up=="0_0"} { 
    set p1_5  [lindex $gaGet(page1) 5]
    set p2_14 [lindex $gaGet(page2) 14]
    puts "Pages p1_5:<$p1_5> p2_14:<$p2_14>"
    AddToPairLog $gaSet(pair) "Page1: $p1_5, Page2: $p2_14"
    if {$p1_5=="01" && $p2_14=="0C"} {
      set ret 0
    } elseif {($p1_5=="02" || $p1_5=="03") && ($p2_14=="1C" || $p2_14=="1D")} {
      set ret 0
    } elseif {$p1_5=="04" && $p2_14=="1E"} {
      set ret 0
    } else {
      set gaSet(fail) "Mismatch between Page1: $p1_5 to Page2: $p2_14"
      set ret -1
    }  
  }
  
  return $ret
}
# ***************************************************************************
# SoftwareDownload
# ***************************************************************************
proc SoftwareDownload {run} {
  set ret [SetSWDownload]
  if {$ret!=0} {return $ret}
  
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
    return -2
  }
  Power all on 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  
  ## 21/06/2020 07:29:24
  if {[string match *.24SFP.PTP* $gaSet(DutInitName)]==1} {
    set txt "Connect 3 fiber optics between:\n\
    Port 1 of AUX 2 (A) to Port 11 of the UUT\n\
    Port 1 of AUX 1 (B) to Port 17 of the UUT\n\
    Port 3 of AUX 1 (C) to Port 9 of the UUT"
    set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Sync_E in 24SFP/PTP"\
      -message $txt]
    if {$res=="Stop"} {
      return -2
    }
    set ret 0
  }  
  if {$np=="8SFPP" && $up=="0_0"} {
    set txt "Connect 3 fiber optics between:\n\
    Port 1 of AUX 2 (A) to Port 5 of the UUT\n\
    Port 1 of AUX 1 (B) to Port 1 of the UUT\n\
    Port 3 of AUX 1 (C) to Port 3 of the UUT"
    set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "Sync_E in 8SPP"\
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
    return -2
  }
  Power all on  
  after 2000
  MuxMngIO ioToCnt ioToCnt
  
  set ret [SyncELockClkTest] 
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on  
    Wait "Wait for UP" 40
    set ret [SyncELockClkTest]
    if {$ret!=0} {
      return $ret
    }
  }
  
  set ret [GpibOpen]
  if {$ret!=0} {
    set gaSet(fail) "No communication with Scope"
    return $ret
  }
  
  set ret [ExistTds520B]
  if {$ret!=0} {return $ret}
  
  for {set tr 1} {$tr <= 3} {incr tr} {
    puts "\n[MyTime] Try $tr of ChkLockClkTds"
    MuxMngIO ioToCnt ioToCnt
    DefaultTds520b    
    ##ClearTds520b
    after 2000
    SetLockClkTds   
    after 3000
    set ret [ChkLockClkTds]
    puts "Result of Try $tr of ChkLockClkTds: <$ret>"
    if {$ret!=0} {
      after 1000
    } else {
      break
    }
  }    
  if {$ret!=0} {
    GpibClose
    return $ret
  }
   
  set ret [SyncELockClkTest]
  if {$ret!=0} {
    Power all off
    after 3000
    Power all on  
    Wait "Wait for UP" 40
    set ret [SyncELockClkTest]
  }
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
  set res [DialogBoxRamzor -type "Ok Stop" -icon /images/info -title "FD button Test" -message $txt]
  if {$res=="Stop"} {
    return -1
  }
  set ret 0
  return $ret
}
# ***************************************************************************
# WriteSerialNumber
# ***************************************************************************
proc WriteSerialNumber {run} {
  global gaSet gaGui buffer
  set ret [GuiReadSerNum]
  parray gaSet *serialNum*
  if {$ret!=0} {return $ret}  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}   
  set ret [WritePage0_SN]
  if {$ret!=0} {return $ret} 
    set ret [AdminFactAll]
    if {$ret!=0} {return $ret} 
    set ret [VerifySN]
    if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# Download_Jat_Pll
# ***************************************************************************
proc Download_Jat_Pll {run} {
  set ret [SetJatPllDownload]
}
# ***************************************************************************
# Load_Jat_Pll
# ***************************************************************************
proc Load_Jat_Pll {run} {
  set ret [Load_Jat_Pll_Perf]
}

# ***************************************************************************
# DyingGasp_Log
# ***************************************************************************
proc DyingGasp_Log {run} {
  set ret [Dyigasp_ClearLog]
  if {$ret!=0} {return $ret}
  Power all off
  after 3000
  Power all on
  set ret [Wait "Wait UUT up" 30 white]
  if {$ret!=0} {return $ret}
  set ret [Dyigasp_ReadLog]
  return $ret
}
# ***************************************************************************
# PtpClock_conf
# ***************************************************************************
proc PtpClock_conf {run} {
  set ret 0
  #set ret [FactDefault std noWD]
  if {$ret!=0} {return $ret}
  set ret [PtpClock_conf_perf]
  return $ret
}

# ***************************************************************************
# PtpClock_run
# ***************************************************************************
proc PtpClock_run {run} {
  set ret [Wait "PTP Clock Recovering" 10 white]
  set ret [PtpClock_run_perf]
  if {$ret!=0} {
    set ret [Wait "PTP Clock Recovering" 10 white]
    set ret [PtpClock_run_perf]
  if {$ret!=0} {return $ret}
  }
  set ret [FactDefault std noWD]
  
  return $ret
}
# ***************************************************************************
# DoorSwitchAppDownload
# ***************************************************************************
proc DoorSwitchAppDownload {run} {
  set ret [DoorSwitchSetSWDownload]
  if {$ret!=0} {return $ret}
  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}
  
  set ret [DoorSwitchAppDownloadTest]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# DoorSwitchTest
# ***************************************************************************
proc DoorSwitchTest {run} {
  set ret [DoorSwitchTestPerf]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# WriteCleiCode
# ***************************************************************************
proc WriteCleiCode {run} {
  global gaSet gaGui buffer
  set ret [GuiReadSerNum]
  parray gaSet *serialNum*
  if {$ret!=0} {return $ret}  
  set ret [EntryBootMenu]
  if {$ret!=0} {return $ret}   
  set ret [WritePage0_CLEI]
  if {$ret!=0} {return $ret} 
    set ret [AdminFactAll]
    if {$ret!=0} {return $ret} 
  return $ret
}
# ***************************************************************************
# BP_test
# ***************************************************************************
proc BP_test {run} {
  global gaSet gaGui gRelayState
  Status ""
  Power all on
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  foreach ps {2 1} {
    set val [ShowPS $ps]
    puts "val:<$val>"
    if {$val=="-1"} {return -1}
    if {$val!="OK"} {
      set gaSet(fail) "Status of PS-$ps is \"$val\". Expected \"OK\""
      return -1
    }
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
      
    set res "OK"
    set ret 0
          
    RLSound::Play information
    set txt "Remove PS-$ps and verify that led is OFF"
    set res [DialogBoxRamzor -type "OK Cancel" -icon /images/info -title "LED Test" -message $txt]
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
  return $ret
}

# ***************************************************************************
# On_Off 
# ***************************************************************************
proc On_Off {run} {
  global gaSet gaGui gRelayState
  Status ""
  set retRet 0
  set offDur 5
  if {[string is integer $gaSet(entDUT)] && [string length $gaSet(entDUT)]>0} {
    set offOnQty $gaSet(entDUT)
  } else {
    set offOnQty 50
    set gaSet(entDUT) $offOnQty
  }
  set r [set p [set f 0]]
  for {set i 1} {$i<=$offOnQty} {incr i} {
    Status "OFF-ON $i from $offOnQty"
    set r $i
    Power all off
    set ret [Wait "$offDur sec in OFF state" $offDur white]
    if {$ret!=0} {return $ret} 
    Power all on
    set ret [Login]
    if {$ret=="-2"} {return $ret}
    if {$ret==0} {
      set res PASS
      incr p
    } elseif {$ret=="-1"} {
      set res FAIL_$gaSet(fail)
      set retRet -1
      incr f
    }
    puts "OFF-ON $i from $offOnQty. Res: $res\n"; update
    AddToPairLog $gaSet(pair) "OFF-ON $i Result:$res"
    set st "$gaSet(logTime) Run:$r, Pass:$p, Fail:$f"
    $gaSet(startTime) configure -text $st
  }
  return $retRet
}

# ***************************************************************************
# SetToDefaultAll_Save
# ***************************************************************************
proc SetToDefaultAll_Save {run} {
  global gaSet 
  Power all on
  set ret [FactDefault stda noWD]
  if {$ret!=0} {return $ret}
  set ret [SaveRunningConf]
  return $ret 
}

# ***************************************************************************
# CheckUserDefaultFile
# ***************************************************************************
proc CheckUserDefaultFile {run} {
  global gaSet 
  Power all on
  set ret [CheckUserDefaultFilePerf]
  return $ret 
}

# ***************************************************************************
# BIST
# ***************************************************************************
proc BIST {run} {
  global gaSet 
  Power all on
  set ret [BistPerf]
  return $ret 
}

proc stam {} {

}

# ***************************************************************************
# DownLoad_PsCleiCodeFile
# ***************************************************************************
proc DownLoad_PsCleiCodeFile {run} {
  global gaSet 
  Power all on
  set ret [PsCleiCode_Config]
  if {$ret!=0} {return $ret}
  set ret [PsCleiCode_DownLoad]
  return $ret 
}
