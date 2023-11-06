#***************************************************************************
#** OpenRL
#***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  #set ret3 [OpenComAux] 
#   if {[string match {*Mac_BarCode*} $gaSet(startFrom)] || [string match {*Leds*} $gaSet(startFrom)] ||\
#       [string match {*Memory*} $gaSet(startFrom)]      || [string match {*License*} $gaSet(startFrom)] ||\
#       [string match {*FactorySet*} $gaSet(startFrom)]  || [string match {*SaveUserFile*} $gaSet(startFrom)] ||\
#       [string match {*SetToDefaultAll*} $gaSet(startFrom)] } {
#     set openGens 0  
#   } else {
#     set openGens 1
#   } 

  ## 14/01/2019 09:53:28 open Gen anyway
  if {$::repairMode} {
    if {$gaSet(Etx220exists)} {
      set openGens 1
    } else {
      set openGens 0
    }
  } else {
    set openGens 1
  }  
  if {$openGens==1} {  
    Status "Open ETH GENERATOR"
    set ret2 0
    set gaSet(id220)  [RL10GbGen::Open $gaSet(com220)]
#    set ret2 [RL10GbGen::Init $gaSet(id220)]
##   set ret [RLSerial::Open $gaSet(com220) 115200 n 8 1]
    if {$ret2!=0} {set gaSet(fail) "Cann't open COM-$gaSet(com220)"}
    
  } else {
    set ret2 0
  }  
   
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2 " ; update
  if {$ret1!=0 || $ret2!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  set ret [RLSerial::Open $gaSet(comDut) 9600 n 8 1]
  ##set ret [RLCom::Open $gaSet(comDut) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comDut) fail"
  }
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# OpenComAux
# ***************************************************************************
proc OpenComAux {} {
  global gaSet
  if {$gaSet(pair)=="SE"} {
    ## only UUT1 tested by SyncE
    set ret [RLSerial::Open $gaSet(comAux1) 9600 n 8 1]
    ##set ret [RLCom::Open $gaSet(comAux1) 9600 8 NONE 1]
    if {$ret!=0} {
      set gaSet(fail) "Open COM $gaSet(comAux1) fail"
    }
    set ret [RLSerial::Open $gaSet(comAux2) 9600 n 8 1]
    ##set ret [RLCom::Open $gaSet(comAux2) 9600 8 NONE 1]
    if {$ret!=0} {
      set gaSet(fail) "Open COM $gaSet(comAux2) fail"
    }
  } else {
    ## only UUT1 tested by SyncE
    set ret 0
  }
  return $ret
}
# ***************************************************************************
# CloseComAux
# ***************************************************************************
proc CloseComAux {} {
  global gaSet
  if {$gaSet(pair)=="SE"} {
    ## only UUT1 tested by SyncE
    catch {RLSerial::Close $gaSet(comAux1)}
    catch {RLSerial::Close $gaSet(comAux2)}
#     catch {RLCom::Close $gaSet(comAux1)}
#     catch {RLCom::Close $gaSet(comAux2)}
  }
  return {}
}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  catch {RLSerial::Close $gaSet(comDut)}
  ##catch {RLCom::Close $gaSet(comDut)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
#   catch {RLEtxGen::CloseAll}
  catch {RL10GbGen::Close $gaSet(id220)}
  #catch {RLScotty::SnmpCloseAllTrap}
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  # parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=7 && [llength $boxL]!=14 && [llength $boxL]!=28} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2} {
    set gaSet(idPwr$rb) [RLUsbPio::Open $rb RBA $channel]
  }
#   set gaSet(idDrc) [RLUsbPio::Open 1 PORT $channel]
#   RLUsbPio::SetConfig $gaSet(idDrc) 11111111 ; # all 8 pins are IN
  
 set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2" {
	  catch {RLUsbPio::Close $gaSet(idPwr$rb)}
  }
  catch {RLUsbPio::Close $gaSet(idDrc)}
  catch {RLUsbMmux::Close $gaSet(idMuxMngIO)}
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  puts "SaveUutInit $fil"
  set id [open $fil w]
  puts $id "set gaSet(sw)          \"$gaSet(sw)\""
  puts $id "set gaSet(dbrSW)       \"$gaSet(dbrSW)\""
  puts $id "set gaSet(swPack)      \"$gaSet(swPack)\""
  
  puts $id "set gaSet(dbrBVerSw)   \"$gaSet(dbrBVerSw)\""
  puts $id "set gaSet(dbrBVer)     \"$gaSet(dbrBVer)\""
  if ![info exists gaSet(cpld)] {
    set gaSet(cpld) ???
  }
  puts $id "set gaSet(cpld)        \"$gaSet(cpld)\""
  
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  foreach indx {Boot SW 19 Half19  DGasp ExtClk 19SyncE Half19SyncE Aux1 Aux2 Default 19B Half19B 19BSyncE Half19BSyncE } {
    if ![info exists gaSet([set indx]CF)] {
      set gaSet([set indx]CF) ??
    }
    puts $id "set gaSet([set indx]CF) \"$gaSet([set indx]CF)\""
  }
  foreach indx {licDir} {
    if ![info exists gaSet($indx)] {
      puts "SaveUutInit fil:$SaveUutInit gaSet($indx) doesn't exist!"
      set gaSet($indx) ???
    }
    puts $id "set gaSet($indx) \"$gaSet($indx)\""
  }
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  puts $id "set gaSet(performShortTest) \"$gaSet(performShortTest)\""  
  
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 0
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  if {![info exists gaSet(ddrMultyQty)]} {
    set gaSet(ddrMultyQty) 5
  }
  puts $id "set gaSet(ddrMultyQty) \"$gaSet(ddrMultyQty)\""
  
  if {![info exists gaSet(scopeModel)]} {
    set gaSet(scopeModel) Tds340
  }
  puts $id "set gaSet(scopeModel) \"$gaSet(scopeModel)\""
  
  if {![info exists gaSet(enSerNum)]} {
    set gaSet(enSerNum) 0
  }
  puts $id "set gaSet(enSerNum) \"$gaSet(enSerNum)\""
  
  if {![info exists gaSet(enJat)]} {
    set gaSet(enJat) 0
  }
  puts $id "set gaSet(enJat) \"$gaSet(enJat)\""
  
  if {![info exists gaSet(enPll)]} {
    set gaSet(enPll) 0
  }
  puts $id "set gaSet(enPll) \"$gaSet(enPll)\""
  
  if {![info exists gaSet(rbTestMode)]} {
    set gaSet(rbTestMode) "Full"
  }
  puts $id "set gaSet(rbTestMode) \"$gaSet(rbTestMode)\""
  
  if {![info exists gaSet(enVneNum)]} {
    set gaSet(enVneNum) 0
  }
  puts $id "set gaSet(enVneNum) \"$gaSet(enVneNum)\""
  
  if {![info exists gaSet(Etx220exists)]} {
    set gaSet(Etx220exists) 0
  }
  puts $id "set gaSet(Etx220exists) \"$gaSet(Etx220exists)\""
  
  close $id   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent {expected stamm} {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  
  if ![info exists ::reduceSpaces] {
    set ::reduceSpaces 1
  }
  if {$::reduceSpaces==1} {  
    ## replace a few empties by one empty
    regsub -all {[ ]+} $sent " " sent
  } 

  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  if {$expected=="stamm"} {
    set cmd [list RLSerial::Send $com $sent]
    ##set cmd [list RLCom::Send $com $sent]
    foreach car [split $sent ""] {
      set asc [scan $car %c]
      #puts "car:$car asc:$asc" ; update
      if {[scan $car %c]=="13"} {
        append sentNew "\\r"
      } elseif {[scan $car %c]=="10"} {
        append sentNew "\\n"
      } {
        append sentNew $car
      }
    }
    set sent $sentNew
  
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent"
    puts "send: ----------------------------------------\n"
    update
    return $ret
    
  }
  
  #puts "Send sent:<$sent>" 
  set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  ##set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } else {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=$expected, buffer=<$buffer>"
    puts "send: ----------------------------------------\n"
    update
  }
  
  #RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}

