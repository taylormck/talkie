package main

import "core:log"
import sdl "vendor:sdl3"

device: ^sdl.GPUDevice
window: ^sdl.Window

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    init()
    defer teardown()

    update_loop()
}

init :: proc() -> bool {
    if !sdl.Init({.VIDEO}) {
        log.errorf("unable to initialize sdl, error {}", sdl.GetError())
        return false
    }

    device = sdl.CreateGPUDevice({.SPIRV, .DXIL, .MSL}, false, nil)
    if device == nil {
        log.errorf("unable to initialize gpu device, error {}", sdl.GetError())
        return false
    }

    window = sdl.CreateWindow("Talkie", 640, 480, {.RESIZABLE})
    if window == nil {
        log.errorf("unable to intitialize window, error: {}", sdl.GetError())
        return false
    }

    if !sdl.ClaimWindowForGPUDevice(device, window) {
        log.errorf(
            "unable to claim window for gpu device, error: {}",
            sdl.GetError(),
        )
        return false
    }

    return true
}

teardown :: proc() {
    if window != nil {
        sdl.DestroyWindow(window)
    }

    if device != nil {
        sdl.DestroyGPUDevice(device)
    }
}

update_loop :: proc() {
    is_running := true
    event: sdl.Event

    for is_running {
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                is_running = false
            case .KEY_UP:
                switch event.key.key {
                case 27:
                    is_running = false
                }
            }
        }

        command_buffer := sdl.AcquireGPUCommandBuffer(device)
        if command_buffer == nil {
            log.errorf("unable to aquire command buffer: {}", sdl.GetError())
            return
        }

        swapchain_texture: ^sdl.GPUTexture
        if sdl.WaitAndAcquireGPUSwapchainTexture(
            command_buffer,
            window,
            &swapchain_texture,
            nil,
            nil,
        ) {
            color_target_info := sdl.GPUColorTargetInfo {
                texture     = swapchain_texture,
                clear_color = sdl.FColor{1, 0.5, 0.5, 1},
                load_op     = .CLEAR,
                store_op    = .STORE,
            }

            render_pass := sdl.BeginGPURenderPass(
                command_buffer,
                &color_target_info,
                1,
                nil,
            )
            sdl.EndGPURenderPass(render_pass)
        }

        if !sdl.SubmitGPUCommandBuffer(command_buffer) {
            log.errorf("unable to submit command buffer: {}", sdl.GetError())
            return
        }
    }
}
