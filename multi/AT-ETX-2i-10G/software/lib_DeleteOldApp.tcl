# ***************************************************************************
# DeleteOldApp
# ***************************************************************************
proc DeleteOldApp {} {
  foreach fol [glob -nocomplain -type d c:/download/sw/*] {
    if {[string match -nocase {6.5.1(0.15)} [file tail $fol]]} {
      catch {file delete -force $fol}
    } 
  }
  foreach fol [glob -nocomplain -type d c:/download/sw/*] {
    if {[string match -nocase {6.5.1(0.24)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    } 
    if {[string match -nocase {6.4.0(0.49)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.5.1(1.41)_BYT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.4.0(0.60)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol/sw-pack_2i_10g.bin}
    }
    if {[string match -nocase {6.5.1(0.15)_CELL} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.6.1(0.23)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.32)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.3.1(0.46)_SFR} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.6.1(0.57)_CELL} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
   
  }
}

# ***************************************************************************
# DeleteOldUserDef
# ***************************************************************************
proc DeleteOldUserDef {} {
  foreach userDef [glob -nocomplain -type f C:/AT-ETX-2i-10G/ConfFiles/DEFAULT/*.txt] {
    puts "userDef:<$userDef>"
    if {[string match -nocase {User Default ETX2i10G_TA.TXT} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    } 
    if {[string match -nocase {ETX2i-10G_template.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {User_Default_ETX2i10G_4Uplink_12User_TA.TXT} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {User_Default_ETX2i10G_4Uplink_24User_TA.TXT} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {CELL_ETX2i-10G_template_Rev2.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {CELL_ETX2i-10G-28P-template_Rev2.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {CONNECT_SFR_BOOTSTRAP_2i10G_V1_Rev1.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
#     if {[string match -nocase {CELL_*.txt} [file tail $userDef]]} {
#       puts "delete [file tail $userDef]"
#       catch {file delete -force $userDef}
#     } 
    update
  }
}

