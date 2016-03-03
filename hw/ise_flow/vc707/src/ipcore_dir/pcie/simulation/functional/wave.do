onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {End Point} -expand -group {System Interface} /board/EP/sys_rst_n
add wave -noupdate -expand -group {End Point} -expand -group {System Interface} /board/EP/sys_clk_p
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/user_clk
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/user_reset
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/user_lnk_up
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_sel
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_cpld
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_cplh
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_npd
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_nph
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_pd
add wave -noupdate -expand -group {End Point} -expand -group {AXI Common} /board/EP/fc_ph
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/m_axis_rx_tdata
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/m_axis_rx_tready
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/m_axis_rx_tvalid
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/m_axis_rx_tlast
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/m_axis_rx_tuser
add wave -noupdate -expand -group {End Point} -expand -group {AXI Rx} /board/EP/rx_np_ok
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/s_axis_tx_tdata
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/s_axis_tx_tready
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/s_axis_tx_tvalid
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/s_axis_tx_tlast
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/s_axis_tx_tuser
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/tx_buf_av
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/tx_err_drop
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/tx_cfg_req
add wave -noupdate -expand -group {End Point} -expand -group {AXI Tx} /board/EP/tx_cfg_gnt
add wave -noupdate -group {Root Port} -group {System Interface} /board/RP/sys_clk
add wave -noupdate -group {Root Port} -group {System Interface} /board/RP/sys_rst_n
add wave -noupdate -group {Root Port} -group {AXI Rx} /board/RP/m_axis_rx_tdata
add wave -noupdate -group {Root Port} -group {AXI Rx} /board/RP/m_axis_rx_tvalid
add wave -noupdate -group {Root Port} -group {AXI Rx} /board/RP/m_axis_rx_tlast
add wave -noupdate -group {Root Port} -group {AXI Rx} /board/RP/m_axis_rx_tuser
add wave -noupdate -group {Root Port} -group {AXI Tx} /board/RP/s_axis_tx_tdata
add wave -noupdate -group {Root Port} -group {AXI Tx} /board/RP/s_axis_tx_tready
add wave -noupdate -group {Root Port} -group {AXI Tx} /board/RP/s_axis_tx_tvalid
add wave -noupdate -group {Root Port} -group {AXI Tx} /board/RP/s_axis_tx_tlast
add wave -noupdate -group {Root Port} -group {AXI Tx} /board/RP/s_axis_tx_tuser
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 215
update
