###############################################
#硬件信息
#CPU必须指定
#FPU和FLOAT-ABI在没有时不指定
#指令集不指定时，默认为ARM指令集
#在不允许指令集相互调用时，将THUMB-INTERWORK注释掉
#注：硬件信息在编译和链接过程中，应当是通用的
###############################################
CPU = -mcpu=cortex-m0
FPU =
FLOAT_ABI =
INSTRUCTION_SET = -mthumb
THUMB_INTERWORK = -mthumb-interwork

#硬件信息
HARDWARE_OPTIONS = $(CPU) $(FPU) $(FLOAT_ABI) $(INSTRUCTION_SET) $(THUMB_INTERWORK)

###################################################
#编译参数
#语言标准指定为c11
#输出所有警告
#设置代码优化级别
#添加调试信息，DWARF格式，版本号2
#设置代码裁剪
#生成MAP文件
# -MMD:告诉编译器生成目标文件（.o文件）的同时，生成一个与之对应的依赖文件（.d文件）。依赖文件包含了目标文件所依赖的头文件信息
# -MP:告诉编译器为每个头文件生成一个伪目标规则。这样，即使某个头文件被删除了，make也不会因为找不到头文件而停止
# -MF:用于指定生成的依赖文件的名称
###################################################
C_STANDARD = -std=c11
#CXX-STANDARD = -std=c++11
WARNING = -Wall
OPTIMIZE = -Og
DEBUG = -g -gdwarf-2
FDATA_FFUNCTION = -fdata-sections -ffunction-sections
GEN_DEP_INF = -MMD -MP -MF"$(@:%.o=%.d)"

#编译选项(参数)
COMPILE_OPTIONS = $(C_STANDARD) $(WARNING) $(OPTIMIZE) $(DEBUG) $(FDATA_FFUNCTION) $(GEN_DEP_INF)

#头文件路径
#使用-I来添加头文件路径
C_INCLUDES_PATH = \
-ICMSIS/FM33LG0xx/Include \
-ICore_Libs/FM33LG0xx_FL_Driver/Inc \
-Iheader

#CFLAGS (硬件信息+编译选项+头文件搜索路径)
CFLAGS = $(HARDWARE_OPTIONS) $(COMPILE_OPTIONS) $(C_INCLUDES_PATH)

############################################################
#汇编参数
############################################################
# -Wa:表示将后续参数传递给汇编器进行处理
# -a:让汇编器生成汇编和源代码混合的文件
# -ad:让汇编器生成带有本地符号表的汇编代码文件
# -alms:指定生成带有扩展信息的汇编代码文件，并保存到指定路径
ASFLAGS = -a -ad -alms=

############################################################
#链接参数
############################################################
#外部库链接(链接工具链包中的可选库)
#使用-lx来选择,链接器会自动补全为 libx.a
LIB = -lc -lm -lnosys

#链接脚本文件
#使用-T来选择
LDSCRIPT = -TCMSIS/FM33LG0xx/fm33lg02x_flash.ld

#生成.map文件
MAP_DIR = $(EXECAUTABLE_DIR)
MAP = -Map=$(MAP_DIR)/$(TARGET).map

#输出交叉引用列表
CROSS_REFERENCE = --cref -Wl

LDFLAGS = $(HARDWARE_OPTIONS) -specs=nano.specs $(LDSCRIPT) $(LIB) -Wl,$(MAP),$(CROSS_REFERENCE),--gc-sections


#####################################################
#指定编译工具链
#####################################################
TOOLCHAIN_PATH = arm-gnu-toolchain-13.2.Rel1-x86_64-arm-none-eabi/bin
CC = $(TOOLCHAIN_PATH)/arm-none-eabi-gcc
CXX = $(TOOLCHAIN_PATH)/arm-none-eabi-g++
AS = $(TOOLCHAIN_PATH)/arm-none-eabi-as
CP = $(TOOLCHAIN_PATH)/arm-none-eabi-objcopy
SZ = $(TOOLCHAIN_PATH)/arm-none-eabi-size
LD = $(TOOLCHAIN_PATH)/arm-none-eabi-ld


