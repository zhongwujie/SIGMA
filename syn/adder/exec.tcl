## 设置目标库和链接库路径
set target_library /hpc/home/connect.wzhong679/code/Tools/freepdk-45nm/stdcells.db
set link_library /hpc/home/connect.wzhong679/code/Tools/freepdk-45nm/stdcells.db

## 设置多线程选项
set_host_options -max_cores 6

## 读取 RTL 文件
read_file -format verilog {../../vmod/adder_switch.v
  ../../vmod/reduction_mux.v
 } -autoread -top adder_switch

## 设置时钟, 200 Mhz
create_clock -period 5 [get_port clk]

## 综合
compile

## 生成面积报告
report_area -hierarchy > area.area_rpt

## 生成约束报告
report_constraint -all_violators > cons.constraint_rpt

## 生成时序报告
report_timing > timing.timing_rpt