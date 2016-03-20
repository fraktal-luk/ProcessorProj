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
static const char *ng0 = "C:/Users/frakt_000/Documents/GitHub/ProcessorProj/ProcDev/NewCoreTB.vhd";
extern char *IEEE_P_2592010699;
extern char *WORK_P_2913168131;
extern char *WORK_P_2284038668;
extern char *WORK_P_3178049071;
extern char *WORK_P_2392574874;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );
int work_p_2284038668_sub_1279250441_2077180020(char *, char *, char *);
int work_p_2392574874_sub_492870414_3353671955(char *, char *, char *);


static void work_a_2063723557_2372691052_p_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    int64 t7;
    int64 t8;

LAB0:    t1 = (t0 + 5032U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(142, ng0);
    t2 = (t0 + 6456);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    *((unsigned char *)t6) = (unsigned char)3;
    xsi_driver_first_trans_fast(t2);
    xsi_set_current_line(143, ng0);
    t2 = (t0 + 4048U);
    t3 = *((char **)t2);
    t7 = *((int64 *)t3);
    t8 = (t7 / 2);
    t2 = (t0 + 4840);
    xsi_process_wait(t2, t8);

LAB6:    *((char **)t1) = &&LAB7;

LAB1:    return;
LAB4:    xsi_set_current_line(144, ng0);
    t2 = (t0 + 6456);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    *((unsigned char *)t6) = (unsigned char)2;
    xsi_driver_first_trans_fast(t2);
    xsi_set_current_line(145, ng0);
    t2 = (t0 + 4048U);
    t3 = *((char **)t2);
    t7 = *((int64 *)t3);
    t8 = (t7 / 2);
    t2 = (t0 + 4840);
    xsi_process_wait(t2, t8);

LAB10:    *((char **)t1) = &&LAB11;
    goto LAB1;

LAB5:    goto LAB4;

LAB7:    goto LAB5;

LAB8:    goto LAB2;

LAB9:    goto LAB8;

LAB11:    goto LAB9;

}

