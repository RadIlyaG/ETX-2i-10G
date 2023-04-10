BootDownload                                       lWidthTests1 (UUT-1 -> 2 -> .. -> n)
SetDownload                                        lWidthTests1 (UUT-1 -> 2 -> .. -> n)
Pages                                              lWidthTests1 (UUT-1 -> 2 -> .. -> n)
SoftwareDownload                                   lWidthTests1 (UUT-1 -> 2 -> .. -> n)
if {$b=="Half19" || $b=="Half19B" || $b=="19B"} {
  FanEepromBurn                                    lWidthTests1 (UUT-1 -> 2 -> .. -> n)
}                                                   
OpenLicense                                        lWidthTests1 (UUT-1 -> 2 -> .. -> n)

SetToDefault_Multi (no wait 20 sec on the finish)  lWidthTests1 (UUT-1 -> 2 -> .. -> n)
Leds_FAN_conf_Multi                                lWidthTests1 (UUT-1 -> 2 -> .. -> n)
Leds_FAN_Multi     (no disconnect all cables)      lTogetherTests1 (UUT-1 and 2 and .. and n)

SetToDefaultWD                                     lSerialTests1
ID                                                 lSerialTests1
UTP_ID                                             lSerialTests1
SFP_ID                                             lSerialTests1
DyingGasp_conf DyingGasp_run                       lSerialTests1
DataTransmission_conf DataTransmission_run         lSerialTests1
if {$p=="P"} {
 ExtClk SyncE_conf SyncE_run                       lSerialTests1
}
DDR                                                lSerialTests1
SetToDefault                                       lSerialTests1
X Leds_FAN_conf Leds_FAN

if {[string match *.12CMB.* $gaSet(DutInitName)]==1} {
 Combo_PagesSW ID Combo_SFP_ID Combo_UTP_ID        lSerialTests1
}
if {$np=="npo" || $np=="2SFPP"} {
 CloseLicense                                      lSerialTests1
} 
LoadDefaultConfiguration                           lSerialTests1


Leds_AllCablesOFF_Multi  (disconnect all cables)   lTogetherTests2 (UUT-1 and 2 and .. and n)
Mac_BarCode_Multi                                  lWidthTests2 (UUT-1 -> 2 -> .. -> n)