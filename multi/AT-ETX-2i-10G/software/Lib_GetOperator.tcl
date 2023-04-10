package require img::gif
package require img::jpeg
package require img::ico
# ***************************************************************************
# GetOperator
# ***************************************************************************
proc GetOperator {args} {
  global gaGetOpDBox
  set iIndx [lsearch $args "-i"]
  if {$iIndx=="-1"} {
    set icon images/oper32.ico
  } else {
    set icon [lindex $args [expr {$iIndx+1}]]
    if ![file exists $icon] {
      tk_messageBox -type ok -icon error -message "$icon doesn't exist"
      return -1
    }
  }
  set tiIndx [lsearch $args "-ti"]
  if {$tiIndx=="-1"} {
    set ti "Get Operator"
  } else {
    set ti [lindex $args [expr {$tiIndx+1}]]    
  }
  set teIndx [lsearch $args "-te"]
  if {$teIndx=="-1"} {
    set te "Operator's Name "
  } else {
    set te [lindex $args [expr {$teIndx+1}]]    
  }
  while 1 {
    RLSound::Play information
    set ret [GetOpDlg -title $ti -text $te -type "Ok Cancel" -icon $icon]     
    #puts "\n<$ret> was clicked\n" 
    if {$ret=="Cancel"} {
      return -1
    }
    set operator [string toupper $gaGetOpDBox(entVal1)]
    puts "entryValue:<$operator>"
    if {([string length $operator]<2) || \
        ([string length $operator]==12 && [string is alpha [string range $operator 0 1]]  && [string is digit [string range $operator 2 end]] ) || \
        ([string length $operator]==8 && [string is digit $operator])} {
      ## or too short or ID barcode or Traceability barcode
      ## try again    
    } else {
      return $operator
    }
  }
}
# ***************************************************************************
# GetOpDlg
# ***************************************************************************
proc GetOpDlg {args} {
  global gaGetOpDBox
  catch {array unset gaGetOpDBox}
  
  # each option & default value
  foreach {opt def} {title "DialogBox" text "" icon "" type ok \
                     parent . aspect 1150 default 0 entQty 1 entLab "" entPerRow 1\
                     linkText "" linkCmd "" justify center width "" message ""\
                     ent1focus 1 place center font TkDefaultFont DotEn 1 DashEn 1} {
    set var$opt [GetOpOpt $args "-$opt" $def]
  }
  
  set varaccpButIndx $vardefault
  if {$varentQty>0} {
    set vardefault [llength $vartype]
  }
  
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1 -place $varplace]
  if [winfo exists .tmpldlg] {
    wm deiconify .tmpldlg
    wm deiconify $varparent
    wm deiconify .tmpldlg
    return {}
  }

  #create icon 
  if {[string length $varicon]>0} {
    if {[string index $varicon end-3]=="."} {
      set micon $varicon
    } else {
      set micon $varicon.gif
    }
  }
  if {[catch {image create photo -file [pwd]/$micon} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }
  
  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    if {[lsearch $vartype $but]==$varaccpButIndx} {
      $dlg add -text $but -name $but -command [list GetOpEndDlg $dlg $but $varentQty $varDotEn $varDashEn]
    } else {
      $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
    }    
  }
  
  #create message
  ## supports -message for convertion from tk_messageBox to DialogBox 
  if {$varmessage!=""} {
    set vartext $varmessage
  }
  set msg [message [$dlg getframe].msg -text $vartext  \
     -anchor c -aspect $varaspect -justify left -font $varfont]
  pack $msg -anchor w -padx 3 -pady 3 ; #-fill both -expand 1
  
  if {$varentQty>0} {
    #-textvariable gaGetOpDBox(entVal$fi)
    #-vcmd {GetOpEntryValidCmd %P}  -validate all
    #set varentPerRow 2
    set fr [frame [$dlg getframe].fr -bd 0 -relief groove]
      for {set fi 1} {$fi<=$varentQty} {incr fi} {
        set f [frame $fr.f$fi -bd 0 -relief groove]
          set labText [lindex $varentLab [expr $fi-1]]
          set lab$fi [label $f.lab$fi  -text $labText]
          set ent$fi [entry $f.ent$fi] 
          
          ## user defined Entry width
          if {$varwidth!=""} {
            [set ent$fi] configure -width $varwidth
          }
          pack [set ent$fi] -padx 2 -side right -fill x -expand 1
          
          ## don't pack empty Label
          if {$labText!=""} {            
            pack [set lab$fi] -padx 2 -side right
          }
          
        #pack $f -padx 2 -pady 2  -anchor e -fill x -expand 1
        grid $f -padx 2 -pady 2 -row [expr {($fi-1) / $varentPerRow}] -column [expr {($fi-1) % $varentPerRow}]
        
        
        ## in case of 2 Entries pack them side-by-side
        if {$varentQty=="2"} {
          #pack configure $f -side left; # -fill x -expand 1
        }
        [set ent$fi] delete 0 end					         
      }
    pack $fr -padx 2 -pady 2 -fill both -expand 1 
    set taskL [exec tasklist.exe]
    if {[regexp -all wish* $taskL]!="1"} {
      if {$varent1focus==1} {
        focus -force $ent1
      }  
    } else {
      ##  if just one wish is existing - put the focus
      focus -force $ent1
    }
    
    ## binding for each Entries, except last
    for {set fi 1} {$fi<$varentQty} {incr fi} {
      bind [set ent$fi] <Return> [list GetOpReturnOnEntry [set ent$fi] $fi [list focus -force [set ent[expr {$fi+1}]] ] $varDotEn $varDashEn ]
    }
    ## binding for the last Entry
    bind [set ent$varentQty] <Return> [list GetOpReturnOnEntry [set ent$varentQty] $fi [list $dlg invoke $varaccpButIndx ] $varDotEn $varDashEn ]
  }
  
  #create "html" link
  if {$varlinkText!=""} {
    set ht [label [$dlg getframe].ht -text $varlinkText -fg blue -cursor hand2]
    set curFont [$ht cget -font]
    if {[llength $curFont]>1} {
      set newFont [linsert $curFont end underline]
    } else {
      set newFont {{MS Sans Serif} 8 underline}
    }
    $ht configure -font $newFont
    pack $ht -anchor w  -padx 6
    bind $ht <1> $varlinkCmd
  }
  
  set ret [$dlg draw]		
  destroy $dlg
  return $ret
}
#***************************************************************************
#** Opt
#***************************************************************************
proc GetOpOpt {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
}
# ***************************************************************************
# GetOpEndDlg
# ***************************************************************************
proc GetOpEndDlg {dlg but varentQty dotEn dashEn} {
  set res 1
  for {set fi 1} {$fi<=$varentQty} {incr fi} {
    set res [GetOpReturnOnEntry [$dlg getframe].fr.f$fi.ent$fi $fi [list return 1]  $dotEn $dashEn]
    #puts "fi:$fi res:$res"
    if {$res!="1"} {return}
  }    
  Dialog::enddialog $dlg $but
}
# ***************************************************************************
# GetOpReturnOnEntry
# ***************************************************************************
proc GetOpReturnOnEntry {e fi cmd dotEn dashEn} {
  global gaGetOpDBox
  set P [$e get]
  set res [GetOpEntryValidCmd $P $dotEn $dashEn]
  #puts "e:$e P:$P res:$res cmd:$cmd fi:$fi" ; update
  if {$res==1} {
    set gaGetOpDBox(entVal$fi) $P
    eval $cmd
  } else {
    $e selection range 0 end 
  }
}
# ***************************************************************************
# GetOpEntryValidCmd
# this proc must return 1 or 0
# ***************************************************************************
proc GetOpEntryValidCmd {P dotEn dashEn} {
  #puts "GetOpEntryValidCmd $P $dotEn $dashEn"
  set leng [string length $P]
	set rep [regexp -all { } $P]
	if {$dotEn=="1"} {
    set dot "OK"
    set P  [regsub -all {[\.]} $P ""]
  } elseif {$dotEn=="0"}  {
    if {[regexp {\.} $P]==0} {
      set dot "OK"
    } else {
      set dot "BAD"
    }
  }
  if {$dashEn=="1"} {
    set dash "OK"
    set P  [regsub -all {[\-]} $P ""]
  } elseif {$dashEn=="0"}  {
    if {[regexp {\-} $P]==0} {
      set dash "OK"
    } else {
      set dash "BAD"
    }
  }
  set num [string is alnum [regsub -all {[\s]} $P ""]]
  
  #puts "leng:<$leng> rep:<$rep> num:<$num> $dot $dash"
	if {($leng>0) && ($leng!=$rep) && ($num=="1") && ($dot=="OK") && ($dash=="OK")} {
	  return 1
  } else {
    return 0
  }
}



