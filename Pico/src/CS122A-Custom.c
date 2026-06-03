#include <stdio.h>
#include "hardware/i2c.h"
#include "../header/maze.hpp"


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

enum randomize_button {r_start, r_off, r_release, r_on} rbuttonStates;

int gameState = 0;
int gameEnd = 1;

bool r_button() {
    switch (rbuttonStates) {
        case r_start:
            rbuttonStates = r_off;
            break;
        case r_off:
            if (!gpio_get(15) && !gameEnd) {
                rbuttonStates = r_release;
            }   
            break;
        case r_release:
            if (gpio_get(15))
                rbuttonStates = r_on;
            break;
        case r_on:
            rbuttonStates = r_off;
            break;
    }

    switch (rbuttonStates) {
        case r_on:
            initMaze();
            generateMaze(0, 0);
            create_border();
            gameState = 1;
            transmit_maze(gameState, 0);
            break;
    }
}

enum start_button {s_start, s_off, s_release, s_on} sbuttonStates;

bool s_button() {
    switch (sbuttonStates) {
        case s_start:
            sbuttonStates = s_off;
            break;
        case s_off:
            if (!gpio_get(14)) {
                sbuttonStates = s_release;
            }   
            break;
        case s_release:
            if (gpio_get(14))
                sbuttonStates = s_on;
            break;
        case s_on:
            sbuttonStates = s_off;
            break;
    }

    switch (sbuttonStates) {
        case s_on:
            gameState = 0;
            gameEnd = 0;
            transmit_maze(gameState, gameEnd);
            break;
    }
}

int main()
{
    srand(time(NULL));

    stdio_init_all();
    struct repeating_timer random_timer;
    struct repeating_timer start_timer;
    i2c_init(i2c0, 100 * 1000); // i2c_0

    gpio_set_function(20, GPIO_FUNC_I2C); // SDA
    gpio_set_function(21, GPIO_FUNC_I2C); // SCL
    gpio_pull_up(20);
    gpio_pull_up(21);

    spi_init(spi1, 100 * 1000);
    spi_set_format(spi1, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    gpio_set_function(11, GPIO_FUNC_SPI); //MOSI
    gpio_set_function(10, GPIO_FUNC_SPI); //SCK
    gpio_init(13); // CS1
    gpio_set_dir(13, 1);
    gpio_put(13, 1);
    gpio_set_function(12, GPIO_FUNC_SPI); // MISO

    mpu6050_reset();

    //randomize maze bt
    gpio_init(15);
    gpio_set_dir(15, 0);
    gpio_pull_up(15);

    //start | end bt
    gpio_init(14);
    gpio_set_dir(14, 0);
    gpio_pull_up(14);

    int16_t acceleration[3];
    add_repeating_timer_ms(-10, r_button, NULL, &random_timer);
    add_repeating_timer_ms(-10, s_button, NULL, &start_timer);

    while (true) {
        mpu6050_read_raw(acceleration);
        if (!gameEnd)
            gameLogic(acceleration, gameState, gameEnd);
        printf("Acc. X = %d, Y = %d, Z = %d\n", acceleration[0], acceleration[1], acceleration[2]);
        sleep_ms(100);
    }
}
