package main

import "core:fmt"
import "core:log"

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    log.info("Hello,", "world!")
}
