# Create clk_wiz
cell xilinx.com:ip:clk_wiz:5.3 pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 125.0
  CLKOUT2_USED true
  CLKOUT2_REQUESTED_OUT_FREQ 250.0
  CLKOUT2_REQUESTED_PHASE -90.0
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7:5.5 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0 {} {
  ext_reset_in const_0/dout
}

# ADC

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc:2.0 adc_0 {} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# DAC

# Create axis_red_pitaya_dac
cell pavel-demin:user:axis_red_pitaya_dac:1.0 dac_0 {} {
  aclk pll_0/clk_out1
  ddr_clk pll_0/clk_out2
  locked pll_0/locked
  dac_clk dac_clk_o
  dac_rst dac_rst_o
  dac_sel dac_sel_o
  dac_wrt dac_wrt_o
  dac_dat dac_dat_o
}

# CFG

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 cfg_0 {
  CFG_DATA_WIDTH 64
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 64 DIN_FROM 0 DIN_TO 0 DOUT_WIDTH 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 64 DIN_FROM 1 DIN_TO 1 DOUT_WIDTH 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_2 {
  DIN_WIDTH 64 DIN_FROM 2 DIN_TO 2 DOUT_WIDTH 1
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_3 {
  DIN_WIDTH 64 DIN_FROM 31 DIN_TO 16 DOUT_WIDTH 16
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_4 {
  DIN_WIDTH 64 DIN_FROM 63 DIN_TO 32 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# DDS

# Create axi_axis_writer
cell pavel-demin:user:axi_axis_writer:1.0 writer_0 {
  AXI_DATA_WIDTH 32
} {
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create axis_data_fifo
cell xilinx.com:ip:axis_data_fifo:1.1 fifo_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
  FIFO_DEPTH 32768
} {
  S_AXIS writer_0/M_AXIS
  s_axis_aclk pll_0/clk_out1
  s_axis_aresetn slice_1/Dout
}

# Create axis_interpolator
cell pavel-demin:user:axis_interpolator:1.0 inter_0 {
  AXIS_TDATA_WIDTH 32
  CNTR_WIDTH 32
} {
  S_AXIS fifo_0/M_AXIS
  cfg_data slice_4/Dout
  aclk pll_0/clk_out1
  aresetn slice_1/Dout
}

# Create dds_compiler
cell xilinx.com:ip:dds_compiler:6.0 dds_0 {
  DDS_CLOCK_RATE 125
  SPURIOUS_FREE_DYNAMIC_RANGE 138
  FREQUENCY_RESOLUTION 0.2
  PHASE_INCREMENT Streaming
  HAS_TREADY true
  HAS_ARESETN true
  HAS_PHASE_OUT false
  PHASE_WIDTH 30
  OUTPUT_WIDTH 24
  DSP48_USE Minimal
  NEGATIVE_SINE true
} {
  S_AXIS_PHASE inter_0/M_AXIS
  m_axis_data_tready const_0/dout
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# RX

for {set i 0} {$i <= 3} {incr i} {

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 adc_slice_$i {
    DIN_WIDTH 32 DIN_FROM [expr 16 * ($i / 2) + 13] DIN_TO [expr 16 * ($i / 2)] DOUT_WIDTH 14
  } {
    Din adc_0/m_axis_tdata
  }

}

for {set i 0} {$i <= 1} {incr i} {

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 dds_slice_$i {
    DIN_WIDTH 48 DIN_FROM [expr 24 * $i + 23] DIN_TO [expr 24 * $i] DOUT_WIDTH 24
  } {
    Din dds_0/m_axis_data_tdata
  }

}

# TX

# Create axis_lfsr
cell pavel-demin:user:axis_lfsr:1.0 lfsr_0 {} {
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# Create xbip_dsp48_macro
cell xilinx.com:ip:xbip_dsp48_macro:3.0 mult_6 {
  INSTRUCTION1 RNDSIMPLE(A*B+CARRYIN)
  A_WIDTH.VALUE_SRC USER
  B_WIDTH.VALUE_SRC USER
  OUTPUT_PROPERTIES User_Defined
  A_WIDTH 24
  B_WIDTH 16
  P_WIDTH 15
} {
  A dds_slice_1/Dout
  B slice_3/Dout
  CARRYIN lfsr_0/m_axis_tdata
  CLK pll_0/clk_out1
}

# Create c_shift_ram
cell xilinx.com:ip:c_shift_ram:12.0 delay_0 {
  WIDTH.VALUE_SRC USER
  WIDTH 1
  DEPTH 4
} {
  D dds_0/m_axis_data_tvalid
  CLK pll_0/clk_out1
}

# Create axis_zeroer
cell pavel-demin:user:axis_zeroer:1.0 zeroer_0 {
  AXIS_TDATA_WIDTH 16
} {
  s_axis_tdata mult_6/P
  s_axis_tvalid delay_0/Q
  M_AXIS dac_0/S_AXIS
  aclk pll_0/clk_out1
}

for {set i 0} {$i <= 1} {incr i} {

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 adc_slice_[expr $i + 4] {
    DIN_WIDTH 16 DIN_FROM 13 DIN_TO 0 DOUT_WIDTH 14
  } {
    Din mult_6/P
  }

}

for {set i 0} {$i <= 5} {incr i} {

  # Create xbip_dsp48_macro
  cell xilinx.com:ip:xbip_dsp48_macro:3.0 mult_$i {
    INSTRUCTION1 RNDSIMPLE(A*B+CARRYIN)
    A_WIDTH.VALUE_SRC USER
    B_WIDTH.VALUE_SRC USER
    OUTPUT_PROPERTIES User_Defined
    A_WIDTH 24
    B_WIDTH 14
    P_WIDTH 25
  } {
    A dds_slice_[expr $i % 2]/Dout
    B adc_slice_$i/Dout
    CARRYIN lfsr_0/m_axis_tdata
    CLK pll_0/clk_out1
  }

  # Create cic_compiler
  cell xilinx.com:ip:cic_compiler:4.0 cic_$i {
    INPUT_DATA_WIDTH.VALUE_SRC USER
    FILTER_TYPE Decimation
    NUMBER_OF_STAGES 6
    SAMPLE_RATE_CHANGES Fixed
    FIXED_OR_INITIAL_RATE 2500
    INPUT_SAMPLE_FREQUENCY 125
    CLOCK_FREQUENCY 125
    INPUT_DATA_WIDTH 24
    QUANTIZATION Truncation
    OUTPUT_DATA_WIDTH 24
    USE_XTREME_DSP_SLICE false
    HAS_DOUT_TREADY true
    HAS_ARESETN true
  } {
    s_axis_data_tdata mult_$i/P
    s_axis_data_tvalid const_0/dout
    aclk pll_0/clk_out1
    aresetn slice_0/Dout
  }

}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 3
  NUM_SI 6
} {
  S00_AXIS cic_5/M_AXIS_DATA
  S01_AXIS cic_4/M_AXIS_DATA
  S02_AXIS cic_3/M_AXIS_DATA
  S03_AXIS cic_2/M_AXIS_DATA
  S04_AXIS cic_1/M_AXIS_DATA
  S05_AXIS cic_0/M_AXIS_DATA
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 18
  M_TDATA_NUM_BYTES 3
} {
  S_AXIS comb_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# Create floating_point
cell xilinx.com:ip:floating_point:7.1 fp_0 {
  OPERATION_TYPE Fixed_to_float
  A_PRECISION_TYPE.VALUE_SRC USER
  C_A_EXPONENT_WIDTH.VALUE_SRC USER
  C_A_FRACTION_WIDTH.VALUE_SRC USER
  A_PRECISION_TYPE Custom
  C_A_EXPONENT_WIDTH 2
  C_A_FRACTION_WIDTH 22
  RESULT_PRECISION_TYPE Single
  HAS_ARESETN true
} {
  S_AXIS_A conv_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 24
} {
  S_AXIS fp_0/M_AXIS_RESULT
  aclk pll_0/clk_out1
  aresetn slice_0/Dout
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator:13.1 fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 256
  INPUT_DEPTH 256
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 2048
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 12
} {
  clk pll_0/clk_out1
  srst slice_2/Dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo:1.0 fifo_1 {
  S_AXIS_TDATA_WIDTH 256
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS conv_1/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk pll_0/clk_out1
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader:1.0 reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_1/M_AXIS
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# STS

# Create dna_reader
cell pavel-demin:user:dna_reader:1.0 dna_0 {} {
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_0 {
  NUM_PORTS 5
  IN0_WIDTH 32
  IN1_WIDTH 64
  IN2_WIDTH 16
} {
  In0 const_0/dout
  In1 dna_0/dna_data
  In2 fifo_generator_0/rd_data_count
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register:1.0 sts_0 {
  STS_DATA_WIDTH 128
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data concat_0/dout
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sts_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins reader_0/S_AXI]

set_property RANGE 8K [get_bd_addr_segs ps_0/Data/SEG_reader_0_reg0]
set_property OFFSET 0x40002000 [get_bd_addr_segs ps_0/Data/SEG_reader_0_reg0]

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins writer_0/S_AXI]

set_property RANGE 128K [get_bd_addr_segs ps_0/Data/SEG_writer_0_reg0]
set_property OFFSET 0x40020000 [get_bd_addr_segs ps_0/Data/SEG_writer_0_reg0]
