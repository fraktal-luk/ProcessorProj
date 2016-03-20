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
static const char *ng0 = "C:/Users/frakt_000/Documents/GitHub/ProcessorProj/ProcDev/CompareBefore8.v";



static int sp_isBefore(char *t1, char *t2)
{
    char t9[8];
    int t0;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;

LAB0:    t0 = 1;
    xsi_set_current_line(32, ng0);

LAB2:    xsi_set_current_line(33, ng0);
    t3 = (t1 + 2200);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t1 + 2360);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    memset(t9, 0, 8);
    xsi_vlog_unsigned_minus(t9, 8, t5, 8, t8, 8);
    t10 = (t1 + 2680);
    xsi_vlogvar_assign_value(t10, t9, 0, 0, 8);
    xsi_set_current_line(34, ng0);
    t3 = (t1 + 2680);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    memset(t9, 0, 8);
    t6 = (t9 + 4);
    t7 = (t5 + 4);
    t11 = *((unsigned int *)t5);
    t12 = (t11 >> 7);
    t13 = (t12 & 1);
    *((unsigned int *)t9) = t13;
    t14 = *((unsigned int *)t7);
    t15 = (t14 >> 7);
    t16 = (t15 & 1);
    *((unsigned int *)t6) = t16;
    t8 = (t1 + 2520);
    xsi_vlogvar_assign_value(t8, t9, 0, 0, 1);
    t0 = 0;

LAB1:    return t0;
}

static void Cont_27_0(char *t0)
{
    char t21[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    int t17;
    char *t18;
    char *t19;
    char *t20;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    unsigned int t30;
    unsigned int t31;
    char *t32;
    unsigned int t33;
    unsigned int t34;
    char *t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;

LAB0:    t1 = (t0 + 3600U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(27, ng0);
    t2 = (t0 + 1480U);
    t3 = *((char **)t2);
    t2 = (t0 + 1640U);
    t4 = *((char **)t2);
    t2 = (t0 + 3408);
    t5 = (t0 + 848);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 2200);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 2360);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 3504);
    t10 = *((char **)t9);
    t11 = (t10 + 80U);
    t12 = *((char **)t11);
    t13 = (t12 + 272U);
    t14 = *((char **)t13);
    t15 = (t14 + 0U);
    t16 = *((char **)t15);
    t17 = ((int  (*)(char *, char *))t16)(t0, t10);
    if (t17 != 0)
        goto LAB6;

LAB5:    t10 = (t0 + 3504);
    t18 = *((char **)t10);
    t10 = (t0 + 2520);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 848);
    t23 = (t0 + 3408);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 4000);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 1U;
    t31 = t30;
    t32 = (t21 + 4);
    t33 = *((unsigned int *)t21);
    t30 = (t30 & t33);
    t34 = *((unsigned int *)t32);
    t31 = (t31 & t34);
    t35 = (t29 + 4);
    t36 = *((unsigned int *)t29);
    *((unsigned int *)t29) = (t36 | t30);
    t37 = *((unsigned int *)t35);
    *((unsigned int *)t35) = (t37 | t31);
    xsi_driver_vfirst_trans(t25, 0, 0);
    t38 = (t0 + 3920);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 3600U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}


extern void work_m_00000000000493532047_1979947349_init()
{
	static char *pe[] = {(void *)Cont_27_0};
	static char *se[] = {(void *)sp_isBefore};
	xsi_register_didat("work_m_00000000000493532047_1979947349", "isim/NewCoreTB_isim_beh.exe.sim/work/m_00000000000493532047_1979947349.didat");
	xsi_register_executes(pe);
	xsi_register_subprogram_executes(se);
}