static void work_a_2063723557_2372691052_p_1(char *t0)
{
    int64 t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(148, ng0);

LAB3:    t1 = (105 * 1000LL);
    t2 = (t0 + 6520);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    *((unsigned char *)t6) = (unsigned char)3;
    xsi_driver_first_trans_delta(t2, 0U, 1, t1);
    t7 = (t0 + 6520);
    xsi_driver_intertial_reject(t7, t1, t1);

LAB2:
LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_2063723557_2372691052_p_2(char *t0)
{
    char *t1;
    char *t2;
    int64 t3;
    char *t4;
    int64 t5;

LAB0:    t1 = (t0 + 5528U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(153, ng0);
    t3 = (100 * 1000LL);
    t2 = (t0 + 5336);
    xsi_process_wait(t2, t3);

LAB6:    *((char **)t1) = &&LAB7;

LAB1:    return;
LAB4:    xsi_set_current_line(155, ng0);
    t2 = (t0 + 4048U);
    t4 = *((char **)t2);
    t3 = *((int64 *)t4);
    t5 = (t3 * 10);
    t2 = (t0 + 5336);
    xsi_process_wait(t2, t5);

LAB10:    *((char **)t1) = &&LAB11;
    goto LAB1;

LAB5:    goto LAB4;

LAB7:    goto LAB5;

LAB8:    xsi_set_current_line(159, ng0);

LAB14:    *((char **)t1) = &&LAB15;
    goto LAB1;

LAB9:    goto LAB8;

LAB11:    goto LAB9;

LAB12:    goto LAB2;

LAB13:    goto LAB12;

LAB15:    goto LAB13;

}

static void work_a_2063723557_2372691052_p_3(char *t0)
{
    char *t1;
    char *t2;
    int64 t3;
    char *t4;
    unsigned char t5;
    char *t6;
    char *t7;
    char *t8;

LAB0:    t1 = (t0 + 5776U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(164, ng0);
    t3 = (3000 * 1000LL);
    t2 = (t0 + 5584);
    xsi_process_wait(t2, t3);

LAB6:    *((char **)t1) = &&LAB7;

LAB1:    return;
LAB4:    xsi_set_current_line(165, ng0);

LAB10:    t2 = (t0 + 6344);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB11;
    goto LAB1;

LAB5:    goto LAB4;

LAB7:    goto LAB5;

LAB8:    t6 = (t0 + 6344);
    *((int *)t6) = 0;
    xsi_set_current_line(166, ng0);
    t2 = (t0 + 6584);
    t4 = (t2 + 56U);
    t6 = *((char **)t4);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    *((unsigned char *)t8) = (unsigned char)3;
    xsi_driver_first_trans_fast(t2);
    xsi_set_current_line(167, ng0);

LAB14:    t2 = (t0 + 6360);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB15;
    goto LAB1;

LAB9:    t4 = (t0 + 992U);
    t5 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t4, 0U, 0U);
    if (t5 == 1)
        goto LAB8;
    else
        goto LAB10;

LAB11:    goto LAB9;

LAB12:    t6 = (t0 + 6360);
    *((int *)t6) = 0;
    xsi_set_current_line(168, ng0);
    t2 = (t0 + 6584);
    t4 = (t2 + 56U);
    t6 = *((char **)t4);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    *((unsigned char *)t8) = (unsigned char)2;
    xsi_driver_first_trans_fast(t2);
    xsi_set_current_line(169, ng0);

LAB18:    *((char **)t1) = &&LAB19;
    goto LAB1;

LAB13:    t4 = (t0 + 992U);
    t5 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t4, 0U, 0U);
    if (t5 == 1)
        goto LAB12;
    else
        goto LAB14;

LAB15:    goto LAB13;

LAB16:    goto LAB2;

LAB17:    goto LAB16;

LAB19:    goto LAB17;

}

static void work_a_2063723557_2372691052_p_4(char *t0)
{
    char t23[16];
    char t34[16];
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    int t8;
    int t9;
    char *t10;
    int t11;
    int t12;
    unsigned char t13;
    char *t14;
    char *t15;
    unsigned char t16;
    unsigned char t17;
    char *t18;
    int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t24;
    char *t25;
    int t26;
    unsigned int t27;
    int t28;
    unsigned char t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t35;
    char *t36;
    int t37;
    unsigned int t38;
    int t39;
    int t40;
    int t41;
    int t42;
    unsigned int t43;
    unsigned int t44;
    char *t45;
    char *t46;
    int t47;
    int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    char *t52;
    char *t53;
    char *t54;
    char *t55;
    char *t56;

LAB0:    xsi_set_current_line(177, ng0);
    t1 = (t0 + 992U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 6376);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(178, ng0);
    t3 = (t0 + 1352U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:
LAB6:    goto LAB3;

LAB5:    xsi_set_current_line(181, ng0);
    t3 = ((WORK_P_2913168131) + 1408U);
    t7 = *((char **)t3);
    t8 = *((int *)t7);
    t9 = (t8 - 1);
    t3 = (t0 + 11180);
    *((int *)t3) = 0;
    t10 = (t0 + 11184);
    *((int *)t10) = t9;
    t11 = 0;
    t12 = t9;

LAB8:    if (t11 <= t12)
        goto LAB9;

LAB11:    goto LAB6;

LAB9:    xsi_set_current_line(182, ng0);
    t14 = (t0 + 3272U);
    t15 = *((char **)t14);
    t16 = *((unsigned char *)t15);
    t17 = (t16 == (unsigned char)3);
    if (t17 == 1)
        goto LAB15;

LAB16:    t13 = (unsigned char)0;

LAB17:    if (t13 != 0)
        goto LAB12;

LAB14:    xsi_set_current_line(186, ng0);
    t1 = (t0 + 6712);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t7 = (t4 + 56U);
    t10 = *((char **)t7);
    *((unsigned char *)t10) = (unsigned char)2;
    xsi_driver_first_trans_fast(t1);

LAB13:
LAB10:    t1 = (t0 + 11180);
    t11 = *((int *)t1);
    t3 = (t0 + 11184);
    t12 = *((int *)t3);
    if (t11 == t12)
        goto LAB11;

LAB25:    t8 = (t11 + 1);
    t11 = t8;
    t4 = (t0 + 11180);
    *((int *)t4) = t11;
    goto LAB8;

LAB12:    xsi_set_current_line(183, ng0);
    t25 = ((WORK_P_3178049071) + 1168U);
    t30 = *((char **)t25);
    t25 = (t0 + 3432U);
    t31 = *((char **)t25);
    t27 = (31 - 9);
    t32 = (t27 * 1U);
    t33 = (0 + t32);
    t25 = (t31 + t33);
    t35 = (t34 + 0U);
    t36 = (t35 + 0U);
    *((int *)t36) = 9;
    t36 = (t35 + 4U);
    *((int *)t36) = 2;
    t36 = (t35 + 8U);
    *((int *)t36) = -1;
    t37 = (2 - 9);
    t38 = (t37 * -1);
    t38 = (t38 + 1);
    t36 = (t35 + 12U);
    *((unsigned int *)t36) = t38;
    t39 = work_p_2392574874_sub_492870414_3353671955(WORK_P_2392574874, t25, t34);
    t36 = (t0 + 11180);
    t40 = *((int *)t36);
    t41 = (t39 + t40);
    t42 = (t41 - 0);
    t38 = (t42 * 1);
    xsi_vhdl_check_range_of_index(0, 511, 1, t41);
    t43 = (32U * t38);
    t44 = (0 + t43);
    t45 = (t30 + t44);
    t46 = (t0 + 11180);
    t47 = *((int *)t46);
    t48 = (t47 - 0);
    t49 = (t48 * 1);
    t50 = (32U * t49);
    t51 = (0U + t50);
    t52 = (t0 + 6648);
    t53 = (t52 + 56U);
    t54 = *((char **)t53);
    t55 = (t54 + 56U);
    t56 = *((char **)t55);
    memcpy(t56, t45, 32U);
    xsi_driver_first_trans_delta(t52, t51, 32U, 0LL);
    xsi_set_current_line(184, ng0);
    t1 = (t0 + 6712);
    t3 = (t1 + 56U);
    t4 = *((char **)t3);
    t7 = (t4 + 56U);
    t10 = *((char **)t7);
    *((unsigned char *)t10) = (unsigned char)3;
    xsi_driver_first_trans_fast(t1);
    goto LAB13;

LAB15:    t14 = (t0 + 3432U);
    t18 = *((char **)t14);
    if (31 > 0)
        goto LAB18;

LAB19:    if (-1 == -1)
        goto LAB23;

LAB24:    t19 = 0;

LAB20:    t20 = (31 - t19);
    t21 = (t20 * 1U);
    t22 = (0 + t21);
    t14 = (t18 + t22);
    t24 = (t23 + 0U);
    t25 = (t24 + 0U);
    *((int *)t25) = 31;
    t25 = (t24 + 4U);
    *((int *)t25) = 9;
    t25 = (t24 + 8U);
    *((int *)t25) = -1;
    t26 = (9 - 31);
    t27 = (t26 * -1);
    t27 = (t27 + 1);
    t25 = (t24 + 12U);
    *((unsigned int *)t25) = t27;
    t28 = work_p_2284038668_sub_1279250441_2077180020(WORK_P_2284038668, t14, t23);
    t29 = (t28 == 0);
    t13 = t29;
    goto LAB17;

LAB18:    if (-1 == 1)
        goto LAB21;

LAB22:    t19 = 31;
    goto LAB20;

LAB21:    t19 = 0;
    goto LAB20;

LAB23:    t19 = 31;
    goto LAB20;

}


extern void work_a_2063723557_2372691052_init()
{
	static char *pe[] = {(void *)work_a_2063723557_2372691052_p_0,(void *)work_a_2063723557_2372691052_p_1,(void *)work_a_2063723557_2372691052_p_2,(void *)work_a_2063723557_2372691052_p_3,(void *)work_a_2063723557_2372691052_p_4};
	xsi_register_didat("work_a_2063723557_2372691052", "isim/NewCoreTB_isim_beh.exe.sim/work/a_2063723557_2372691052.didat");
	xsi_register_executes(pe);
}
