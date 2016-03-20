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
static const char *ng0 = "C:/Users/frakt_000/Documents/GitHub/ProcessorProj/ProcDev/VerilogCQRouting0.v";
static int ng1[] = {0, 0};
static int ng2[] = {1, 0};
static int ng3[] = {256, 0};



static int sp_acceptingVec(char *t1, char *t2)
{
    char t5[8];
    char t15[8];
    char t17[8];
    char t19[8];
    int t0;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t16;
    char *t18;
    char *t20;
    unsigned int t21;
    int t22;

LAB0:    t0 = 1;
    xsi_set_current_line(47, ng0);

LAB2:    xsi_set_current_line(48, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t1 + 4096);
    xsi_vlogvar_assign_value(t4, t3, 0, 0, 4);
    xsi_set_current_line(49, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t1 + 4096);
    t6 = (t1 + 4096);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = (t1 + 3776);
    t10 = (t9 + 56U);
    t11 = *((char **)t10);
    t12 = (t1 + 3936);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    memset(t15, 0, 8);
    xsi_vlog_unsigned_minus(t15, 32, t11, 8, t14, 8);
    t16 = ((char*)((ng2)));
    memset(t17, 0, 8);
    xsi_vlog_unsigned_minus(t17, 32, t15, 32, t16, 32);
    t18 = ((char*)((ng3)));
    memset(t19, 0, 8);
    xsi_vlog_unsigned_mod(t19, 32, t17, 32, t18, 32);
    xsi_vlog_generic_convert_bit_index(t5, t8, 2, t19, 32, 2);
    t20 = (t5 + 4);
    t21 = *((unsigned int *)t20);
    t22 = (!(t21));
    if (t22 == 1)
        goto LAB3;

LAB4:    t0 = 0;

LAB1:    return t0;
LAB3:    xsi_vlogvar_assign_value(t4, t3, 0, *((unsigned int *)t5), 1);
    goto LAB4;

}

static void Cont_40_0(char *t0)
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

LAB0:    t1 = (t0 + 5016U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(40, ng0);
    t2 = (t0 + 1776U);
    t3 = *((char **)t2);
    t2 = (t0 + 1616U);
    t4 = *((char **)t2);
    t2 = (t0 + 4824);
    t5 = (t0 + 984);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 3776);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 3936);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 4920);
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

LAB5:    t10 = (t0 + 4920);
    t18 = *((char **)t10);
    t10 = (t0 + 4096);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 984);
    t23 = (t0 + 4824);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 6472);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 15U;
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
    xsi_driver_vfirst_trans(t25, 0, 3);
    t38 = (t0 + 6328);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 5016U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}

static void Cont_40_1(char *t0)
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

LAB0:    t1 = (t0 + 5264U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(40, ng0);
    t2 = (t0 + 1936U);
    t3 = *((char **)t2);
    t2 = (t0 + 1616U);
    t4 = *((char **)t2);
    t2 = (t0 + 5072);
    t5 = (t0 + 984);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 3776);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 3936);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 5168);
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

LAB5:    t10 = (t0 + 5168);
    t18 = *((char **)t10);
    t10 = (t0 + 4096);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 984);
    t23 = (t0 + 5072);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 6536);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 15U;
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
    xsi_driver_vfirst_trans(t25, 0, 3);
    t38 = (t0 + 6344);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 5264U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}

static void Cont_40_2(char *t0)
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

LAB0:    t1 = (t0 + 5512U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(41, ng0);
    t2 = (t0 + 2096U);
    t3 = *((char **)t2);
    t2 = (t0 + 1616U);
    t4 = *((char **)t2);
    t2 = (t0 + 5320);
    t5 = (t0 + 984);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 3776);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 3936);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 5416);
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

LAB5:    t10 = (t0 + 5416);
    t18 = *((char **)t10);
    t10 = (t0 + 4096);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 984);
    t23 = (t0 + 5320);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 6600);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 15U;
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
    xsi_driver_vfirst_trans(t25, 0, 3);
    t38 = (t0 + 6360);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 5512U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}

static void Cont_40_3(char *t0)
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

LAB0:    t1 = (t0 + 5760U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(42, ng0);
    t2 = (t0 + 2256U);
    t3 = *((char **)t2);
    t2 = (t0 + 1616U);
    t4 = *((char **)t2);
    t2 = (t0 + 5568);
    t5 = (t0 + 984);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 3776);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 3936);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 5664);
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

LAB5:    t10 = (t0 + 5664);
    t18 = *((char **)t10);
    t10 = (t0 + 4096);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 984);
    t23 = (t0 + 5568);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 6664);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 15U;
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
    xsi_driver_vfirst_trans(t25, 0, 3);
    t38 = (t0 + 6376);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 5760U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}

static void Cont_40_4(char *t0)
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

LAB0:    t1 = (t0 + 6008U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(43, ng0);
    t2 = (t0 + 2416U);
    t3 = *((char **)t2);
    t2 = (t0 + 1616U);
    t4 = *((char **)t2);
    t2 = (t0 + 5816);
    t5 = (t0 + 984);
    t6 = xsi_create_subprogram_invocation(t2, 0, t0, t5, 0, 0);
    t7 = (t0 + 3776);
    xsi_vlogvar_assign_value(t7, t3, 0, 0, 8);
    t8 = (t0 + 3936);
    xsi_vlogvar_assign_value(t8, t4, 0, 0, 8);

LAB4:    t9 = (t0 + 5912);
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

LAB5:    t10 = (t0 + 5912);
    t18 = *((char **)t10);
    t10 = (t0 + 4096);
    t19 = (t10 + 56U);
    t20 = *((char **)t19);
    memcpy(t21, t20, 8);
    t22 = (t0 + 984);
    t23 = (t0 + 5816);
    t24 = 0;
    xsi_delete_subprogram_invocation(t22, t18, t0, t23, t24);
    t25 = (t0 + 6728);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    memset(t29, 0, 8);
    t30 = 15U;
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
    xsi_driver_vfirst_trans(t25, 0, 3);
    t38 = (t0 + 6392);
    *((int *)t38) = 1;

LAB1:    return;
LAB6:    t9 = (t0 + 6008U);
    *((char **)t9) = &&LAB4;
    goto LAB1;

}


extern void work_m_00000000002249749207_0415011089_init()
{
	static char *pe[] = {(void *)Cont_40_0,(void *)Cont_40_1,(void *)Cont_40_2,(void *)Cont_40_3,(void *)Cont_40_4};
	static char *se[] = {(void *)sp_acceptingVec};
	xsi_register_didat("work_m_00000000002249749207_0415011089", "isim/NewCoreTB_isim_beh.exe.sim/work/m_00000000002249749207_0415011089.didat");
	xsi_register_executes(pe);
	xsi_register_subprogram_executes(se);
}
