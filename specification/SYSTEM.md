# 周辺機器

## External Interrupt Cause (TVAL) Table

| cause  | details            |
| ------ | ------------------ |
| 0x0010 | RTC interrupt      |
| 0x0020 | keyboard interrupt |

## IO Address Table

| address | details                  |
| ------- | ------------------------ |
| 0x0000  | -                        |
| ...     |                          |
| 0x0020  | key input buffer counter |
| 0x0021  | keycode buffer           |
| ...     |                          |
| 0xFFFF  | -                        |

## RTC

RTC Register (0x0010)

RTC MSec Register   (0x0010)
RTC Sec Register    (0x0011)
RTC Min Register    (0x0012)
RTC Hour Register   (0x0013)
RTC Day Register    (0x0014)
RTC Mon Register    (0x0015)
RTC Year Register   (0x0016)

## KBC

KBC Register

Key Input Buffer Counter (0x0020)

| 15 - 0 |
| ------ |
| count  |

Keycode Buffer (0x0021)

| 15 - 0  |
| ------- |
| keycode |
