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
static const char *ng0 = "C:/Users/frakt_000/Documents/GitHub/ProcessorProj/ProcDev/BufferCounter.v";
static int ng1[] = {0, 0};



static int sp_minByte(char *t1, char *t2)
{
    char t14[8];
    int t0;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;

LAB0:    t0 = 1;
    xsi_set_current_line(49, ng0);

LAB2:    xsi_set_current_line(50, ng0);
    t3 = (t1 + 5192);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB3;

LAB4:    xsi_set_current_line(53, ng0);
    t3 = (t1 + 4872);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t1 + 5032);
    t12 = (t6 + 56U);
    t13 = *((char **)t12);
    memset(t14, 0, 8);
    t15 = (t5 + 4);
    if (*((unsigned int *)t15) != 0)
        goto LAB8;

LAB7:    t16 = (t13 + 4);
    if (*((unsigned int *)t16) != 0)
        goto LAB8;

LAB11:    if (*((unsigned int *)t5) > *((unsigned int *)t13))
        goto LAB9;

LAB10:    t18 = (t14 + 4);
    t7 = *((unsigned int *)t18);
    t8 = (~(t7));
    t9 = *((unsigned int *)t14);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB12;

LAB13:    xsi_set_current_line(56, ng0);

LAB16:    xsi_set_current_line(57, ng0);
    t3 = (t1 + 4872);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t1 + 5352);
    xsi_vlogvar_assign_value(t6, t5, 0, 0, 8);

LAB14:
LAB5:    t0 = 0;

LAB1:    return t0;
LAB3:    xsi_set_current_line(50, ng0);

LAB6:    xsi_set_current_line(51, ng0);
    t12 = ((char*)((ng1)));
    t13 = (t1 + 5352);
    xsi_vlogvar_assign_value(t13, t12, 0, 0, 8);
    goto LAB5;

LAB8:    t17 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t17) = 1;
    goto LAB10;

LAB9:    *((unsigned int *)t14) = 1;
    goto LAB10;

LAB12:    xsi_set_current_line(53, ng0);

LAB15:    xsi_set_current_line(54, ng0);
    t19 = (t1 + 5032);
    t20 = (t19 + 56U);
    t21 = *((char **)t20);
    t22 = (t1 + 5352);
    xsi_vlogvar_assign_value(t22, t21, 0, 0, 8);
    goto LAB14;

}

static int sp_getLiving(char *t1, char *t2)
{
    char t14[8];
    int t0;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    char *t15;

LAB0:    t0 = 1;
    xsi_set_current_line(63, ng0);

LAB2:    xsi_set_current_line(64, ng0);
    t3 = (t1 + 5832);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB3;

LAB4:    xsi_set_current_line(67, ng0);

LAB7:    xsi_set_current_line(68, ng0);
    t3 = (t1 + 5512);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t1 + 5672);
    t12 = (t6 + 56U);
    t13 = *((char **)t12);
    memset(t14, 0, 8);
    xsi_vlog_unsigned_minus(t14, 8, t5, 8, t13, 8);
    t15 = (t1 + 5992);
    xsi_vlogvar_assign_value(t15, t14, 0, 0, 8);

LAB5:    t0 = 0;

LAB1:    return t0;
LAB3:    xsi_set_current_line(64, ng0);

LAB6:    xsi_set_current_line(65, ng0);
    t12 = ((char*)((ng1)));
    t13 = (t1 + 5992);
    xsi_vlogvar_assign_value(t13, t12, 0, 0, 8);
    goto LAB5;

}

