wm iconify . ; update

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
set jav [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment" CurrentVersion]
set gaSet(javaLocation) [file normalize [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment\\$jav" JavaHome]/bin]


## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER 
}
after 1000
set gaSet(radNet) 0
foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
  if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
    set gaSet(radNet) 1
  }  
}
if 0 {
  
  if {$gaSet(radNet)} {
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
      after 2000
    }
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
      after 2000
    }
    update
  }
  
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G]
  set d1 [file normalize  C:/AT-ETX-2i-10G]
  set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/download]
  set d2 [file normalize  C:/download]
  
  if {$gaSet(radNet)} {
    #set emailL {{ronen_be@rad.com} {} {} }
    #set emailL {{ilya_g@rad.com} {} {} }
    set emailL [list]
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1 $s2 $d2" -noCheckFiles {init*.tcl skipped.txt} \
      -noCheckDirs {temp tmpFiles OLD old *wo*} -jarLocation C:/RadApps \
      -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      SQliteClose
      exit
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RL10GbGen; #RLEtxGen
package require RLUsbPio
package require RLUsbMmux
package require RLSound  
package require RLCom
RLSound::Open ; # [list failbeep fail.wav passbeep pass.wav beep warning.wav]
#package require RLScotty ; #RLTcp
package require ezsmtp
package require http
package require RLAutoUpdate
##package require registry
package require sqlite3

source Gui_Etx2i10G.tcl
source Main_Etx2i10G.tcl
source Lib_Put_Etx2i10G.tcl
source Lib_Gen_Etx2i10G.tcl
source Lib_Ds280e01_Etx2iB.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source Lib_FindConsole.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source Lib_Etx204_220.tcl
source lib_DeleteOldApp.tcl
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl

DeleteOldApp
DeleteOldUserDef
#source Lib_Tds340.tcl ;  ## done by ButRun according to gaSet(scopeModel)

#console show 

set gaSet(comDut) $gaSet(comMiniUsb)
if [file exists uutInits/$gaSet(DutInitName)] {
  source uutInits/$gaSet(DutInitName)
  if {[string match *.8SFPP.* $gaSet(DutInitName)]==1} {
    set gaSet(comDut) $gaSet(comMicroUsb)
  }
} else {
  source [lindex [glob uutInits/ETX*.tcl] 0]
}
source lib_SQlite.tcl

set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0

set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0
set gaSet(nextPair) begin
#set gaSet(1.barcode1) CE100025622

set gaSet(gpibMode) com
set gaSet(relDebMode) Release

set gaSet(maxMultiQty) 7
set gaSet(ReadOperator) 0

if ![info exists gaSet(chBAH)] {
  set gaSet(chBAH) 1
}

GUI
BuildTests
update

wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"
#set ret [SQliteOpen]
