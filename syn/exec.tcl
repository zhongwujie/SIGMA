## 设置目标库和链接库路径
set target_library /hpc/home/connect.wzhong679/code/Tools/freepdk-45nm/stdcells.db
set link_library /hpc/home/connect.wzhong679/code/Tools/freepdk-45nm/stdcells.db

## 设置多线程选项
set_host_options -max_cores 6

## 读取 RTL 文件
read_file -format verilog { ../vmod/flexdpe.v
  ../vmod/xbar.v
  ../vmod/benes.v
  ../vmod/mult_gen.v 
  ../vmod/mult_switch.v
  ../vmod/adder_switch.v 
  ../vmod/edge_adder_switch.v
  ../vmod/reduction_mux.v
  ../vmod/fan_network.v 
  ../vmod/fan_ctrl.v
} -autoread -top flexdpe

## 设置时钟, 200 Mhz
create_clock -period 5 [get_port clk]

## 综合
compile

## 生成面积报告
report_area -hierarchy > ./output/area.area_rpt

## 生成约束报告
report_constraint -all_violators > ./output/cons.constraint_rpt

## 生成时序报告
report_timing > ./output/timing.timing_rpt