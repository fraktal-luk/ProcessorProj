/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x7708f090 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "C:/Users/frakt_000/Documents/GitHub/ProcessorProj/ProcDev/PipeStageLogicBuffer.vhd";
extern char *IEEE_P_2592010699;
extern char *WORK_P_2913168131;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );
int work_p_2913168131_sub_2384492247_1522046508(char *, char *);


static void work_a_2244275876_3212880686_p_0(char *t0)
{
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    int t13;
    int t14;
    int t15;
    int t16;

LAB0:    xsi_set_current_line(87, ng0);
    t1 = (t0 + 992U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 8224);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(88, ng0);
    t3 = (t0 + 1192U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:    t1 = (t0 + 1352U);
    t3 = *((char **)t1);
    t2 = *((unsigned char *)t3);
    t5 = (t2 == (unsigned char)3);
    if (t5 != 0)
        goto LAB8;

LAB9:
LAB6:    goto LAB3;

LAB5:    xsi_set_current_line(89, ng0);
    t3 = xsi_get_transient_memory(8U);
    memset(t3, 0, 8U);
    t7 = t3;
    memset(t7, (unsigned char)2, 8U);
    t8 = (t0 + 8368);
    t9 = (t8 + 56U);
    t10 = *((char **)t9);
    t11 = (t10 + 56U);
    t12 = *((char **)t11);
    memcpy(t12, t3, 8U);
    xsi_driver_first_trans_fast(t8);
    goto LAB6;

LAB8:    xsi_set_current_line(91, ng0);
    t1 = (t0 + 3592U);
    t4 = *((char **)t1);
    t13 = work_p_2913168131_sub_2384492247_1522046508(WORK_P_2913168131, t4);
    t1 = (t0 + 4232U);
    t7 = *((char **)t1);
    t14 = work_p_2913168131_sub_2384492247_1522046508(WORK_P_2913168131, t7);
    t6 = (t13 >= t14);
    if (t6 == 0)
        goto LAB10;

LAB11:    xsi_set_current_line(93, ng0);
    t1 = (t0 + 4392U);
    t3 = *((char **)t1);
    t13 = work_p_2913168131_sub_2384492247_1522046508(WORK_P_2913168131, t3);
    t1 = (t0 + 2152U);
    t4 = *((char **)t1);
    t14 = work_p_2913168131_sub_2384492247_1522046508(WORK_P_2913168131, t4);
    t15 = (t13 + t14);
    t1 = (t0 + 5688U);
    t7 = *((char **)t1);
    t16 = work_p_2913168131_sub_2384492247_1522046508(WORK_P_2913168131, t7);
    t2 = (t15 <= t16);
    if (t2 == 0)
        goto LAB12;

LAB13:    xsi_set_current_line(95, ng0);
    t1 = (t0 + 4552U);
    t3 = *((char **)t1);
    t1 = (t0 + 8368);
    t4 = (t1 + 56U);
    t7 = *((char **)t4);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memcpy(t9, t3, 8U);
    xsi_driver_first_trans_fast(t1);
    goto LAB6;

LAB10:    t1 = (t0 + 14258);
    xsi_report(t1, 31U, (unsigned char)1);
    goto LAB11;

LAB12:    t1 = (t0 + 14289);
    xsi_report(t1, 26U, (unsigned char)1);
    goto LAB13;

}

static void work_a_2244275876_3212880686_p_1(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(123, ng0);

LAB3:    t1 = (t0 + 4232U);
    t2 = *((char **)t1);
    t1 = (t0 + 8432);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memcpy(t6, t2, 8U);
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t7 = (t0 + 8240);
    *((int *)t7) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_2244275876_3212880686_p_2(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(124, ng0);

LAB3:    t1 = (t0 + 4072U);
    t2 = *((char **)t1);
    t1 = (t0 + 8496);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memcpy(t6, t2, 8U);
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t7 = (t0 + 8256);
    *((int *)t7) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_2244275876_3212880686_p_3(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(125, ng0);

LAB3:    t1 = (t0 + 3432U);
    t2 = *((char **)t1);
    t1 = (t0 + 8560);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memcpy(t6, t2, 8U);
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t7 = (t0 + 8272);
    *((int *)t7) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_2244275876_3212880686_p_4(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(126, ng0);

LAB3:    t1 = (t0 + 3592U);
    t2 = *((char **)t1);
    t1 = (t0 + 8624);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memcpy(t6, t2, 8U);
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t7 = (t0 + 8288);
    *((int *)t7) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}


extern void work_a_2244275876_3212880686_init()
{
	static char *pe[] = {(void *)work_a_2244275876_3212880686_p_0,(void *)work_a_2244275876_3212880686_p_1,(void *)work_a_2244275876_3212880686_p_2,(void *)work_a_2244275876_3212880686_p_3,(void *)work_a_2244275876_3212880686_p_4};
	xsi_register_didat("work_a_2244275876_3212880686", "isim/NewCoreTB_isim_beh.exe.sim/work/a_2244275876_3212880686.didat");
	xsi_register_executes(pe);
}
