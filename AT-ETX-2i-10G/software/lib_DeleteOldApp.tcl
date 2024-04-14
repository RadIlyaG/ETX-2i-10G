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
    if {[string match -nocase {6.4.0(0.60)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.4.0(0.66)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.32)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.5.1(0.27)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(2.52)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.53)} [file tail $fol]]} {
      # 07:50 03/11/2022  catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.100)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.0(0.34)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(2.75)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.5.1(0.30)_LY} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    
    ## 07:36 21/03/2023
    # if {[string match -nocase {6.7.1(0.107)_FT} [file tail $fol]]} {
      # catch {file delete -force $fol}
    # }
    
    if {[string match -nocase {6.8.2(2.76)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.107)_FT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    
    #10:51 10/04/2023
    if {[string match -nocase {6.8.2(3.75)_8sfpp} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    
    ## 07:48 13/04/2023
    if {[string match -nocase {6.7.1(0.107)_TA} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    
    ## 07:29 16/04/2023
    if {[string match -nocase {6.5.1(0.30)_TA} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(1.43)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.32)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.35)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.21)_8SFPP_PTP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.20)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.0(0.32)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.0(0.9)_8SFPP} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.3.1(0.48)_SFR} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.7.1(0.70)_SFR} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2 (9.80)_MMC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(3.75)_ATT} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.55)} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.4.0(0.74)_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
    if {[string match -nocase {6.8.2(0.76)_8sfpp_TWC} [file tail $fol]]} {
      catch {file delete -force $fol}
    }
  }
}

# ***************************************************************************
# DeleteOldUserDef
# ***************************************************************************
proc DeleteOldUserDef {} {
  foreach userDef [glob -nocomplain -type f C:/AT-ETX-2i-10G/ConfFiles/DEFAULT/*.cfg] {
    puts "userDef:<$userDef>"
    if {[string match -nocase {FTR-etx_2i_10g_b_8sfpp_golden_EDIT.cfg} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    } 
    
  }
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
    if {[string match -nocase {OFK_User Default ETX2i10G_4Uplink_4User_rev1.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {today_RAD_EXT-2i-10G_ZTP_Config_v1.0.cfg.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {RAD_EXT-2i-10G_ZTP_Config_v1.0._Master.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {CONNECT_SFR_BOOTSTRAP_2i10G_V1_Rev2.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {ETX2i_8SFPP_UDC_FINAL_V2_rev2.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {ETX2i_8SFPP_UDC_FINAL_V3.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    if {[string match -nocase {LY_etx2i10G_ztp_minimal_Rev1.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    
    ##10:55 19/03/2023
    if {[string match -nocase {CONNECT_SFR_BOOTSTRAP_2i10G_V2_Rev3.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    
    
    
#     if {[string match -nocase {CELL_*.txt} [file tail $userDef]]} {
#       puts "delete [file tail $userDef]"
#       catch {file delete -force $userDef}
#     } 

    if {[string match -nocase {FTR-etx_2i_10g_b_8sfpp_golden_EDIT.txt} [file tail $userDef]]} {
      puts "delete [file tail $userDef]"
      catch {file delete -force $userDef}
    }
    update
  }
}

