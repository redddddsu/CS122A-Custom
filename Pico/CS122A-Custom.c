#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/i2c.h"

static int addr = 0x68;

static void mpu6050_reset() {
    uint8_t buf[] = {0x6B, 0x80};
    i2c_write_blocking(i2c0, addr, buf, 2, false);
    sleep_ms(100);

    buf[1] = 0x00;  
    i2c_write_blocking(i2c0, addr, buf, 2, false); 
    sleep_ms(10); 
}

static void mpu6050_read_raw(int16_t accel[3]) {
    uint8_t buffer[6];
    uint8_t val = 0x3B;
    i2c_write_blocking(i2c0, addr, &val, 1, true); 
    i2c_read_blocking(i2c0, addr, buffer, 6, false);

    for (int i = 0; i < 3; i++) {
        accel[i] = (buffer[i * 2] << 8 | buffer[(i * 2) + 1]);
    }
}

long map(long x, long in_min, long in_max, long out_min, long out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

int main()
{
    stdio_init_all();
    i2c_init(i2c0, 100 * 1000); // i2c_0

    gpio_set_function(20, GPIO_FUNC_I2C); // SDA
    gpio_set_function(21, GPIO_FUNC_I2C); // SCL
    gpio_pull_up(20);
    gpio_pull_up(21);

    mpu6050_reset();

    int16_t acceleration[3];

    while (true) {
        mpu6050_read_raw(acceleration);
        printf("Acc. X = %d, Y = %d, Z = %d\n", acceleration[0], acceleration[1], acceleration[2]);
        sleep_ms(1000);
    }
}