##***************************************************************************
##** Wait
##***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	  $gaSet(runTime) configure -text $i
	  RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}

#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}

# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    #set ret [Send $com \r stam $testEach]
    #set ret [RLSerial::Waitfor $com buffer stam $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      if [string match *$expd* $buffer] {
        set ret 0
      }
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:\"$expd\" ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        break
      }
    }
    
    if {[string match {*boot*} $expd] && [string match {*HW Failure*} $buffer]} {
      set ret "HW Failure"
      break
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}   
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
#   return 0
  set ret 0
  switch -exact -- $ps {
    1   {set pioL 1}
    2   {set pioL 2}
    all {set pioL "1 2"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RLUsbPio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RLUsbPio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  puts "\nGuiPower $n $state"
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 - 5.1 - SE.1 {set portL [list 1]}
    1.2 - 2.2 - 3.2 - 4.2 - 5.2 - SE.2 {set portL [list 2]}      
    1 - 2 - 3 - 4 - 5 - SE - all       {set portL [list 1 2]}  
  }        
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $portL {
      set id [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$id>"
      RLUsbPio::Set $id $state
      RLUsbPio::Close $id
    }   
  }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  if [info exists gaSet(log.$pair)] {
    set log $gaSet(log.$pair)
  } else {
    if [info exists gaSet(logTime)] { 
      set log c:/logs/${gaSet(logTime)}.txt 
    } else {
      set log c:/logs/[clock format [clock seconds] -format "%Y.%m.%d-%H.%M.%S"].txt 
    }    
  }
  set logFileID [open $log a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# ShowLog 
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
#     exec notepad $gaSet(logFile.$gaSet(pair)) &
#   }
  if {[info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
    exec notepad $gaSet(log.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {mode} {
  global gaSet gaGui
  Status "Please wait for retriving DBR's parameters"
  
  set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  puts "\r[MyTime] GetDbrName $mode $barcode"; update
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  wm title . "$gaSet(pair) : "
  after 500
  
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  set res [catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b]
  #puts "res:<$res> b:<$b>"
  if [string match *Exception* $b] {
    set gaSet(fail) "Network connection problem"
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrName Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrName Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $res .]
  puts "GetDbrName res:<$res>"
  puts "GetDbrName initName:<$initName>"
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    source uutInits/$gaSet(DutInitName)  
    #UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw} {
      puts "GetDbrName gaSet($v) does not exist"
      set gaSet($v) ??
    }
    foreach en {licEn} {
      set gaSet($v) 0
    } 
  } 
  wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  pack forget $gaGui(frFailStatus)
  #Status ""
  update
  if {$mode=="full"} {
    BuildTests
    
    set ret [GetDbrSW $barcode]
    puts "GetDbrName ret of GetDbrSW:$ret" ; update
    if {$ret!=0} {
      RLSound::Play fail
  	  Status "Test FAIL"  red
      DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrName Problem"
      pack $gaGui(frFailStatus)  -anchor w
  	  $gaSet(runTime) configure -text ""
    }
  } else {
    set ret 0
  }
  puts ""
  
  focus -force $gaGui(curTest)
  if {$ret==0} {
    Status "Ready"
  }
  return $ret
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}

# ***************************************************************************
# RetriveDutFam
# RetriveDutFam [regsub -all / ETX-2I-10G-B_ATT/19/DCR/8SFPP .].tcl
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  set gaSet(dutFam) NA 
  set gaSet(dutBox) NA 
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "RetriveDutFam $dutInitName"
  if {[string match *10G-B* $dutInitName]==1 || [string match *10G_C* $dutInitName]==1} {
    puts "if 01"
    if {[string match *B.AC.* $dutInitName]==1 || \
        [string match *.DDC.* $dutInitName]==1 || [string match *B.8.5.* $dutInitName]==1 ||\
        [string match *B_PLD.8.5.* $dutInitName]==1 || [string match *B_OPT.* $dutInitName]==1 ||\
        [string match *B_TWC.8.5.* $dutInitName]==1 || \
        [string match *B_C.8.5.* $dutInitName]==1 || [string match *_C.8.5.* $dutInitName]==1 ||\
        [string match *B_FTR.8.5.* $dutInitName]==1 || [string match *B_MMC.8.5.* $dutInitName]==1} {
      set gaSet(dutFam) Half19B.0.0.0.0.0.0
      puts "if 011"
    } elseif {[string match *B.19.DCR.8SFPP* $dutInitName]==1 || [string match *B.19.ACR.8SFPP* $dutInitName]==1 || \
              [string match *.ACDCI.* $dutInitName]==1 || [string match *.ACACI.* $dutInitName]==1 || \
              [string match *B.19.* $dutInitName]==1 || \
              [string match *.ACDC.* $dutInitName]==1 || [string match *.ACAC.* $dutInitName]==1 || \
              [string match *.DCDC.* $dutInitName]==1 || \
              [string match *B_*.ACR.* $dutInitName]==1 || [string match *B_*.DCR.* $dutInitName]==1 || \
              [string match *B_*.DR.* $dutInitName]==1 || \
              [string match *B_*.AC.* $dutInitName]==1 || [string match *B_*.DC.* $dutInitName]==1 || \
              [regexp {ODU?\.8} $dutInitName]==1 || \
              [string match *_C.19.H.DR.* $dutInitName]==1 || [string match *_C.19.DR.* $dutInitName]==1 || \
              [string match *B_TWC.19.* $dutInitName]==1 || [string match *B_VT.19.* $dutInitName]==1 || \
              [string match *B_GC.19.*.4SFPP4SFP $dutInitName]==1 } {
      puts "if 012"
      set gaSet(dutFam) 19B.0.0.0.0.0.0
      ## 29/06/2022 14:27:11
      ## exceptions
      if {$dutInitName == "ETX-2I-10G_CELLCOM.ACDC.24SFP.tcl" || \
          $dutInitName == "ETX-2I-10G_CELLCOM.ACDC.2SFPP.24SFP.tcl" || \
          $dutInitName == "ETX-2I-10G_CELLCOM.ACDC.4SFPP.24SFP.tcl"} {
        puts "if 0121"
        set gaSet(dutFam) 19.0.0.0.0.0.0
      }
    }
  } elseif {[string match *.8.5.* $dutInitName]==1} {
    puts "if 02"
    ## 10:50 08/11/2022
    set gaSet(dutFam) Half19B.0.0.0.0.0.0
  } elseif {[string match *10G_ATT.*.8SFPP* $dutInitName]} {
    puts "if 03"
    ## 09:31 26/05/2022 In new 2I-10G parts defined with FPGA 660 the -B was removed from the Marketing and the DBR Assembly
      ## ETX-2I-10G_ATT/19/AC/8SFPP
      ## ETX-2I-10G_ATT/19/ACR/8SFPP
      ## ETX-2I-10G_ATT/19/DC/8SFPP
      ## ETX-2I-10G_ATT/19/DCR/8SFPP
      ## ETX-2I-10G_ATT/H/DCR/ODU/8SFPP
    ## but still it is the 19B box
    set gaSet(dutFam) 19B.0.0.0.0.0.0
  } elseif {[regexp {10G\.19\.[AD]CR?\.8S?F?P?P}  $dutInitName]} {
    puts "if 04"
    ## 07/08/2022 New naming format
    set gaSet(dutFam) 19B.0.0.0.0.0.0
  } elseif {[regexp {10G\.19\.H?\.?[AD]CR?\.8S?F?P?P}  $dutInitName]} {
    puts "if 05"
    ## 08/11/2022 New naming format
    set gaSet(dutFam) 19B.0.0.0.0.0.0
  } else {
    puts "if 06"
    if {[string match *.12SFP* $dutInitName]==1 || [string match *.12S12U* $dutInitName]==1 || [string match *.24SFP* $dutInitName]==1 || [string match *.12CMB.* $dutInitName]==1} {
      puts "if 061"
      set gaSet(dutFam) 19.0.0.0.0.0.0
    } else {
      puts "if 062"
      set gaSet(dutFam) Half19.0.0.0.0.0.0
    }
  }
  if {$dutInitName == "ETX-2I-10G_COV.ACR.4SFPP.24SFP.tcl"} {
    puts "if 07.1"
    set gaSet(dutFam) 19.0.0.0.0.0.0
  }
  if {$dutInitName == "ETX-2I-10G_FTR.19.HN.DCR.8SFPP.K04N.tcl"} {
    puts "if 07.2"
    set gaSet(dutFam) 19.0.0.0.0.0.0
  }
  if {$dutInitName == "ETX-2I-10G.19.H.ACDC.8SFPP.PTP.tcl"} {
    puts "if 07.3"
    set gaSet(dutFam) 19.0.0.0.0.0.0
  }
  
  set npo npo
  set upo upo
  if {[string match *.2SFPP.* $dutInitName]==1 || [string match *.2SFPP2SFP.* $dutInitName]==1} {    
    set npo 2SFPP
  } elseif {[string match *.4SFPP.* $dutInitName]==1} {    
    set npo 4SFPP
  } elseif {[string match *.8SFPP.* $dutInitName]==1 || [string match *.8P.* $dutInitName]==1 ||\
            [string match *.4SFPP4SFP.* $dutInitName]==1} {    
    set npo 8SFPP
    set upo 0_0    
  }
  
  if {[string match *PP.4SFP.* $dutInitName]==1} {
    set upo 4SFP_0
  } elseif {[string match *PP.4SFP4UTP.* $dutInitName]==1 || \
            [string match *.4SFP4UTP.* $dutInitName]==1 || \
            [string match *.4S.4U.* $dutInitName]==1 || \
            [string match *.4S4U.* $dutInitName]==1} {
    set upo 4SFP_4UTP
  } elseif {[string match *PP.12SFP12UTP.* $dutInitName]==1} {
    set upo 12SFP_12UTP
  } elseif {[string match *PP.12SFP12SFP.* $dutInitName]==1} {
    set upo 12SFP_12SFP
  } elseif {[string match *PP.24SFP.* $dutInitName]==1} {
    set upo 24SFP_0
  } elseif {[string match *PP.8SFP.* $dutInitName]==1} {
    set upo 8SFP_0
  } elseif {[string match *.12SFP12UTP.* $dutInitName]==1} {
    set upo 12SFP_12UTP
  } elseif {[string match *.12S12U.* $dutInitName]==1} {
    set upo 12SFP_12UTP
  } elseif {[string match *.24SFP.* $dutInitName]==1} {
    set upo 24SFP_0
  } elseif {[string match *.12CMB.* $dutInitName]==1} {
    set upo 12SFP_12UTP ; # 23/07/2020 07:50:08 12SFP_0
  } 
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$ps.$npo.$upo  
  }
  
#   if {[string match *.RTR.* $dutInitName]==1} {
#     foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
#       set gaSet(dutFam) $b.R.$p.$d.$ps.$np.$up  
#     }
#   }
  if {[string match *.PTP.* $dutInitName]==1} {
    foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
      set gaSet(dutFam) $b.$r.P.$d.$ps.$np.$up  
    }
  }
#   if {[string match *.DRC.* $dutInitName]==1} {
#     foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
#       set gaSet(dutFam) $b.$r.$p.D.$ps.$np.$up  
#     }
#   }
  
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set PS noPS
  if {[string match *.WR.* $dutInitName]==1} {
    set PS WR
  } elseif {[string match *.ACDC* $dutInitName]==1} {
    set PS ACDC
  } elseif {[string match *DC* $dutInitName]==1 ||[string match *DR* $dutInitName]==1} {
    set PS DC
  } elseif {[string match *.AC* $dutInitName]==1} {
    set PS AC
  } elseif {[string match *.24VR* $dutInitName]==1} {
    set PS DC
  } elseif {[string match *19.NULL.* $dutInitName]==1} {
    set PS AC
  }  elseif {[string match *.AR.* $dutInitName]==1} {
    set PS AC
  }
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {
    set gaSet(dutFam) $b.$r.$p.$d.$PS.$np.$up  
  }
  
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  set gaSet(dutBox) $b
    
  puts "dutInitName:$dutInitName dutBox:$gaSet(dutBox) DutFam:$gaSet(dutFam)" ; update
}                               
# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save com} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf \"$cfTxt\" $save $com"
  #set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download File [file tail $cf]" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
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
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *EccXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt] || [string match *aAux* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        set ::reduceSpaces 0
        RLSerial::Send $com "$line\r" 
        set ::reduceSpaces 1
        ##RLCom::Send $com "$line\r" 
      } else {
        if {[string match *Aux* $cfTxt]} {
          set gaSet(prompt) 205A
        } else {
          set waitFor 2I
        }
        if {[string match {*conf system name*} $line]} {
          set gaSet(prompt) [lindex $line end]
        }
        if {[string match *CUST-LAB-ETX203PLA-1* $line]} {
          set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        }
        if {[string match *WallGarden_TYPE-5* $line]} {
          set gaSet(prompt) "WallGarden_TYPE-5"          
        }
        if {[string match *BOOTSTRAP-2I10G* $line]} {
          set gaSet(prompt) "BOOTSTRAP-2I10G"          
        }
        if {[string match *ETX-2i* $line]} {
          set gaSet(prompt) "ETX-2i"          
        }
        if {[string match *ZTP* $line]} {
          set gaSet(prompt) "ZTP"
        }
        if {[string match *2i10G-COV-* $line]} {
          set gaSet(prompt) "2i10G-COV-"
        }
        set ::reduceSpaces 0
        if {[string match {*login-message*} $line]} {
          Send $com $line\r stam 1
        } else {
          set ret [Send $com $line\r $gaSet(prompt) 60]
        }  
        set ::reduceSpaces 1
#         Send $com "$line\r"
#         set ret [MyWaitFor $com {205A 2I ztp} 0.25 60]
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "CLI Error"
          set ret -1
          break
        }
      }            
    }
  }
  close $id  
  if {$ret==0} {
    if {$com==$gaSet(comAux1) || $com==$gaSet(comAux2)} {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
    } else {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
#       Send $com "exit all\r" 
#       set ret [MyWaitFor $com {205A 2I ztp} 0.25 8]
    }
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 80]
      if {$ret=="-1"} {
        set ret [Send $com "admin save\r" "successfull" 80]
      }
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  puts "[MyTime] Pings to $dutIp" ; update
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac
# ***************************************************************************
proc GetMac {fi} {
  puts "[MyTime] GetMac $fi" ; update
  set macFile c:/tmp/mac[set fi].txt
  exec $::RadAppsPath/MACServer.exe 0 1 $macFile 1
  set ret [catch {open $macFile r} id]
  if {$ret!=0} {
    set gaSet(fail) "Open Mac File fail"
    return -1
  }
  set buffer [read $id]
  close $id
  file delete $macFile)
  set ret [regexp -all {ERROR} $buffer]
  if {$ret!=0} {
    set gaSet(fail) "MACServer ERROR"
    exec beep.exe
    return -1
  }
  return [lindex $buffer 0]
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# GetDbrSW
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui
  set gaSet(dbrSW) ""
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
  puts "GetDbrSW b:<$b>" ; update
  after 1000
  if ![info exists gaSet(swPack)] {
    set gaSet(swPack) ""
  }
  set swIndx [lsearch $b $gaSet(swPack)]  
  if {$swIndx<0} {
    set gaSet(fail) "There is no SW ID for $gaSet(swPack) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrSW Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrSW [string trim [lindex $b [expr {1+$swIndx}]]]
  puts dbrSW:<$dbrSW>
  set gaSet(dbrSW) $dbrSW
  
  set dbrBVerSwIndx [lsearch $b $gaSet(dbrBVerSw)]  
  if {$dbrBVerSwIndx<0} {
    set gaSet(fail) "There is no Boot SW ID for $gaSet(dbrBVerSw) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrSW Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrBVer [string trim [lindex $b [expr {1+$dbrBVerSwIndx}]]]
  puts dbrBVer:<$dbrBVer>
  set gaSet(dbrBVer) $dbrBVer
  
  pack forget $gaGui(frFailStatus)
  
  set swTxt [glob SW*_$barcode.txt]
  catch {file delete -force $swTxt}
  
  Status ""
  update
  BuildTests
  focus -force $gaGui(curTest)
  return 0
}
# ***************************************************************************
# GuiMuxMngIO
# ***************************************************************************
proc GuiMuxMngIO {mngMode syncEmode} {
  global gaSet descript
  set channel [RetriveUsbChannel]   
  RLEH::Open
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  MuxMngIO $mngMode $syncEmode
  RLUsbMmux::Close $gaSet(idMuxMngIO) 
  RLEH::Close
}
# ***************************************************************************
# MuxMngIO
##     MuxMngIO ioToGenMngToPc ioToGen
# ***************************************************************************
proc MuxMngIO {mngMode syncEmode} {
  global gaSet
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if [string match *UTP* $up] {
    
  }
  puts "MuxMngIO $mngMode $syncEmode"
  RLUsbMmux::AllNC $gaSet(idMuxMngIO)
  after 1000
  switch -exact -- $mngMode {
    ioToPc {
      if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,2,9,14
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,2,9,14     
      }
    }
    ioToGenMngToPc {
     if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,4,8,14
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,1,8,14      
      }
    }
    ioToGen {
      if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,4
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,1     
      }
    }
    mngToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 8,14
    }
    ioToCnt {
      if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 6,3
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 7,3     
      }
    }
    nc {
      ## do nothing, already disconected
    }
  }
  switch -exact -- $syncEmode {
    ioToGen {
      if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 15,21,24,27
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 15,21,22,28     
      }
    }
    ioToCnt {
      if [string match *UTP* $up] {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 16,21,24,23
      } else {
        RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 16,21,22,23     
      }
    }
    nc {
      ## do nothing, already disconected
    }
  }
}


