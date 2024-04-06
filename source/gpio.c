#include "gpio.h"
#include "fm33lg0xx_fl.h"
#include "fm33lg0xx_fl_def.h"
#include "fm33lg0xx_fl_gpio.h"
#include "fm33lg0xx_fl_conf.h"

void ClockInit() {
    /* Initial RCHF */
    FL_CMU_RCHF_SetFrequency(FL_CMU_RCHF_FREQUENCY_8MHZ);                               /*配置RCHF频率*/
    FL_CMU_RCHF_Enable();                                                               /*使能RCHF*/

    /* Initial System Clock */
    FL_FLASH_SetReadWait(FLASH, FL_FLASH_READ_WAIT_0CYCLE);                             /*配置FLASH等待周期*/
    FL_CMU_SetSystemClockSource(FL_CMU_SYSTEM_CLK_SOURCE_RCHF);                         /*配置系统时钟*/
    FL_CMU_SetAHBPrescaler(FL_CMU_AHBCLK_PSC_DIV1);                                     /*配置AHB时钟*/
    FL_CMU_SetAPBPrescaler(FL_CMU_APBCLK_PSC_DIV1);                                     /*配置APB时钟*/

    SystemCoreClockUpdate();                                                            /*系统时钟更新*/

}

void GPIOInit() {
    FL_GPIO_InitTypeDef GPIOInitStruct;
    GPIOInitStruct.mode = FL_GPIO_MODE_OUTPUT;
    GPIOInitStruct.outputType = FL_GPIO_OUTPUT_PUSHPULL;
    GPIOInitStruct.pull = FL_ENABLE;
    GPIOInitStruct.analogSwitch = FL_DISABLE;
    GPIOInitStruct.remapPin = FL_DISABLE;
    GPIOInitStruct.pin = FL_GPIO_PIN_4;
    FL_GPIO_Init(GPIOA, &GPIOInitStruct);
}

void LEDToggle() {
    FL_Init();
    FL_GPIO_ToggleOutputPin(GPIOA, FL_GPIO_PIN_4);
    FL_DelayMs(500);
}