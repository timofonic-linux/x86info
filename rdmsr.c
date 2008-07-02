/*
 *  (C) 2001 Dave Jones.
 *
 *  Licensed under the terms of the GNU GPL License version 2.
 *
 *  Contributions by Arjan van de Ven & Philipp Rumpf.
 *
 *  Routines for reading MSRs.
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include "x86info.h"

#if defined(__FreeBSD__)
# include <sys/ioctl.h>                                                         
# include <cpu.h>
#endif

#if defined(__FreeBSD__)

int read_msr(int cpu, unsigned int idx, unsigned long long *val)
{
	char cpuname[16];
	unsigned char buffer[8];
	unsigned long lo, hi;
	int fh;
	static int nodriver=0;
	cpu_msr_args_t args;

	if (nodriver==1)
		return 0;

	(void)snprintf(cpuname, sizeof(cpuname), "/dev/cpu%d", cpu);

	fh = open(cpuname, O_RDONLY);
	if (fh==-1) {
		if (!silent)
			perror(cpuname);
		nodriver=1;
		return 0;
	}

	args.msr = idx;                                                         
	if (ioctl(fh, CPU_RDMSR, &args) != 0) {                                 
		if (close(fh) == -1) {                                          
			perror("close");                                        
			exit(EXIT_FAILURE);
		}

		return 0;
	}

	*val = args.data; 

	if (close(fh)==-1) {
		perror("close");
		exit(EXIT_FAILURE);
	}
	return 1;
}

#else /* !__FreeBSD__ */

int read_msr(int cpu, unsigned int idx, unsigned long long *val)
{
	char cpuname[16];
	unsigned char buffer[8];
	unsigned long lo, hi;
	int fh;
	static int nodriver=0;

	if (nodriver==1)
		return 0;

	(void)snprintf(cpuname, sizeof(cpuname), "/dev/cpu/%d/msr", cpu);

	fh = open(cpuname, O_RDONLY);
	if (fh==-1) {
		if (!silent)
			perror(cpuname);
		nodriver=1;
		return 0;
	}

	if (lseek(fh, idx, SEEK_CUR)==-1) {
		perror("lseek");
		exit(EXIT_FAILURE);
	}

	if (fh != -1) {
		if (read(fh, &buffer[0], 8) != 8) {
			if (close(fh) == -1) {
				perror("close");
				exit(EXIT_FAILURE);
			}
			return 0;
		}

		lo = (*(unsigned long *)buffer);
		hi = (*(unsigned long *)(buffer+4));
		*val = hi;
		*val = (*val<<32) | lo;
	}
	if (close(fh)==-1) {
		perror("close");
		exit(EXIT_FAILURE);
	}
	return 1;
}

#endif /* __FreeBSD__ */


void dumpmsr (int cpu, unsigned int msr, int size)
{
	unsigned long long val=0;

	if (read_msr(cpu, msr, &val) == 1) {
		if (size==32){
			printf ("MSR: 0x%08x=0x%08lx : ", msr, (unsigned long) val);
			binary32(val);
		}
		if (size==64) {
			printf ("MSR: 0x%08x=0x%016llx : ", msr, val);
			binary64(val);
		}
		return;
	}
	printf ("Couldn't read MSR 0x%x\n", msr);
}

void dumpmsr_bin (int cpu, unsigned int msr, int size)
{
	unsigned long long val=0;

	if (read_msr(cpu, msr, &val) == 1) {
		if (size==32)
			binary32(val);
		if (size==64)
			binary64(val);
		return;
	}
	printf ("Couldn't read MSR 0x%x\n", msr);
}