# ***************************************************************************
# InitAux
# ***************************************************************************
proc InitAux {aux} {
  global gaSet
  set com $gaSet(com$aux)
  
  RLEH::Open
  set ret [RLSerial::Open $com 9600 n 8 1]
  ##set ret [RLCom::Open $com 9600 8 NONE 1]
  
  set ret [Login205 $aux]
  if {$ret!=0} {
    set ret [Login205 $aux]
    
  }
  set gaSet(fail) "Logon fail"
  
  if {$ret==0} {
    Send $com "exit all\r" stam 0.25 
    set cf $gaSet([set aux]CF) 
    set cfTxt "$aux"
    set ret [DownloadConfFile $cf $cfTxt 1 $com]    
  }  
  catch {RLSerial::Close $com}
  ##catch {RLCom::Close $com}
  RLEH::Close
  if {$ret==0} {
    Status "$aux is configured"  yellow
  } else {
    Status "Configuration of $aux failed" red
  }
  return $ret
} 
# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}
# ***************************************************************************
# LoadBootErrorsFile
# ***************************************************************************
proc LoadBootErrorsFile {} {
  global gaSet
  set gaSet(bootErrorsL) [list] 
  if ![file exists ./TeamLeaderFiles/bootErrors.txt]  {
    return {}
  }
  
  set id [open  ./TeamLeaderFiles/bootErrors.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(bootErrorsL) $line
      }
    }

  close $id
  
