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
  if {$fi=="bootErrors.txt" || $fi=="sfpList.txt" || $fi=="NoTrace.txt"} {
    file delete -force $fi
  }  
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER 
}

source lib_DeleteOldApp.tcl
DeleteOldApp
DeleteOldUserDef

after 1000 
set ::RadAppsPath c:/RadApps
if 1 {
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip] || [string match {*172.17.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
}
if 1 {
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
  
  proc TesterAutoSync {} {
    global gaSet gMessage
  
    set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G]
    set d1 [file normalize  C:/AT-ETX-2i-10G]
    set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/download]
    set d2 [file normalize  C:/download]
    
    if {$gaSet(radNet)} {
      if {[string match *david-ya* [info host]] || [string match *ilya-g* [info host]]} {
        set emailL [list]
      } else {
        set emailL {{yulia_s@rad.com ronen_be@rad.com} {} {} }
      }  
    } else {
      set emailL [list]
    }
    
    # java.exe -jar c:/RadApps/AutoSyncApp.jar "//prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G C:/AT-ETX-2i-10G //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/download C:/download" "-noCheckFiles{init*.tcl skipped.txt *.db}" "-noCheckDirs{temp tmpFiles OLD old}"
    # Measure-Command {$foo = java.exe -jar c:/RadApps/AutoSyncApp.jar "//prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/AT-ETX-2i-10G C:/AT-ETX-2i-10G //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/ETX-2i-10G/download C:/download" "-noCheckFiles{init*.tcl skipped.txt *.db}" "-noCheckDirs{temp tmpFiles OLD old}"} ; $foo 
    
    set ret [RLAutoSync::AutoSync "$s1 $d1 $s2 $d2" -noCheckFiles {init*.tcl skipped.txt *.db} \
        -noCheckDirs {temp tmpFiles OLD old} -jarLocation $::RadAppsPath \
        -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    set rt $ret
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    
    
    if {$ret=="-1"} {
      if [string match *Exception* $gMessage] {
        set txt "Network connection problem"
        set res [tk_messageBox -icon error -type ok -title "AutoSync Network problem"\
          -message "Network connection problem"]
      } else {
        set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
          -message "The AutoSync process did not perform successfully.\n\n\
          Do you want to continue? "]
        if {$res=="no"} {
          #SQliteClose
          exit
        } else {
          set ret 0
        }
      }
    } 
    return $ret
  }
  
  set ret [TesterAutoSync]
  
  if {$gaSet(radNet)} {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Macreg.2* Macreg-i* DP* *.prd}]
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
        #SQliteClose
        exit
      }
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
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl
source Lib_GetSerNum.tcl

source lib_DeleteOldApp.tcl
DeleteOldApp
DeleteOldUserDef
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
  if {$fi=="bootErrors.txt" || $fi=="sfpList.txt" || $fi=="NoTrace.txt"} {
    file delete -force $fi
  }  
}
#source Lib_Tds340.tcl ;  ## done by ButRun according to gaSet(scopeModel)

#console show 

if [file exists uutInits/$gaSet(DutInitName)] {
  source uutInits/$gaSet(DutInitName)
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
#set gaSet(1.barcode1) CE100025622

set gaSet(gpibMode) com
set gaSet(relDebMode) Release

if ![info exists gaSet(enSerNum)] {
  set gaSet(enSerNum) 0
}
if {![info exists gaSet(rbTestMode)]} {
  set gaSet(rbTestMode) "Full"
}
set gaSet(eraseTitle) 0
if {![info exists gaSet(enVneNum)]} {
  set gaSet(enVneNum) 0
}
set gaSet(1.useTraceId) 1

set gaSet(cleiCodeMode) 0

set gaSet(insertSerNumOptsList) [list ETX-2I-10G_LY ETX-2I-10G-B_LY ETX-2I-10G-B_VO/19/ACR/4SFPP/4S4U]
  
DeleteOldTeFiles
DeleteOldCaptConsFiles

GUI
BuildTests
update

wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"
#set ret [SQliteOpen]
ToggleTestMode
InformAboutNewFiles