#指定要编译的源文件
#用于获得中间文件(eg: .o .d)的文件名
CXX_SOURCE_FILES = \
source/main.c \
CMSIS/FM33LG0xx/Source/system_fm33lg0xx.c \
source/gpio.c \
Core_Libs/FM33LG0xx_FL_Driver/Src/fm33lg0xx_fl_gpio.c \
Core_Libs/FM33LG0xx_FL_Driver/Src/fm33lg0xx_fl.c


ASM_SOURCE_FILES = \
CMSIS/FM33LG0xx/startup_fm33lg0xx.s


#生成的可执行文件存放的目录
EXECAUTABLE_DIR = bin

#编译过程产生的文件存放目录
BUILD_DIR = build



#把(CXX_SOURCE_FILES)下的所有.c换成.o,去掉包含路径的部分，加上新的前缀(BUILD_DIR),定义给宏OBJECTS
#此时的OBJECTS 就是我们要的各个源文件对应的的 .o文件的文件名列表
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(CXX_SOURCE_FILES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCE_FILES:.s=.o)))


#使用vpath函数来指定源文件搜索目录
#注意，自定义的CXX_SOURCE_FILES的目的是为了生成OBJECTS，不是为编译器指定搜索目录
vpath %.c source: Core_Libs/FM33LG0xx_FL_Driver/Src: CMSIS/FM33LG0xx/Source
vpath %.s CMSIS/FM33LG0xx


################################################################################################################################3
#指定最后的可执行文件名
TARGET = fm33_main
#要生成elf bin hex三个文件
all:$(EXECAUTABLE_DIR)/$(TARGET).elf $(EXECAUTABLE_DIR)/$(TARGET).bin $(EXECAUTABLE_DIR)/$(TARGET).hex


#bin 和 hex 文件 通过elf文件生成
#也即bin和hex，依赖于elf文件
# -S选项，移除符号表和调试信息，从而减小文件大小
$(EXECAUTABLE_DIR)/%.hex: $(EXECAUTABLE_DIR)/%.elf
	$(CP) -O ihex $< $@

$(EXECAUTABLE_DIR)/%.bin: $(EXECAUTABLE_DIR)/%.elf
	$(CP) -O binary -S $< $@

#elf文件依赖于编译的所有.o文件 和 makefile
#通过gcc调用ld ,并将链接参数传递给ld，产生的文件输出到$@(当前规则的目标，也即EXECAUTABLE_DIR/TARGET.elf)
#命令行中输出$@文件的大小
$(EXECAUTABLE_DIR)/$(TARGET).elf: $(OBJECTS) Makefile | $(EXECAUTABLE_DIR)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@
	$(SZ) $@


#.o文件通过.c文件和汇编.s 文件生成
#使用编译器和汇编器 
# $< 表示当前规则下，第一个依赖
# 通过%.o : %.c的方式, 对每个.c文件生成.o文件
#
# -Wa:表示将后续参数传递给汇编器进行处理
# 因为.c文件经编译后，还需汇编才能得到.o文件
# -a:让汇编器生成汇编和源代码混合的文件
# -ad:让汇编器生成带有本地符号表的汇编代码文件
# -alms:指定生成带有扩展信息的汇编代码文件，并保存到指定路径
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) -c  $< -o $@


$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) $(ASFLAGS)$(BUILD_DIR)/$(notdir $(<:.s=.lst)) $< -o $@
	$(CC) -MMD -MP -MF"$(@:%.o=%.d)" -c $< -o $(@:%.o=%.d)




$(BUILD_DIR):
	mkdir $@
$(EXECAUTABLE_DIR):
	mkdir $@

clean:
	-rm -r $(BUILD_DIR)/*
	-rm -r $(EXECAUTABLE_DIR)/*