#   foreach ber $bootErrorsL {
#     if [string length $ber] {
#      lappend gaSet(bootErrorsL) $ber
#    }
#   }
  return {}
}
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  set path3 C:\\teraterm\\ttermpro.exe
  if [file exist $path1] {
    set path $path1
  } elseif [file exist $path2] {
    set path $path2  
  } elseif [file exist $path3] {
    set path $path3  
  } else {
    puts "no teraterm installed"
    return {}
  }
  if {[string match *Dut* $comName] || [string match *Dls* $comName] || [string match *Aux* $comName]} {
    set baud 9600
  } else {
    set baud 115200
  }
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val] 
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
}  
# *********

# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list AT-2IB10G-1-W10 AT-2I10G-2-W10 AT-2I10G-3-W10 AT-2I10G-4-W10 \
                   AT-2I10G-5-W10  AT-2I10G-6-W10 AT-2I10G-7-W10 AT-2I10G-8-W10 \
                   AT-2I10G-9-W10  AT-2I10G-10-W10 AT-2I10G-13-W10 AT-2I10G-14-W10 \
                   AT-2I10G-15-W10 AT-2i10G-16-W10 AT-2I10G-18-W10 AT-2I10G-19-W10 ]
  ## Philippines AT-2I10G-11-W10 AT-2I10G-12-W10  AT-2I10G-17-W10
  set initsPath AT-ETX-2i-10G/software/uutInits
  set usDefPath AT-ETX-2i-10G/ConfFiles/DEFAULT
  set teLeadPath AT-ETX-2i-10G/software/TeamLeaderFiles
  
  set s1 c:/$initsPath
  set s2 c:/$usDefPath
  set s3 c:/$teLeadPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      set dest //$host/c$/$usDefPath
      if [file exists $dest] {
        lappend sdl $s2 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      set dest //$host/c$/$teLeadPath
      if [file exists $dest] {
        lappend sdl $s3 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
    }
  }
  
  set msg ""
  if {$unUpdatedHostsL!=""} {
    set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL "file://R:\\IlyaG\\2i10G"
          if ![file exists R:/IlyaG/2i10G] {
            file mkdir R:/IlyaG/2i10G
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/2i10G } res
            puts $res
            catch {file copy -force $s2/$fi R:/IlyaG/2i10G } res
            puts $res
            catch {file copy -force $s3/$fi R:/IlyaG/2i10G } res
            puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}

