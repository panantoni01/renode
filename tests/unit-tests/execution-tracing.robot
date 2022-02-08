*** Settings ***
Suite Setup                                     Setup
Suite Teardown                                  Teardown
Test Setup                                      Reset Emulation
Test Teardown                                   Test Teardown
Resource                                        ${RENODEKEYWORDS}

*** Keywords ***
Create Machine
    Execute Command                             using sysbus
    Execute Command                             include @scripts/single-node/versatile.resc

    Execute Command                             cpu PerformanceInMips 1
    # the value of quantum is selected here to generate several blocks
    # of multiple instructions to check if the execution tracer can
    # disassemble blocks correctly
    Execute Command                             emulation SetGlobalQuantum "0.000004"

*** Test Cases ***
Should Dump PCs
    Create Machine
    ${FILE}=                                    Allocate Temporary File

    Execute Command                             cpu EnableExecutionTracing @${FILE} PC
    # exactly the amount of virtual time to execute 16 instructions
    Execute Command                             emulation RunFor "0.000016"

    # wait for the file to populate
    Sleep  3s

    ${content}=  Get File  ${FILE}
    @{pcs}=  Split To Lines  ${content}

    Length Should Be                            ${pcs}      16
    Should Be Equal                             ${pcs[0]}   0x8000
    Should Be Equal                             ${pcs[1]}   0x8004
    Should Be Equal                             ${pcs[2]}   0x8008
    Should Be Equal                             ${pcs[3]}   0x359C08
    Should Be Equal                             ${pcs[14]}  0x8010
    Should Be Equal                             ${pcs[15]}  0x8014

Should Dump Opcodes
    Create Machine
    ${FILE}=                                    Allocate Temporary File

    Execute Command                             cpu EnableExecutionTracing @${FILE} Opcode
    # exactly the amount of virtual time to execute 16 instructions
    Execute Command                             emulation RunFor "0.000016"

    # wait for the file to populate
    Sleep  3s

    ${content}=  Get File  ${FILE}
    @{pcs}=  Split To Lines  ${content}

    Length Should Be                            ${pcs}      16
    Should Be Equal                             ${pcs[0]}   0xE321F0D3
    Should Be Equal                             ${pcs[1]}   0xEE109F10
    Should Be Equal                             ${pcs[2]}   0xEB0D46FE
    Should Be Equal                             ${pcs[3]}   0xE28F3030
    Should Be Equal                             ${pcs[14]}  0x0A0D470D
    Should Be Equal                             ${pcs[15]}  0xE28F302C

Should Dump PC And Opcodes
    Create Machine
    ${FILE}=                                    Allocate Temporary File

    Execute Command                             cpu EnableExecutionTracing @${FILE} PCAndOpcode
    # exactly the amount of virtual time to execute 16 instructions
    Execute Command                             emulation RunFor "0.000016"

    # wait for the file to populate
    Sleep  3s

    ${content}=  Get File  ${FILE}
    @{pcs}=  Split To Lines  ${content}

    Length Should Be                            ${pcs}      16
    Should Be Equal                             ${pcs[0]}   0x8000: 0xE321F0D3
    Should Be Equal                             ${pcs[1]}   0x8004: 0xEE109F10
    Should Be Equal                             ${pcs[2]}   0x8008: 0xEB0D46FE
    Should Be Equal                             ${pcs[3]}   0x359C08: 0xE28F3030
    Should Be Equal                             ${pcs[14]}  0x8010: 0x0A0D470D
    Should Be Equal                             ${pcs[15]}  0x8014: 0xE28F302C

