; mkmon_A_8k.asm - Create object file containing Music Kit DSP Monitor
;		 configured for 8K words of external DSP SRAM.

; *** Must manually keep version,rev in synch with verrev.asm ***
; *** and DSP_SYS_{VER,REV}_C in dsp.h
mkmon_A_8k ident 65,41		; Music Kit DSP-resident monitor
	 define nolist 'list'	; stand back!
MEM_SIZ	  set  8192
MEM_OFF	  set  8192
ONE_MEM   set  1		; x,y,p are overlaid in external memory
SEND_KERN_ACKS set 1
ASM_SYS  set 1			; include system
	 include 'music_macros'	; need 'memmap, lc, allocsys'
	 end PLI_USR		; default start address in DSP