# ***************************************************************************
# UpdateSourecScripts
# ***************************************************************************
proc UpdateSourceScripts {} {
  global gaSet
  puts "\n[MyTime]UpdateSourceScripts"
  if {$gaSet(radNet)==0} {return {}}
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G]
  set d1 [file normalize  C:/AT-ETX-2i-10G]
  set noCopyL [file join $d1 software uutInits]
  lappend noCopyL [file join $d1 software [info host]]
  lappend sdl $s1 $d1
  set ret [RLAutoUpdate::AutoUpdate $sdl -noCopyGlobL {init*.* *.db *.html skipped.txt} -noCopyL $noCopyL] 
    
  set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
  set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
  puts "uss updFileL:<$updFileL>"  
  puts "uss newestFileL:<$newestFileL>"  
 
  if {[lsearch $updFileL lib_PackSour.tcl] != "-1"} {
    set txt "Some Tester's files have been updated.\n\nThe GUI will automatically close and open"
    set ret [DialogBox -title "Restart the Tester" -icon images/info -type "OK" -message $txt]
    if {$ret=="OK"} {
      wm iconify . ; update
      after 2000 exit
      exec wish86.exe ${gaSet(pair)}-Tester.tcl &
      return {}
    }
  }
  foreach f $updFileL {
    if {[file extension $f] eq ".tcl"} {
      catch {source $f} res
      puts "\nsource $f .. res:<$res>"; update
    }
  }
  
  return $ret
}
# ***************************************************************************
# RetriveFansCheckJ
# ***************************************************************************
proc RetriveFansCheckJ {} {
  global buffer gaSet
  puts "RetriveFansCheckJ dutFam:$gaSet(dutFam) DutInitName:$gaSet(DutInitName)"
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
  if ![info exists buffer] {set buffer NA}

  foreach vv {A B D F G C E H I J checkJ} {set $vv na}
  if {($np=="8SFPP" && $up=="0_0" && [string match *B.8.5.* $gaSet(DutInitName)]) || \
       $b=="Half19B" || $b=="Half19"} {
    puts "if1"
    set fans 1
    set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F]
  } elseif {$b=="19B" && $np!="8SFPP" && $up!="0_0"} {
    puts "if2"
    set fans 2
    set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G]
  } elseif {$np=="8SFPP" && $up=="0_0"} {
    puts "if3.0"
    if {[string match *B.19.N.* $gaSet(DutInitName)]     || \
        [string match *B.19.H.* $gaSet(DutInitName)]     || \
        [string match *B_C.19.H.* $gaSet(DutInitName)]   || \
        [string match *B_ATT.H.* $gaSet(DutInitName)]    || \
        [string match *10G_ATT.H.* $gaSet(DutInitName)]  || \
        [string match *B.H.DCR* $gaSet(DutInitName)]     || \
        [string match *_C.19.H.* $gaSet(DutInitName)]    || \
        [string match *_C.H.DR.OD.* $gaSet(DutInitName)] || \
        [string match *.19.H.* $gaSet(DutInitName)] || \
        [string match *B.H.DC.OD* $gaSet(DutInitName)] || \
        [string match *B_BRSD.H.AR.OD* $gaSet(DutInitName)] || \
        [string match *10G_FTR.19.HN.DCR.8SFPP.K04N* $gaSet(DutInitName)]} {
      ## 26/05/2022 added *10G_ATT.H.*
      if {$np=="8SFPP" && $up=="0_0" && [regexp {ODU?\.8} $gaSet(DutInitName)]==1} {
        puts "if3.1.1"
        set fans 0
        set checkJ no
        foreach vv {D F G C E H I J fans checkJ} {
          set $vv NA
        }
        set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+} $buffer ma A B]
      } else {
        puts "if3.1"
        set fans 4
        set checkJ no
        set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G x1 J C E H I] 
      }
    } elseif {[string match *B_C.19.DR.* $gaSet(DutInitName)] || \
              [string match *B_ATT.19.* $gaSet(DutInitName)]  || \
              [string match *10G_ATT.19.* $gaSet(DutInitName)] || \
              [string match *_C.19.DR.* $gaSet(DutInitName)] || \
              [string match *_EIR.19.ACR.* $gaSet(DutInitName)] || \
              [string match *_EIR.19.DCR.* $gaSet(DutInitName)] || \
              [string match *_GC.19.ACR.4SFPP4SFP.* $gaSet(DutInitName)]} {
      ## 26/05/2022 added *10G_ATT.19.*
      puts "if3.2"
      set fans 2
      set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G]
    } elseif {[string match *B.19.* $gaSet(DutInitName)] || [string match *B_TWC.19.* $gaSet(DutInitName)]} {
      puts "if4"
      set fans 2
      set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G]
    } elseif {[regexp {10G\.19\.[AD]CR?\.8S?F?P?P}  $gaSet(DutInitName)]} {
      puts "if4.1"
      set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G]
      set fans 2
    }
  } elseif {$b=="19"} {
    puts "if5"
    set fans 4
    set checkJ yes
    set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G x1 J C E H I]    
  }
  if {$gaSet(DutInitName) == "ETX-2I-10G.19.H.ACDC.8SFPP.PTP.tcl"} {
    puts "if6.1" 
    set fans 4
    set checkJ yes
    set res [regexp {st\s+([\d\.\-]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([\d\.]+)\s+([\d\.]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+} $buffer ma A B D F G x1 J C E H I] 
  }
  puts "ST fans-$fans checkJ-$checkJ"
  if {$res==0} {
    set gaSet(fail) "Read ST fail"
    return -1
  }
  foreach vv {A B D F G C E H I J fans checkJ} {
    puts "ST fans-$fans $vv [set $vv]"
    AddToPairLog $gaSet(pair) "$vv [set $vv]"
    lappend lvv [set $vv]_
  }
  return $lvv
}

# ***************************************************************************
# PrepareDwnlJatPll
# ***************************************************************************
proc PrepareDwnlJatPll {} {
  global gaSet
  foreach {b r p d ps np up} [split $gaSet(dutFam) .] {}
#   if {[string match *8SFPP* $gaSet(DutInitName)] || [string match *.8P.* $gaSet(DutInitName)]} {
#     set b 8SFPP 
#   }
  if {$np=="8SFPP" && $up=="0_0"} {
    set b 8SFPP
  }  
  if {$b=="19"} {
    set SWCF c:/download/SW/JAT_PLL_PROG/sw-pack_2i_10g.bin
  } elseif {$b=="Half19"} {
    set SWCF c:/download/SW/JAT_PLL_PROG/sw-pack_2i_10g_lc.bin
  } elseif {$b=="19B" || $b=="Half19B"} {
    set SWCF c:/download/SW/JAT_PLL_PROG/sw-pack_2i_10g_lc_b.bin
  } elseif {$b=="8SFPP"} {
    set SWCF c:/download/SW/JAT_PLL_PROG/sw-pack_2i_10g_b_8sfpp.bin
  }
  puts "SetJatPllDownload b:$b SWCF:$SWCF"; update
  
  if {[file exists $SWCF]!=1} {
    set gaSet(fail) "The SW file $SWCF doesn't exist"
    return -1
  }
     
  # set tail [file tail $SWCF]
  set tail $gaSet(pair)_[file tail $SWCF]
  set rootTail [file rootname $tail]
  if [file exists c:/download/temp/$tail] {
    catch {file delete -force c:/download/temp/$tail}
    after 2000
    if [file exists c:/download/temp/$tail] {
      if [catch {file delete -force c:/download/temp/$tail} cres] {
        set gaSet(fail) "The SW file ($SWCF) can't be deleted"
        puts "[MyTime] PrepareDwnlJatPll. The file c:/download/temp/$tail ($gaSet(SWCF)) can't be deleted. cres:<$cres>"
        return -1
      }
    
    }
  }
    
  if [catch {file copy -force $SWCF c:/download/temp/$tail } res] {
    set tail $res
  }
  
  return $tail
}

# ***************************************************************************
# TestNewOption
# ***************************************************************************
proc TestNewOption {{opt ""}} {
  global gaSet
  if {$opt==""} {
    set opt $gaSet(DutFullName)
  }
  puts "TestNewOption $opt"
  set initName  [regsub -all / $opt .].tcl
  set gaSet(DutInitName) $initName
  set ret [RetriveDutFam $gaSet(DutInitName)]
  #puts "ret of RetriveDutFam: $ret"
  set ret [RetriveFansCheckJ]
  puts "ret of RetriveFansCheckJ: $ret"
  if {$ret!=0} {
    puts "gaSet(fail): $gaSet(fail)"
  }
  set ret [PrepareDwnlJatPll]
  puts "ret of PrepareDwnlJatPll: $ret"
  if {$ret!=0} {
    puts "gaSet(fail): $gaSet(fail)"
  }
}

# ***************************************************************************
# CheckAccWinprogAte
# ***************************************************************************
proc CheckAccWinprogAte {} {
  set w "w://winprog/ate"
  if [file exists $w] {
    set ti [time {set fid [file isdirectory $w]}]
    puts "w $ti" ; update
    foreach item [glob -nocomplain -directory $w *] {
      set ti [time {set iid [file isdirectory $w]}]
      puts "$item $ti" ; update
    }
  
  } else {
    puts "file exists $w = 0"
  }
}

# ***************************************************************************
# CheckTitleDbrNameVsUutDbrName
# ***************************************************************************
proc CheckTitleDbrNameVsUutDbrName {} {
  global gaSet
  set barcode $gaSet(1.barcode1) 
  set fileName MarkNam_$barcode.txt
  if [file exists $fileName] {
    file delete -force $fileName
    after 1000
  }
  set res [catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b]
  puts "CTDNVUDN barcode:<$barcode> res:<$res> b:<$b>"
  
  after 1000
  if ![file exists $fileName] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error -title "Get DbrName Problem"
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  catch {file delete -force $fileName}
  
  set uutDbrName "[string trim $res]"
  puts "CTDNVUDN uutDbrName:<$uutDbrName> gaSet(DutFullName):<$gaSet(DutFullName)>"
  if {$uutDbrName != $gaSet(DutFullName)} {
    set gaSet(fail) "Mismatch between UUT's Barcode and GUI" 
    AddToPairLog $gaSet(pair) "Mismatch between UUT's Barcode ($uutDbrName) and GUI ($gaSet(DutFullName))"
    return -1
  } else {
    return 0
  }
}
# ***************************************************************************
# DeleteOldTeFiles
# ***************************************************************************
proc DeleteOldTeFiles {} {
  foreach fi [glob -nocomplain c:/temp/te_*.txt] {
    file delete -force $fi
  }
}
# ***************************************************************************
# DeleteOldCaptConsFiles
# ***************************************************************************
proc DeleteOldCaptConsFiles {} {
  set daysAgo [clock add [clock seconds] -4 days]
  foreach fi [glob -nocomplain c:/temp/ConsoleCapt*.txt] {
    if {[file mtime $fi]<$daysAgo} {
      file delete -force $fi
    }  
  }
}

# ***************************************************************************
# TempHist
# ***************************************************************************
proc ThermoHist {} {
  set logs_path "c:/logs"
  set i 0
  set csv $logs_path/thermo_[clock format [clock seconds] -format "%Y.%m.%d_%H.%M.%S"].log
  set scv_id [open $csv w+]
  foreach log [lsort -decr [glob -directory $logs_path *.txt]] {
    foreach {date time barcode stat} [split $log -] {
      if {[string length $barcode] >= 11} {
        foreach {barc txt} [split $barcode .] {          
          set id [open $log r]
          set log_cont [read $id]
          close $id
          set A [set B [set uut [set lsr ""]]]
          if [regexp {..(ETX-[0-9A-Z\_\/\.\-]+)\s} $log_cont m uut] {
            set uut [string trim $uut]
          }
          if [regexp {..Laser Temperature \(Celsius\) : ([0-9\.]+)\sC\s} $log_cont m lsr] {
            set lsr [string trim $lsr]
          }
          if [regexp {..(A\s+([\d\.]+))\s} $log_cont m A AA] {
            set A [string trim $A]
          }
          if [regexp {..(B\s+([\d\.]+))\s} $log_cont m B BB] {
            set B [string trim $B]
          }
          if {$A!="" && $B!=""} {
            incr i
            set text [format "%-*s | %-*s | %-*s | %-*s | %-*s " 13 $barc 40 [file rootname [file tail $log]] 40 $uut 6 $A 6 $B]; update
            if {$lsr!=""} { 
              append text [format "| %-*s | %-*s " 14 "Eth 0/1 $lsr" 5 [format %.2f [expr {$AA - $lsr}]]]
            }
            puts $scv_id $text
          }
        }
        #if {$i>3} {return}
      }
    }  
  }
  close $scv_id
  after 200
  eval exec [auto_execok start] \"\" [list $csv]
  return $i
}
# ***************************************************************************
# AllATEsThermoHist
# ***************************************************************************
proc AllATEsThermoHist {mode} {
  global gaSet
  puts "\n[MyTime] AllATEsThermoHist $mode"
  if {[info exists gaSet(radNet)] && $gaSet(radNet)==1} {
    if {$mode=="OD"} {
      set hostsL [list AT-2I10G-13-W10 AT-2I10G-14-W10 \
                     AT-2I10G-15-W10 AT-2I10G-16-W10 AT-2I10G-18-W10]
    } elseif {$mode=="all"} {
      set hostsL [list AT-2IB10G-1-W10 AT-2I10G-2-W10 AT-2I10G-3-W10 AT-2I10G-4-W10 \
                     AT-2I10G-5-W10  AT-2I10G-6-W10 AT-2I10G-7-W10 AT-2I10G-8-W10 \
                     AT-2I10G-9-W10  AT-2I10G-10-W10 AT-2I10G-13-W10 AT-2I10G-14-W10 \
                     AT-2I10G-15-W10 AT-2I10G-16-W10  AT-2I10G-18-W10]
    } else {
      return {0}
    }
  } else {
    return {1}
  }
  
  set csv c:/logs/thermo_${mode}_[clock format [clock seconds] -format "%Y.%m.%d_%H.%M.%S"].log
  set scv_id [open $csv w+]
  
  foreach host $hostsL {
    if [file exists $host] {
      set ret [EachAteThermoHist $host $scv_id $mode]
      puts $ret
      if {$ret=="-1"} {
        puts $scv_id "$host is unreachable"
      }
    }
  }
  
  close $scv_id
  after 200
  eval exec [auto_execok start] \"\" [list $csv]
  Status "Done"
  return {2}
} 
# ***************************************************************************
# EachAteThermoHist
# ***************************************************************************
proc EachAteThermoHist {host scv_id mode} {
  Status "Read Thermo History from $host (\'$mode\')"
  #puts "EachAteThermoHist $host $scv_id $mode"
  set logs_path "//$host/c$/logs"
  if ![file exist $logs_path] {
    return -1
  }  
  set i 0
  puts $scv_id "\n\r $host"
  set firstLogTime [clock scan "2022-07-24 00:00:00"]
  set logs [lsort -decr [glob -directory $logs_path *.txt]]
  foreach log $logs {
    set ifMtime [expr {[file mtime $log]<$firstLogTime}]
    if {$ifMtime} {
      #puts "l1 <$log>" ; update
      continue
    }
    
    foreach {date time barcode stat} [split [file tail $log] -] {
      if {[string length $barcode] >= 11} {
        #puts "EachAteThermoHist $host $log"; update
          foreach {barc txt} [split $barcode .] {}
          set id [open $log r]
          set log_cont [read $id]
          close $id
          if {$mode=="OD" && [string match {*ETX*OD*} $log_cont] } {
            ## lets read this log
            #puts "l2 <$log>" ; update
          } elseif {$mode=="all"} {
            ## lets read this log
            #puts "l2 <$log>" ; update
          } else {
            #puts "l3 <$log>" ; update
            continue
          }
          
          set A [set B [set uut [set lsr ""]]]
          if [regexp {..(ETX-[0-9A-Z\_\/\.\-]+)\s} $log_cont m uut] {
            set uut [string trim $uut]
          }
          if [regexp {..Laser Temperature \(Celsius\) : ([0-9\.]+)\sC\s} $log_cont m lsr] {
            set lsr [string trim $lsr]
          }
          if [regexp {..(A\s+([\d\.]+))\s} $log_cont m A AA] {
            set A [string trim $A]
          }
          if [regexp {..(B\s+([\d\.]+))\s} $log_cont m B BB] {
            set B [string trim $B]
          }
          if {$A!="" && $B!=""} {
            incr i
            set text [format "%-*s | %-*s | %-*s | %-*s | %-*s " 13 $barc 40 [file rootname [file tail $log]] 40 $uut 6 $A 6 $B]; update
            if {$lsr!=""} { 
              append text [format "| %-*s | %-*s " 14 "Eth 0/1 $lsr" 5 [format %.2f [expr {$AA - $lsr}]]]
            }
            puts $scv_id $text
          }
        #{}
        #if {$i>3} {return}
      }
    }  
  }
  
  return $i
}

# ***************************************************************************
# LoadNoTraceFile
# ***************************************************************************
proc LoadNoTraceFile {} {
  global gaSet
  set gaSet(noTraceL) [list] 
  if ![file exists ./TeamLeaderFiles/NoTrace.txt]  {
    return {}
  }
  
  set id [open ./TeamLeaderFiles/NoTrace.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(noTraceL) $line
      }
    }

  close $id
}
# ***************************************************************************
# AddDbrNameToNoTraceFile
# ***************************************************************************
proc AddDbrNameToNoTraceFile {} {
  global gaSet
  set dbrName $gaSet(DutFullName)
  set id [open ./TeamLeaderFiles/NoTrace.txt a]
    puts $id $dbrName
  close $id
}
# ***************************************************************************
# ReadHistoryVersion
# ***************************************************************************
proc ReadHistoryVersion {mode} {
  global gaSet
  #puts "\n[MyTime] ReadHistoryVersion $mode"
  if {$mode=="local"} {
    set path [pwd]
  } else {
    set path //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G/software
  }
  #puts "ReadHistoryVersion $mode $path"
  set id [open $path/history.html r] 
  set hist [read $id]
  close $id 
  regsub -all -- {<[\w\=\#\d\s\"\/]+>} $hist "" a
  set aa [split $a "  \n\r"]
  set ver [string trim [lindex $aa [expr {1 + [lsearch [split $aa "  \n\r"] Changes]}]]]
  puts "ReadHistoryVersion $mode $path $ver"
  return $ver
}
# ***************************************************************************
# CompareHistoryVersions
# ***************************************************************************
proc CompareHistoryVersions {} {
  if {[ReadHistoryVersion local] == [ReadHistoryVersion tds]} {
    return 0
  } else {
    return -1
  }
}

# ***************************************************************************
# GetDbrSWAgain
# ***************************************************************************
proc GetDbrSWAgain {} {
  global gaSet

  set barcode $gaSet(1.barcode1)
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
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
  set ret 0
  return $ret
}

proc ianf {} {InformAboutNewFiles}
# ***************************************************************************
# InformAboutNewFiles
# ***************************************************************************
proc InformAboutNewFiles {} {
  global gaSet
  if {$gaSet(radNet)==0} {return {} }
  set path [file dirname [pwd]]
  set pathTail [file tail $path]
  set secNow [clock seconds]
  set ::newFilesL [list]
  puts "\n[MyTime] InformAboutNewFiles"
  CheckFolder4NewFiles $path $secNow
  puts "::newFilesL:<$::newFilesL>"
  
  if {[llength $::newFilesL]>0} {
    set msg "The following was changed during last hour:\n\n"
    foreach fi $::newFilesL {
      set ffi [format %-85s $fi]
      append msg "$fi\t[clock format [file mtime $fi] -format '%Y.%m.%d-%H.%M.%S']\n"
    }  
    #append msg "\nwas sent"
    append msg "\nAre you sure you want to upload it to TDS?"
    set res [DialogBox -message $msg -type {Yes No} -justify left -icon question -title "Tester update" -aspect 2000]
    #set res "Yes"
    if {$res=="Yes"} {
      if [string match *ilya-g-* [info host]] {
        set mlist {ilya_g@rad.com}
      } else {
        set mlist {ilya_g@rad.com yulia_s@rad.com} ; # 
      }
      set mess "The following was changed:\r\n"
      foreach {s} $::newFilesL {
        append mess "\r$s\n"
      }
      append mess "\rfile://R:\\IlyaG\\$pathTail\r"
      SendMail $mlist $mess
      if ![file exists R:/IlyaG/$pathTail] {
        file mkdir R:/IlyaG/$pathTail
      }
      #set msg "A message regarding\n\n"
      foreach fi $::newFilesL {
        catch {file copy -force $fi R:/IlyaG/$pathTail } res
        puts "file:<$fi>, res of copy:<$res>"
      }
      update
    }
  } else {
    set msg "No new files"
    DialogBox -message $msg -type Ok -icon info -title "Tester update" -aspect 2000
    puts "msg:<$msg>"
  }
  
}
# ***************************************************************************
# CheckFolder4NewFiles
# ***************************************************************************
proc CheckFolder4NewFiles {path secNow} {
  #puts "CheckFolder4NewFiles $path $secNow"
  foreach item [glob -nocomplain -directory $path *] {
    if [file isdirectory $item] {
      CheckFolder4NewFiles $item $secNow
    } else {
      set mtim  [file mtime $item]
      if {[expr {$secNow - $mtim}] < 1800} {
        ## if an file was modified during last half-hour, add it to list
        #puts "cf4nf $item" ; update
        if [string match {*init*.tcl} $item] {
          ## don take this file
        } else {
          set dirname [file dirname $item]
          if {[string match *ConfFiles* $dirname] ||\
              [string match *uutInits* $dirname] ||\
              [string match *TeamLeaderFiles* $dirname]} {
            lappend ::newFilesL $item
          }
        }
      }
    }
  }
}
# ***************************************************************************
# IsOptionReqsSerNum
# ***************************************************************************
proc IsOptionReqsSerNum {} {
  global gaSet gaGui
  set res 0
  puts "\nIsOptionReqsSerNum $gaSet(DutFullName)"
  
  set gaSet(insertSerNumOptsList) [list  ] ; #  07:31 08/08/2023 ETX-2I-10G_LY ETX-2I-10G-B_LY  #11:01 07/08/2023 ETX-2I-10G-B_VO/19/ACR/4SFPP/4S4U
  foreach opt $gaSet(insertSerNumOptsList)  {
    set res [string match *$opt* $gaSet(DutFullName)]
    puts "IsOptionReqsSerNum $opt $res"
    if $res break
  }
  puts "IsOptionReqsSerNum res:<$res>"
  if $res {
    set state normal
  } else {
    set  state disabled
  }
  $gaGui(enSerNum) configure -state $state
  update
  return $res
}

# ***************************************************************************
# LoadCleiCodesFile
# ***************************************************************************
proc LoadCleiCodesFile {} {
  global gaSet
  set gaSet(CleiCodesL) [list] 
  if ![file exists ./TeamLeaderFiles/CleiCodes.txt]  {
    return {}
  }
  
  set id [open  ./TeamLeaderFiles/CleiCodes.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        #lappend gaSet(CleiCodesL) $line
        set gaSet(CleiCodesL) [concat $gaSet(CleiCodesL) $line]
      }
    }
  close $id  
  return {}
}

## RetriveIdTraceData DF100148093 CSLByBarcode
## RetriveIdTraceData DF100148093 MKTItem4Barcode
## RetriveIdTraceData 21181408    PCBTraceabilityIDData
## RetriveIdTraceData TO300315253 OperationItem4Barcode
# ***************************************************************************
# RetriveIdTaceData
# ***************************************************************************
proc RetriveIdTraceData {args} {
  package require http
  package require tls
  package require base64
  ::http::register https 8445 ::tls::socket
  global gaSet
  set gaSet(fail) ""
  puts "RetriveIdTraceData $args"
  set barc [format %.11s [lindex $args 0]]
  
  set command [lindex $args 1]
  switch -exact -- $command {
    CSLByBarcode          {set barcode $barc  ; set traceabilityID null}
    PCBTraceabilityIDData {set barcode null   ; set traceabilityID $barc}
    MKTItem4Barcode       {set barcode $barc  ; set traceabilityID null}
    OperationItem4Barcode {set barcode $barc  ; set traceabilityID null}
    default {set gaSet(fail) "Wrong command: \'$command\'"; return -1}
  }
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param [set command]\?barcode=[set barcode]\&traceabilityID=[set traceabilityID]
  append url $param
  puts "url:<$url>"
  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set gaSet(fail) "http::status: <$st> http::ncode: <$nc>"; return -1
  }
  upvar #0 $tok state
  #parray state
  #puts "$state(body)"
  set body $state(body)
  ::http::cleanup $tok
  
  set re {[{}\[\]\,\t\:\"]}
  set tt [regsub -all $re $body " "]
  set ret [regsub -all {\s+}  $tt " "]
  
  return [lindex $ret end]
}

# ***************************************************************************
# GetPcbID
# ***************************************************************************
proc GetPcbID {board} {
  global gaSet gaGui
  set gaSet([set board]PcbId) "" ; update
  set barc $gaSet([set board]PcbIdBarc)
  set pcbName -1
  if {$barc==""} {
    # do nothing
  } else {
    set pcbName [RetriveIdTraceData $barc PCBTraceabilityIDData]
  }
  puts "GetPcbID board:<$board> barc:<$barc> pcbName:<$pcbName>" 
  if {$pcbName=="-1"} {
    return -1
  } else {
    set gaSet([set board]PcbId) $pcbName
    #set gaSet([set board]PcbIdBarc) ""
    if {$board=="main"} {
      focus -force $gaGui(entPCB_SUB_CARD_1_IDbarc) 
      $gaGui(entPCB_SUB_CARD_1_IDbarc) selection range 0 end
    }
    return 0
  }
}