static void Cont_82_0(char *t0)
{
    char t23[8];
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
    char *t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;

LAB0:    t1 = (t0 + 6912U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(82, ng0);
    t2 = (t0 + 2392U);
    t3 = *((char **)t2);
    t2 = (t0 + 3032U);
    t4 = *((char **)t2);
    t2 = (t0 + 2872U);
    t5 = *((char **)t2);
    t2 = (t0 + 6720);
    t6 = (t0 + 1280);
    t7 = xsi_create_subprogram_invocation(t2, 0, t0, t6, 0, 0);
    t8 = (t0 + 5512);
    xsi_vlogvar_assign_value(t8, t3, 0, 0, 8);
    t9 = (t0 + 5672);
    xsi_vlogvar_assign_value(t9, t4, 0, 0, 8);
    t10 = (t0 + 5832);
    xsi_vlogvar_assign_value(t10, t5, 0, 0, 1);

LAB4:    t11 = (t0 + 6816);
    t12 = *((char **)t11);
    t13 = (t12 + 80U);
    t14 = *((char **)t13);
    t15 = (t14 + 272U);
    t16 = *((char **)t15);
    t17 = (t16 + 0U);
    t18 = *((char **)t17);
    t19 = ((int  (*)(char *, char *))t18)(t0, t12);
    if (t19 != 0)
        goto LAB6;

LAB5:    t12 = (t0 + 6816);
    t20 = *((char **)t12);
    t12 = (t0 + 5992);
    t21 = (t12 + 56U);
    t22 = *((char **)t21);
    memcpy(t23, t22, 8);
    t24 = (t0 + 1280);
    t25 = (t0 + 6720);
    t26 = 0;
    xsi_delete_subprogram_invocation(t24, t20, t0, t25, t26);
    t27 = (t0 + 8896);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    t30 = (t29 + 56U);
    t31 = *((char **)t30);
    memset(t31, 0, 8);
    t32 = 255U;
    t33 = t32;
    t34 = (t23 + 4);
    t35 = *((unsigned int *)t23);
    t32 = (t32 & t35);
    t36 = *((unsigned int *)t34);
    t33 = (t33 & t36);
    t37 = (t31 + 4);
    t38 = *((unsigned int *)t31);
    *((unsigned int *)t31) = (t38 | t32);
    t39 = *((unsigned int *)t37);
    *((unsigned int *)t37) = (t39 | t33);
    xsi_driver_vfirst_trans(t27, 0, 7);
    t40 = (t0 + 8720);
    *((int *)t40) = 1;

LAB1:    return;
LAB6:    t11 = (t0 + 6912U);
    *((char **)t11) = &&LAB4;
    goto LAB1;

}

static void Cont_82_1(char *t0)
{
    char t23[8];
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
    char *t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;

LAB0:    t1 = (t0 + 7160U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(82, ng0);
    t2 = (t0 + 2232U);
    t3 = *((char **)t2);
    t2 = (t0 + 3512U);
    t4 = *((char **)t2);
    t2 = (t0 + 2712U);
    t5 = *((char **)t2);
    t2 = (t0 + 6968);
    t6 = (t0 + 848);
    t7 = xsi_create_subprogram_invocation(t2, 0, t0, t6, 0, 0);
    t8 = (t0 + 4872);
    xsi_vlogvar_assign_value(t8, t3, 0, 0, 8);
    t9 = (t0 + 5032);
    xsi_vlogvar_assign_value(t9, t4, 0, 0, 8);
    t10 = (t0 + 5192);
    xsi_vlogvar_assign_value(t10, t5, 0, 0, 1);

LAB4:    t11 = (t0 + 7064);
    t12 = *((char **)t11);
    t13 = (t12 + 80U);
    t14 = *((char **)t13);
    t15 = (t14 + 272U);
    t16 = *((char **)t15);
    t17 = (t16 + 0U);
    t18 = *((char **)t17);
    t19 = ((int  (*)(char *, char *))t18)(t0, t12);
    if (t19 != 0)
        goto LAB6;

LAB5:    t12 = (t0 + 7064);
    t20 = *((char **)t12);
    t12 = (t0 + 5352);
    t21 = (t12 + 56U);
    t22 = *((char **)t21);
    memcpy(t23, t22, 8);
    t24 = (t0 + 848);
    t25 = (t0 + 6968);
    t26 = 0;
    xsi_delete_subprogram_invocation(t24, t20, t0, t25, t26);
    t27 = (t0 + 8960);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    t30 = (t29 + 56U);
    t31 = *((char **)t30);
    memset(t31, 0, 8);
    t32 = 255U;
    t33 = t32;
    t34 = (t23 + 4);
    t35 = *((unsigned int *)t23);
    t32 = (t32 & t35);
    t36 = *((unsigned int *)t34);
    t33 = (t33 & t36);
    t37 = (t31 + 4);
    t38 = *((unsigned int *)t31);
    *((unsigned int *)t31) = (t38 | t32);
    t39 = *((unsigned int *)t37);
    *((unsigned int *)t37) = (t39 | t33);
    xsi_driver_vfirst_trans(t27, 0, 7);
    t40 = (t0 + 8736);
    *((int *)t40) = 1;

LAB1:    return;
LAB6:    t11 = (t0 + 7160U);
    *((char **)t11) = &&LAB4;
    goto LAB1;

}

static void Cont_82_2(char *t0)
{
    char t23[8];
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
    char *t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;

LAB0:    t1 = (t0 + 7408U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(83, ng0);
    t2 = (t0 + 2072U);
    t3 = *((char **)t2);
    t2 = (t0 + 1912U);
    t4 = *((char **)t2);
    t2 = (t0 + 2552U);
    t5 = *((char **)t2);
    t2 = (t0 + 7216);
    t6 = (t0 + 848);
    t7 = xsi_create_subprogram_invocation(t2, 0, t0, t6, 0, 0);
    t8 = (t0 + 4872);
    xsi_vlogvar_assign_value(t8, t3, 0, 0, 8);
    t9 = (t0 + 5032);
    xsi_vlogvar_assign_value(t9, t4, 0, 0, 8);
    t10 = (t0 + 5192);
    xsi_vlogvar_assign_value(t10, t5, 0, 0, 1);

LAB4:    t11 = (t0 + 7312);
    t12 = *((char **)t11);
    t13 = (t12 + 80U);
    t14 = *((char **)t13);
    t15 = (t14 + 272U);
    t16 = *((char **)t15);
    t17 = (t16 + 0U);
    t18 = *((char **)t17);
    t19 = ((int  (*)(char *, char *))t18)(t0, t12);
    if (t19 != 0)
        goto LAB6;

LAB5:    t12 = (t0 + 7312);
    t20 = *((char **)t12);
    t12 = (t0 + 5352);
    t21 = (t12 + 56U);
    t22 = *((char **)t21);
    memcpy(t23, t22, 8);
    t24 = (t0 + 848);
    t25 = (t0 + 7216);
    t26 = 0;
    xsi_delete_subprogram_invocation(t24, t20, t0, t25, t26);
    t27 = (t0 + 9024);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    t30 = (t29 + 56U);
    t31 = *((char **)t30);
    memset(t31, 0, 8);
    t32 = 255U;
    t33 = t32;
    t34 = (t23 + 4);
    t35 = *((unsigned int *)t23);
    t32 = (t32 & t35);
    t36 = *((unsigned int *)t34);
    t33 = (t33 & t36);
    t37 = (t31 + 4);
    t38 = *((unsigned int *)t31);
    *((unsigned int *)t31) = (t38 | t32);
    t39 = *((unsigned int *)t37);
    *((unsigned int *)t37) = (t39 | t33);
    xsi_driver_vfirst_trans(t27, 0, 7);
    t40 = (t0 + 8752);
    *((int *)t40) = 1;

LAB1:    return;
LAB6:    t11 = (t0 + 7408U);
    *((char **)t11) = &&LAB4;
    goto LAB1;

}

static void Cont_82_3(char *t0)
{
    char t23[8];
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
    char *t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;

LAB0:    t1 = (t0 + 7656U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(84, ng0);
    t2 = (t0 + 3192U);
    t3 = *((char **)t2);
    t2 = (t0 + 3672U);
    t4 = *((char **)t2);
    t2 = ((char*)((ng1)));
    t5 = (t0 + 7464);
    t6 = (t0 + 848);
    t7 = xsi_create_subprogram_invocation(t5, 0, t0, t6, 0, 0);
    t8 = (t0 + 4872);
    xsi_vlogvar_assign_value(t8, t3, 0, 0, 8);
    t9 = (t0 + 5032);
    xsi_vlogvar_assign_value(t9, t4, 0, 0, 8);
    t10 = (t0 + 5192);
    xsi_vlogvar_assign_value(t10, t2, 0, 0, 1);

LAB4:    t11 = (t0 + 7560);
    t12 = *((char **)t11);
    t13 = (t12 + 80U);
    t14 = *((char **)t13);
    t15 = (t14 + 272U);
    t16 = *((char **)t15);
    t17 = (t16 + 0U);
    t18 = *((char **)t17);
    t19 = ((int  (*)(char *, char *))t18)(t0, t12);
    if (t19 != 0)
        goto LAB6;

LAB5:    t12 = (t0 + 7560);
    t20 = *((char **)t12);
    t12 = (t0 + 5352);
    t21 = (t12 + 56U);
    t22 = *((char **)t21);
    memcpy(t23, t22, 8);
    t24 = (t0 + 848);
    t25 = (t0 + 7464);
    t26 = 0;
    xsi_delete_subprogram_invocation(t24, t20, t0, t25, t26);
    t27 = (t0 + 9088);
    t28 = (t27 + 56U);
    t29 = *((char **)t28);
    t30 = (t29 + 56U);
    t31 = *((char **)t30);
    memset(t31, 0, 8);
    t32 = 255U;
    t33 = t32;
    t34 = (t23 + 4);
    t35 = *((unsigned int *)t23);
    t32 = (t32 & t35);
    t36 = *((unsigned int *)t34);
    t33 = (t33 & t36);
    t37 = (t31 + 4);
    t38 = *((unsigned int *)t31);
    *((unsigned int *)t31) = (t38 | t32);
    t39 = *((unsigned int *)t37);
    *((unsigned int *)t37) = (t39 | t33);
    xsi_driver_vfirst_trans(t27, 0, 7);
    t40 = (t0 + 8768);
    *((int *)t40) = 1;

LAB1:    return;
LAB6:    t11 = (t0 + 7656U);
    *((char **)t11) = &&LAB4;
    goto LAB1;

}

static void Cont_82_4(char *t0)
{
    char t5[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    char *t18;

LAB0:    t1 = (t0 + 7904U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(86, ng0);
    t2 = (t0 + 3512U);
    t3 = *((char **)t2);
    t2 = (t0 + 3992U);
    t4 = *((char **)t2);
    memset(t5, 0, 8);
    xsi_vlog_unsigned_minus(t5, 8, t3, 8, t4, 8);
    t2 = (t0 + 9152);
    t6 = (t2 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memset(t9, 0, 8);
    t10 = 255U;
    t11 = t10;
    t12 = (t5 + 4);
    t13 = *((unsigned int *)t5);
    t10 = (t10 & t13);
    t14 = *((unsigned int *)t12);
    t11 = (t11 & t14);
    t15 = (t9 + 4);
    t16 = *((unsigned int *)t9);
    *((unsigned int *)t9) = (t16 | t10);
    t17 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t17 | t11);
    xsi_driver_vfirst_trans(t2, 0, 7);
    t18 = (t0 + 8784);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Cont_82_5(char *t0)
{
    char t6[8];
    char t25[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
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
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    int t21;
    char *t22;
    char *t23;
    char *t24;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t33;
    unsigned int t34;
    unsigned int t35;
    char *t36;
    unsigned int t37;
    unsigned int t38;
    char *t39;
    unsigned int t40;
    unsigned int t41;
    char *t42;

LAB0:    t1 = (t0 + 8152U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(87, ng0);
    t2 = (t0 + 3832U);
    t3 = *((char **)t2);
    t2 = (t0 + 1912U);
    t4 = *((char **)t2);
    t2 = (t0 + 4312U);
    t5 = *((char **)t2);
    memset(t6, 0, 8);
    xsi_vlog_unsigned_minus(t6, 8, t4, 8, t5, 8);
    t2 = ((char*)((ng1)));
    t7 = (t0 + 7960);
    t8 = (t0 + 848);
    t9 = xsi_create_subprogram_invocation(t7, 0, t0, t8, 0, 0);
    t10 = (t0 + 4872);
    xsi_vlogvar_assign_value(t10, t3, 0, 0, 8);
    t11 = (t0 + 5032);
    xsi_vlogvar_assign_value(t11, t6, 0, 0, 8);
    t12 = (t0 + 5192);
    xsi_vlogvar_assign_value(t12, t2, 0, 0, 1);

LAB4:    t13 = (t0 + 8056);
    t14 = *((char **)t13);
    t15 = (t14 + 80U);
    t16 = *((char **)t15);
    t17 = (t16 + 272U);
    t18 = *((char **)t17);
    t19 = (t18 + 0U);
    t20 = *((char **)t19);
    t21 = ((int  (*)(char *, char *))t20)(t0, t14);
    if (t21 != 0)
        goto LAB6;

LAB5:    t14 = (t0 + 8056);
    t22 = *((char **)t14);
    t14 = (t0 + 5352);
    t23 = (t14 + 56U);
    t24 = *((char **)t23);
    memcpy(t25, t24, 8);
    t26 = (t0 + 848);
    t27 = (t0 + 7960);
    t28 = 0;
    xsi_delete_subprogram_invocation(t26, t22, t0, t27, t28);
    t29 = (t0 + 9216);
    t30 = (t29 + 56U);
    t31 = *((char **)t30);
    t32 = (t31 + 56U);
    t33 = *((char **)t32);
    memset(t33, 0, 8);
    t34 = 255U;
    t35 = t34;
    t36 = (t25 + 4);
    t37 = *((unsigned int *)t25);
    t34 = (t34 & t37);
    t38 = *((unsigned int *)t36);
    t35 = (t35 & t38);
    t39 = (t33 + 4);
    t40 = *((unsigned int *)t33);
    *((unsigned int *)t33) = (t40 | t34);
    t41 = *((unsigned int *)t39);
    *((unsigned int *)t39) = (t41 | t35);
    xsi_driver_vfirst_trans(t29, 0, 7);
    t42 = (t0 + 8800);
    *((int *)t42) = 1;

LAB1:    return;
LAB6:    t13 = (t0 + 8152U);
    *((char **)t13) = &&LAB4;
    goto LAB1;

}

static void Cont_82_6(char *t0)
{
    char t5[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    char *t18;

LAB0:    t1 = (t0 + 8400U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(89, ng0);
    t2 = (t0 + 4312U);
    t3 = *((char **)t2);
    t2 = (t0 + 3352U);
    t4 = *((char **)t2);
    memset(t5, 0, 8);
    xsi_vlog_unsigned_add(t5, 8, t3, 8, t4, 8);
    t2 = (t0 + 9280);
    t6 = (t2 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memset(t9, 0, 8);
    t10 = 255U;
    t11 = t10;
    t12 = (t5 + 4);
    t13 = *((unsigned int *)t5);
    t10 = (t10 & t13);
    t14 = *((unsigned int *)t12);
    t11 = (t11 & t14);
    t15 = (t9 + 4);
    t16 = *((unsigned int *)t9);
    *((unsigned int *)t9) = (t16 | t10);
    t17 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t17 | t11);
    xsi_driver_vfirst_trans(t2, 0, 7);
    t18 = (t0 + 8816);
    *((int *)t18) = 1;

LAB1:    return;
}


extern void work_m_00000000003404880040_0704559786_init()
{
	static char *pe[] = {(void *)Cont_82_0,(void *)Cont_82_1,(void *)Cont_82_2,(void *)Cont_82_3,(void *)Cont_82_4,(void *)Cont_82_5,(void *)Cont_82_6};
	static char *se[] = {(void *)sp_minByte,(void *)sp_getLiving};
	xsi_register_didat("work_m_00000000003404880040_0704559786", "isim/NewCoreTB_isim_beh.exe.sim/work/m_00000000003404880040_0704559786.didat");
	xsi_register_executes(pe);
	xsi_register_subprogram_executes(se);
}