Should Trace Consecutive Blocks
    Execute Command                             mach create
    Execute Command                             machine LoadPlatformDescriptionFromString "cpu: CPU.RiscV32 @ sysbus { cpuType: \\"rv32g\\"; timeProvider: empty }"
    Execute Command                             machine LoadPlatformDescriptionFromString "mem: Memory.MappedMemory @ sysbus 0x0 { size: 0x10000 }"

    # "li x1, 0"
    Execute Command                             sysbus WriteDoubleWord 0x200 0x93
    # "li x2, 10"
    Execute Command                             sysbus WriteDoubleWord 0x204 0x00a00113
    # "addi x1, x1, 1"
    Execute Command                             sysbus WriteDoubleWord 0x208 0x00108093
    # "bne x1, x2, 0x214"
    Execute Command                             sysbus WriteDoubleWord 0x20C 0x00209463
    # "j 0x300"
    Execute Command                             sysbus WriteDoubleWord 0x210 0x0f00006f

    # "nop"s
    Execute Command                             sysbus WriteDoubleWord 0x214 0x13
    Execute Command                             sysbus WriteDoubleWord 0x218 0x13
    Execute Command                             sysbus WriteDoubleWord 0x21C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x220 0x13
    Execute Command                             sysbus WriteDoubleWord 0x224 0x13
    Execute Command                             sysbus WriteDoubleWord 0x228 0x13
    Execute Command                             sysbus WriteDoubleWord 0x22C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x230 0x13
    Execute Command                             sysbus WriteDoubleWord 0x234 0x13
    Execute Command                             sysbus WriteDoubleWord 0x238 0x13
    Execute Command                             sysbus WriteDoubleWord 0x23C 0x13

    # "j +4" - just to break the block
    # this is to test the block chaining mechanism
    Execute Command                             sysbus WriteDoubleWord 0x240 0x0040006f

    # "nop"s
    Execute Command                             sysbus WriteDoubleWord 0x244 0x13
    Execute Command                             sysbus WriteDoubleWord 0x248 0x13
    Execute Command                             sysbus WriteDoubleWord 0x24C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x250 0x13
    Execute Command                             sysbus WriteDoubleWord 0x254 0x13
    Execute Command                             sysbus WriteDoubleWord 0x258 0x13
    Execute Command                             sysbus WriteDoubleWord 0x25C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x260 0x13
    Execute Command                             sysbus WriteDoubleWord 0x264 0x13
    Execute Command                             sysbus WriteDoubleWord 0x268 0x13
    Execute Command                             sysbus WriteDoubleWord 0x26C 0x13

    # "j +4" - just to break the block
    Execute Command                             sysbus WriteDoubleWord 0x270 0x0040006f

    # "nop"s
    Execute Command                             sysbus WriteDoubleWord 0x274 0x13
    Execute Command                             sysbus WriteDoubleWord 0x278 0x13
    Execute Command                             sysbus WriteDoubleWord 0x27C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x280 0x13
    Execute Command                             sysbus WriteDoubleWord 0x284 0x13
    Execute Command                             sysbus WriteDoubleWord 0x288 0x13
    Execute Command                             sysbus WriteDoubleWord 0x28C 0x13
    Execute Command                             sysbus WriteDoubleWord 0x290 0x13
    Execute Command                             sysbus WriteDoubleWord 0x294 0x13
    Execute Command                             sysbus WriteDoubleWord 0x298 0x13
    Execute Command                             sysbus WriteDoubleWord 0x29C 0x13

    # "j 0x208"
    Execute Command                             sysbus WriteDoubleWord 0x2A0 0xf69ff06f

    # "j 0x300"
    Execute Command                             sysbus WriteDoubleWord 0x300 0x6f

    Execute Command                             sysbus.cpu PC 0x200

    ${FILE}=                                    Allocate Temporary File
    Execute Command                             sysbus.cpu EnableExecutionTracing @${FILE} PC

    # run for 400 instructions
    Execute Command                             sysbus.cpu PerformanceInMips 1
    Execute Command                             emulation RunFor "0.000400"

    # should reach the end of the execution
    ${pc}=  Execute Command                     sysbus.cpu PC
    Should Contain                              ${pc}   0x300

    # wait for the file to populate
    Sleep  3s

    ${content}=  Get File  ${FILE}
    @{pcs}=  Split To Lines  ${content}

    Length Should Be                            ${pcs}      400
    Should Be Equal                             ${pcs[0]}   0x200
    Should Be Equal                             ${pcs[1]}   0x204
    Should Be Equal                             ${pcs[2]}   0x208
    Should Be Equal                             ${pcs[3]}   0x20C
    # here we skip a jump to 0x300 (it should fire at the very end)
    Should Be Equal                             ${pcs[4]}   0x214
    # first iteration of the loop
    Should Be Equal                             ${pcs[39]}  0x2A0
    Should Be Equal                             ${pcs[40]}  0x208
    # another iteration of the loop
    Should Be Equal                             ${pcs[77]}  0x2A0
    Should Be Equal                             ${pcs[78]}  0x208
    # and another
    Should Be Equal                             ${pcs[115]}  0x2A0
    Should Be Equal                             ${pcs[116]}  0x208
    # and the last one
    Should Be Equal                             ${pcs[343]}  0x2A0
    Should Be Equal                             ${pcs[344]}  0x208
    Should Be Equal                             ${pcs[345]}  0x20C
    Should Be Equal                             ${pcs[346]}  0x210
    Should Be Equal                             ${pcs[347]}  0x300