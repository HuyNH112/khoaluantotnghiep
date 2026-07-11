
matrix_test.elf:     file format elf32-littleriscv


Disassembly of section .text:

00010094 <main>:
   10094:	80010113          	addi	sp,sp,-2048
   10098:	80010113          	addi	sp,sp,-2048
   1009c:	4701                	li	a4,0
   1009e:	4585                	li	a1,1
   100a0:	40000613          	li	a2,1024
   100a4:	00271793          	slli	a5,a4,0x2
   100a8:	978a                	add	a5,a5,sp
   100aa:	c38c                	sw	a1,0(a5)
   100ac:	439c                	lw	a5,0(a5)
   100ae:	0741                	addi	a4,a4,16
   100b0:	fec71ae3          	bne	a4,a2,100a4 <main+0x10>
   100b4:	47a1                	li	a5,8
   100b6:	10f02023          	sw	a5,256(zero) # 100 <main-0xff94>
   100ba:	a001                	j	100ba <main+0x26>

Disassembly of section .comment:

00000000 <.comment>:
   0:	3a434347          	.insn	4, 0x3a434347
   4:	2820                	.insn	2, 0x2820
   6:	5078                	lw	a4,100(s0)
   8:	6361                	lui	t1,0x18
   a:	4e47206b          	.insn	4, 0x4e47206b
   e:	2055                	jal	b2 <main-0xffe2>
  10:	4952                	lw	s2,20(sp)
  12:	562d4353          	.insn	4, 0x562d4353
  16:	4520                	lw	s0,72(a0)
  18:	626d                	lui	tp,0x1b
  1a:	6465                	lui	s0,0x19
  1c:	6564                	.insn	2, 0x6564
  1e:	2064                	.insn	2, 0x2064
  20:	20434347          	.insn	4, 0x20434347
  24:	3878                	.insn	2, 0x3878
  26:	5f36                	lw	t5,108(sp)
  28:	3436                	.insn	2, 0x3436
  2a:	2029                	jal	34 <main-0x10060>
  2c:	3531                	jal	fffffe38 <__global_pointer$+0xfffee57c>
  2e:	322e                	.insn	2, 0x322e
  30:	302e                	.insn	2, 0x302e
	...

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	4d41                	li	s10,16
   2:	0000                	unimp
   4:	7200                	.insn	2, 0x7200
   6:	7369                	lui	t1,0xffffa
   8:	01007663          	bgeu	zero,a6,14 <main-0x10080>
   c:	00000043          	.insn	4, 0x0043
  10:	1004                	addi	s1,sp,32
  12:	7205                	lui	tp,0xfffe1
  14:	3376                	.insn	2, 0x3376
  16:	6932                	.insn	2, 0x6932
  18:	7032                	.insn	2, 0x7032
  1a:	5f31                	li	t5,-20
  1c:	326d                	jal	fffff9c6 <__global_pointer$+0xfffee10a>
  1e:	3070                	.insn	2, 0x3070
  20:	615f 7032 5f31      	.insn	6, 0x5f317032615f
  26:	30703263          	.insn	4, 0x30703263
  2a:	7a5f 6d6d 6c75      	.insn	6, 0x6c756d6d7a5f
  30:	7031                	c.lui	zero,0xfffec
  32:	5f30                	lw	a2,120(a4)
  34:	617a                	.insn	2, 0x617a
  36:	6d61                	lui	s10,0x18
  38:	3070316f          	jal	sp,3b3e <main-0xc556>
  3c:	7a5f 6c61 7372      	.insn	6, 0x73726c617a5f
  42:	30703163          	.insn	4, 0x30703163
  46:	7a5f 6163 7031      	.insn	6, 0x703161637a5f
  4c:	0030                	addi	a2,sp,8
