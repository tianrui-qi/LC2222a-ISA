! Fall 2023 Revisions 

! This program executes pow as a test program using the LC 2222 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

! vector table
vector0:
        .fill 0x00000000                        ! device ID 0
        .fill 0x00000000                        ! device ID 1
        .fill 0x00000000                        ! ...
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000                        ! device ID 7
        ! end vector table

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

        ! TODO FIX ME: Install timer interrupt handler into vector table 
        lea $t0, timer_handler
        lea $t1, vector0
        sw $t0, 0($t1)              

        ! TODO FIX ME: Install distance tracker interrupt handler into vector table
        lea $t0, distance_tracker_handler
        lea $t1, vector0
        sw $t0, 1($t1)               


        lea $t0, minval
        lw $t0, 0($t0)
	lea $t1, INT_MAX 			! store 0x7FFFFFFF into minval (to initialize)
	lw $t1, 0($t1)	                  		
        sw $t1, 0($t0)

        ei                                      ! Enable interrupts

        lea $a0, BASE                           ! load base for pow
        lw $a0, 0($a0)
        lea $a1, EXP                            ! load power for pow
        lw $a1, 0($a1)
        lea $at, POW                            ! load address of pow
        jalr $at, $ra                           ! run pow
        lea $a0, ANS                            ! load base for pow
        sw $v0, 0($a0)

        halt                                    ! stop the program here
        addi $v0, $zero, -1                     ! load a bad value on failure to halt

BASE:   .fill 2
EXP:    .fill 8
ANS:	.fill 0                                 ! should come out to 256 (BASE^EXP)

INT_MAX: .fill 0x7FFFFFFF

POW:    addi $sp, $sp, -1                       ! allocate space for old frame pointer
        sw $fp, 0($sp)

        addi $fp, $sp, 0                        ! set new frame pointer

        bgt $a1, $zero, BASECHK                 ! check if $a1 is zero
        beq $zero, $zero, RET1                  ! if the exponent is 0, return 1

BASECHK:bgt $a0, $zero, WORK                    ! if the base is 0, return 0
        beq $zero, $zero, RET0

WORK:   addi $a1, $a1, -1                       ! decrement the power
        lea $at, POW                            ! load the address of POW
        addi $sp, $sp, -2                       ! push 2 slots onto the stack
        sw $ra, -1($fp)                         ! save RA to stack
        sw $a0, -2($fp)                         ! save arg 0 to stack
        jalr $at, $ra                           ! recursively call POW
        add $a1, $v0, $zero                     ! store return value in arg 1
        lw $a0, -2($fp)                         ! load the base into arg 0
        lea $at, MULT                           ! load the address of MULT
        jalr $at, $ra                           ! multiply arg 0 (base) and arg 1 (running product)
        lw $ra, -1($fp)                         ! load RA from the stack
        addi $sp, $sp, 2

        beq $zero, $zero, FIN                   ! unconditional branch to FIN

RET1:   add $v0, $zero, $zero                   ! return a value of 0
	addi $v0, $v0, 1                        ! increment and return 1
        beq $zero, $zero, FIN                   ! unconditional branch to FIN

RET0:   add $v0, $zero, $zero                   ! return a value of 0

FIN:	lw $fp, 0($fp)                          ! restore old frame pointer
        addi $sp, $sp, 1                        ! pop off the stack
        jalr $ra, $zero

MULT:   add $v0, $zero, $zero                   ! return value = 0
        addi $t0, $zero, 0                      ! sentinel = 0
AGAIN:  add $v0, $v0, $a0                       ! return value += argument0
        addi $t0, $t0, 1                        ! increment sentinel
        blt $t0, $a1, AGAIN                     ! while sentinel < argument, loop again
        jalr $ra, $zero                         ! return from mult

timer_handler:
        addi $sp, $sp, -1                       ! save k0
        sw $k0, 0($sp)
        ei                                      ! enable interrupt
        addi $sp, $sp, -3                       ! save state
        sw $t0, 0($sp)
        sw $t1, 1($sp)
        sw $t2, 2($sp)

        ! handler
        lea $t0, ticks                          ! load counter PC adress
        lw $t0, 0($t0)                          ! load counter memory address
        lw $t1, 0($t0)                          ! load counter value in memory
        addi $t1, $t1, 1                        ! increment counter
        sw $t1, 0($t0)                          ! store counter to memory

        lw $t0, 0($sp)                          ! restore state
        lw $t1, 1($sp)
        lw $t2, 2($sp)
        addi $sp, $sp, 3
        di                                      ! disable interrupt
        lw $k0, 0($sp)                          ! restore k0
        addi $sp, $sp, 1
        reti

distance_tracker_handler:
        addi $sp, $sp, -1                       ! save k0
        sw $k0, 0($sp)
        ei                                      ! enable interrupt
        addi $sp, $sp, -3                       ! save state
        sw $t0, 0($sp)
        sw $t1, 1($sp)
        sw $t2, 2($sp)

        ! handler
        in      $t0, 1                          ! t0 = distance tracker
        lea     $t1, maxval                     ! t1 = maxval
        lw      $t1, 0($t1)
        lw      $t1, 0($t1)
        lea     $t2, minval                     ! t2 = minval
        lw      $t2, 0($t2)
        lw      $t2, 0($t2)

        bgt     $t0, $t1, updatemaxval          ! if t0 > t1, update maxval
        blt     $t0, $t2, updateminval          ! if t0 < t2, update minval
        beq     $t0, $t0, updaterange

updatemaxval:
        lea     $t1, maxval                     ! t1 = maxval memeory address
        lw      $t1, 0($t1)                     
        sw      $t0, 0($t1)                     ! store t0 into maxval

        blt     $t0, $t2, updateminval          ! if t0 < t2, update minval
        beq     $t0, $t0, updaterange

updateminval:
        lea     $t2, minval                     ! t2 = minval memeory address
        lw      $t2, 0($t2)                     
        sw      $t0, 0($t2)                     ! store t0 into minval

        beq     $t0, $t0, updaterange

updaterange:
        ! recalculate range
        lea     $t1, maxval                     ! t1 = maxval
        lw      $t1, 0($t1)
        lw      $t1, 0($t1)
        lea     $t2, minval                     ! t2 = minval
        lw      $t2, 0($t2)
        lw      $t2, 0($t2)
        nand    $t2, $t2, $t2                   ! t2 = -minval
        addi    $t2, $t2, 1
        add     $t1, $t1, $t2                   ! t1 = maxval - minval

        ! since we already update minval and maxval by t0 that store the 
        ! distance tracker, we do not need t0 anymore
        lea     $t0, range                      ! t0 = range's memory address
        lw      $t0, 0($t0)
        sw      $t1, 0($t0)                     ! store t1 into range

finish:
        lw $t0, 0($sp)                          ! restore state
        lw $t1, 1($sp)
        lw $t2, 2($sp)
        addi $sp, $sp, 3
        di                                      ! disable interrupt
        lw $k0, 0($sp)                          ! restore k0
        addi $sp, $sp, 1
        reti


initsp: .fill 0xA000
ticks:  .fill 0xFFFF
range:  .fill 0xFFFE
maxval: .fill 0xFFFD
minval: .fill 0xFFFC