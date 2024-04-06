#include "gpio.h"
#include "fm33lg0xx_fl.h"

int main() {
    ClockInit();
    GPIOInit();

    while (1) {
        LEDToggle();
    }
    return 0;
}
