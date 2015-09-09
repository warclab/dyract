#Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
	set Page0 [ ipgui::add_page $IPINST  -name "Page 0" -layout vertical]
	set Component_Name [ ipgui::add_param  $IPINST  -parent  $Page0  -name Component_Name ]
	set RECONFIG_ENABLE [ipgui::add_param $IPINST -parent $Page0 -name RECONFIG_ENABLE]
}

proc update_PARAM_VALUE.RECONFIG_ENABLE { PARAM_VALUE.RECONFIG_ENABLE } {
	# Procedure called to update RECONFIG_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RECONFIG_ENABLE { PARAM_VALUE.RECONFIG_ENABLE } {
	# Procedure called to validate RECONFIG_ENABLE
	return true
}


proc update_MODELPARAM_VALUE.RECONFIG_ENABLE { MODELPARAM_VALUE.RECONFIG_ENABLE PARAM_VALUE.RECONFIG_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RECONFIG_ENABLE}] ${MODELPARAM_VALUE.RECONFIG_ENABLE}
}

