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
extern char *STD_STANDARD;
extern char *IEEE_P_2592010699;

unsigned char ieee_p_2592010699_sub_1690584930_503743352(char *, unsigned char );


int work_p_2392574874_sub_1548306548_3353671955(char *t1, char *t2, char *t3)
{
    char t4[248];
    char t5[24];
    char t9[8];
    char t15[8];
    int t0;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t16;
    char *t17;
    char *t18;
    unsigned char t19;
    char *t20;
    int t21;
    char *t22;
    int t23;
    char *t24;
    int t25;
    char *t26;
    int t27;
    char *t28;
    int t29;
    char *t30;
    int t31;
    int t32;
    unsigned int t33;
    unsigned int t34;
    unsigned int t35;
    char *t36;
    unsigned char t37;
    unsigned char t38;
    int t39;
    char *t40;
    char *t41;
    int t42;
    int t43;
    int t44;
    int t45;
    int t46;
    int t47;
    int t48;

LAB0:    t6 = (t4 + 4U);
    t7 = ((STD_STANDARD) + 384);
    t8 = (t6 + 88U);
    *((char **)t8) = t7;
    t10 = (t6 + 56U);
    *((char **)t10) = t9;
    *((int *)t9) = 0;
    t11 = (t6 + 80U);
    *((unsigned int *)t11) = 4U;
    t12 = (t4 + 124U);
    t13 = ((STD_STANDARD) + 832);
    t14 = (t12 + 88U);
    *((char **)t14) = t13;
    t16 = (t12 + 56U);
    *((char **)t16) = t15;
    xsi_type_set_default_value(t13, t15, 0);
    t17 = (t12 + 80U);
    *((unsigned int *)t17) = 4U;
    t18 = (t5 + 4U);
    t19 = (t2 != 0);
    if (t19 == 1)
        goto LAB3;

LAB2:    t20 = (t5 + 12U);
    *((char **)t20) = t3;
    t22 = (t3 + 0U);
    t23 = *((int *)t22);
    t24 = (t3 + 4U);
    t25 = *((int *)t24);
    t26 = (t3 + 8U);
    t27 = *((int *)t26);
    if (t23 > t25)
        goto LAB7;

LAB8:    if (t27 == -1)
        goto LAB12;

LAB13:    t21 = t25;

LAB9:    t28 = (t3 + 0U);
    t29 = *((int *)t28);
    t30 = (t3 + 8U);
    t31 = *((int *)t30);
    t32 = (t21 - t29);
    t33 = (t32 * t31);
    t34 = (1U * t33);
    t35 = (0 + t34);
    t36 = (t2 + t35);
    t37 = *((unsigned char *)t36);
    t38 = (t37 == (unsigned char)3);
    if (t38 != 0)
        goto LAB4;

LAB6:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t7 = (t8 + 0);
    *((int *)t7) = 0;

LAB5:    t7 = (t3 + 0U);
    t23 = *((int *)t7);
    t8 = (t3 + 4U);
    t25 = *((int *)t8);
    t10 = (t3 + 8U);
    t27 = *((int *)t10);
    if (t23 > t25)
        goto LAB18;

LAB19:    if (t27 == -1)
        goto LAB23;

LAB24:    t21 = t23;

LAB20:    t11 = (t3 + 0U);
    t31 = *((int *)t11);
    t13 = (t3 + 4U);
    t32 = *((int *)t13);
    t14 = (t3 + 8U);
    t39 = *((int *)t14);
    if (t31 > t32)
        goto LAB25;

LAB26:    if (t39 == -1)
        goto LAB30;

LAB31:    t29 = t32;

LAB27:    t42 = (t29 - 1);
    t43 = t42;
    t44 = t21;

LAB14:    if (t43 >= t44)
        goto LAB15;

LAB17:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t21 = *((int *)t8);
    t0 = t21;

LAB1:    return t0;
LAB3:    *((char **)t18) = t2;
    goto LAB2;

LAB4:    t39 = (-(1));
    t40 = (t6 + 56U);
    t41 = *((char **)t40);
    t40 = (t41 + 0);
    *((int *)t40) = t39;
    goto LAB5;

LAB7:    if (t27 == 1)
        goto LAB10;

LAB11:    t21 = t23;
    goto LAB9;

LAB10:    t21 = t25;
    goto LAB9;

LAB12:    t21 = t23;
    goto LAB9;

LAB15:    t16 = (t3 + 0U);
    t45 = *((int *)t16);
    t17 = (t3 + 8U);
    t46 = *((int *)t17);
    t47 = (t43 - t45);
    t33 = (t47 * t46);
    t22 = (t3 + 4U);
    t48 = *((int *)t22);
    xsi_vhdl_check_range_of_index(t45, t48, t46, t43);
    t34 = (1U * t33);
    t35 = (0 + t34);
    t24 = (t2 + t35);
    t19 = *((unsigned char *)t24);
    t37 = (t19 == (unsigned char)3);
    if (t37 != 0)
        goto LAB32;

LAB34:    t7 = (t12 + 56U);
    t8 = *((char **)t7);
    t7 = (t8 + 0);
    *((int *)t7) = 0;

LAB33:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t21 = *((int *)t8);
    t23 = (2 * t21);
    t7 = (t12 + 56U);
    t10 = *((char **)t7);
    t25 = *((int *)t10);
    t27 = (t23 + t25);
    t7 = (t6 + 56U);
    t11 = *((char **)t7);
    t7 = (t11 + 0);
    *((int *)t7) = t27;

LAB16:    if (t43 == t44)
        goto LAB17;

LAB35:    t21 = (t43 + -1);
    t43 = t21;
    goto LAB14;

LAB18:    if (t27 == 1)
        goto LAB21;

LAB22:    t21 = t25;
    goto LAB20;

LAB21:    t21 = t23;
    goto LAB20;

LAB23:    t21 = t25;
    goto LAB20;

LAB25:    if (t39 == 1)
        goto LAB28;

LAB29:    t29 = t31;
    goto LAB27;

LAB28:    t29 = t32;
    goto LAB27;

LAB30:    t29 = t31;
    goto LAB27;

LAB32:    t26 = (t12 + 56U);
    t28 = *((char **)t26);
    t26 = (t28 + 0);
    *((int *)t26) = 1;
    goto LAB33;

LAB36:;
}

int work_p_2392574874_sub_492870414_3353671955(char *t1, char *t2, char *t3)
{
    char t4[248];
    char t5[24];
    char t9[8];
    char t15[8];
    int t0;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t16;
    char *t17;
    char *t18;
    unsigned char t19;
    char *t20;
    int t21;
    char *t22;
    int t23;
    char *t24;
    int t25;
    char *t26;
    int t27;
    int t28;
    char *t29;
    int t30;
    char *t31;
    int t32;
    char *t33;
    int t34;
    int t35;
    int t36;
    char *t37;
    int t38;
    char *t39;
    int t40;
    int t41;
    unsigned int t42;
    char *t43;
    int t44;
    unsigned int t45;
    unsigned int t46;
    char *t47;
    unsigned char t48;
    unsigned char t49;
    char *t50;
    char *t51;

LAB0:    t6 = (t4 + 4U);
    t7 = ((STD_STANDARD) + 832);
    t8 = (t6 + 88U);
    *((char **)t8) = t7;
    t10 = (t6 + 56U);
    *((char **)t10) = t9;
    *((int *)t9) = 0;
    t11 = (t6 + 80U);
    *((unsigned int *)t11) = 4U;
    t12 = (t4 + 124U);
    t13 = ((STD_STANDARD) + 832);
    t14 = (t12 + 88U);
    *((char **)t14) = t13;
    t16 = (t12 + 56U);
    *((char **)t16) = t15;
    xsi_type_set_default_value(t13, t15, 0);
    t17 = (t12 + 80U);
    *((unsigned int *)t17) = 4U;
    t18 = (t5 + 4U);
    t19 = (t2 != 0);
    if (t19 == 1)
        goto LAB3;

LAB2:    t20 = (t5 + 12U);
    *((char **)t20) = t3;
    t22 = (t3 + 0U);
    t23 = *((int *)t22);
    t24 = (t3 + 4U);
    t25 = *((int *)t24);
    t26 = (t3 + 8U);
    t27 = *((int *)t26);
    if (t23 > t25)
        goto LAB8;

LAB9:    if (t27 == -1)
        goto LAB13;

LAB14:    t21 = t23;

LAB10:    t29 = (t3 + 0U);
    t30 = *((int *)t29);
    t31 = (t3 + 4U);
    t32 = *((int *)t31);
    t33 = (t3 + 8U);
    t34 = *((int *)t33);
    if (t30 > t32)
        goto LAB15;

LAB16:    if (t34 == -1)
        goto LAB20;

LAB21:    t28 = t32;

LAB17:    t35 = t28;
    t36 = t21;

LAB4:    if (t35 >= t36)
        goto LAB5;

LAB7:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t21 = *((int *)t8);
    t0 = t21;

LAB1:    return t0;
LAB3:    *((char **)t18) = t2;
    goto LAB2;

LAB5:    t37 = (t3 + 0U);
    t38 = *((int *)t37);
    t39 = (t3 + 8U);
    t40 = *((int *)t39);
    t41 = (t35 - t38);
    t42 = (t41 * t40);
    t43 = (t3 + 4U);
    t44 = *((int *)t43);
    xsi_vhdl_check_range_of_index(t38, t44, t40, t35);
    t45 = (1U * t42);
    t46 = (0 + t45);
    t47 = (t2 + t46);
    t48 = *((unsigned char *)t47);
    t49 = (t48 == (unsigned char)3);
    if (t49 != 0)
        goto LAB22;

LAB24:    t7 = (t12 + 56U);
    t8 = *((char **)t7);
    t7 = (t8 + 0);
    *((int *)t7) = 0;

LAB23:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t21 = *((int *)t8);
    t23 = (2 * t21);
    t7 = (t12 + 56U);
    t10 = *((char **)t7);
    t25 = *((int *)t10);
    t27 = (t23 + t25);
    t7 = (t6 + 56U);
    t11 = *((char **)t7);
    t7 = (t11 + 0);
    *((int *)t7) = t27;

LAB6:    if (t35 == t36)
        goto LAB7;

LAB25:    t21 = (t35 + -1);
    t35 = t21;
    goto LAB4;

LAB8:    if (t27 == 1)
        goto LAB11;

LAB12:    t21 = t25;
    goto LAB10;

LAB11:    t21 = t23;
    goto LAB10;

LAB13:    t21 = t25;
    goto LAB10;

LAB15:    if (t34 == 1)
        goto LAB18;

LAB19:    t28 = t30;
    goto LAB17;

LAB18:    t28 = t32;
    goto LAB17;

LAB20:    t28 = t30;
    goto LAB17;

LAB22:    t50 = (t12 + 56U);
    t51 = *((char **)t50);
    t50 = (t51 + 0);
    *((int *)t50) = 1;
    goto LAB23;

LAB26:;
}

char *work_p_2392574874_sub_2849945851_3353671955(char *t1, char *t2, int t3, int t4)
{
    char t5[248];
    char t6[16];
    char t10[16];
    char t25[8];
    char *t0;
    int t7;
    int t8;
    unsigned int t9;
    int t11;
    char *t12;
    char *t13;
    int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    int t31;
    int t32;
    int t33;
    char *t34;
    char *t35;
    int t36;
    int t37;
    unsigned char t38;
    char *t39;
    int t40;
    char *t41;
    int t42;
    int t43;
    char *t44;
    int t45;
    unsigned int t46;
    unsigned int t47;
    char *t48;
    unsigned char t49;

LAB0:    t7 = (t4 - 1);
    t8 = (0 - t7);
    t9 = (t8 * -1);
    t9 = (t9 + 1);
    t9 = (t9 * 1U);
    t11 = (t4 - 1);
    t12 = (t10 + 0U);
    t13 = (t12 + 0U);
    *((int *)t13) = t11;
    t13 = (t12 + 4U);
    *((int *)t13) = 0;
    t13 = (t12 + 8U);
    *((int *)t13) = -1;
    t14 = (0 - t11);
    t15 = (t14 * -1);
    t15 = (t15 + 1);
    t13 = (t12 + 12U);
    *((unsigned int *)t13) = t15;
    t13 = (t5 + 4U);
    t16 = ((IEEE_P_2592010699) + 4024);
    t17 = (t13 + 88U);
    *((char **)t17) = t16;
    t18 = (char *)alloca(t9);
    t19 = (t13 + 56U);
    *((char **)t19) = t18;
    xsi_type_set_default_value(t16, t18, t10);
    t20 = (t13 + 64U);
    *((char **)t20) = t10;
    t21 = (t13 + 80U);
    *((unsigned int *)t21) = t9;
    t22 = (t5 + 124U);
    t23 = ((STD_STANDARD) + 832);
    t24 = (t22 + 88U);
    *((char **)t24) = t23;
    t26 = (t22 + 56U);
    *((char **)t26) = t25;
    *((int *)t25) = t3;
    t27 = (t22 + 80U);
    *((unsigned int *)t27) = 4U;
    t28 = (t6 + 4U);
    *((int *)t28) = t3;
    t29 = (t6 + 8U);
    *((int *)t29) = t4;
    t30 = (t10 + 0U);
    t31 = *((int *)t30);
    t32 = 0;
    t33 = t31;

LAB2:    if (t32 <= t33)
        goto LAB3;

LAB5:    t12 = (t22 + 56U);
    t16 = *((char **)t12);
    t7 = *((int *)t16);
    t38 = (t7 == 0);
    t49 = (!(t38));
    if (t49 != 0)
        goto LAB10;

LAB12:
LAB11:    t12 = (t13 + 56U);
    t16 = *((char **)t12);
    t12 = (t10 + 12U);
    t9 = *((unsigned int *)t12);
    t9 = (t9 * 1U);
    t0 = xsi_get_transient_memory(t9);
    memcpy(t0, t16, t9);
    t17 = (t10 + 0U);
    t7 = *((int *)t17);
    t19 = (t10 + 4U);
    t8 = *((int *)t19);
    t20 = (t10 + 8U);
    t11 = *((int *)t20);
    t21 = (t2 + 0U);
    t23 = (t21 + 0U);
    *((int *)t23) = t7;
    t23 = (t21 + 4U);
    *((int *)t23) = t8;
    t23 = (t21 + 8U);
    *((int *)t23) = t11;
    t14 = (t8 - t7);
    t15 = (t14 * t11);
    t15 = (t15 + 1);
    t23 = (t21 + 12U);
    *((unsigned int *)t23) = t15;

LAB1:    return t0;
LAB3:    t34 = (t22 + 56U);
    t35 = *((char **)t34);
    t36 = *((int *)t35);
    t37 = xsi_vhdl_mod(t36, 2);
    t38 = (t37 == 0);
    if (t38 != 0)
        goto LAB6;

LAB8:    t12 = (t13 + 56U);
    t16 = *((char **)t12);
    t12 = (t10 + 0U);
    t7 = *((int *)t12);
    t17 = (t10 + 8U);
    t8 = *((int *)t17);
    t11 = (t32 - t7);
    t9 = (t11 * t8);
    t19 = (t10 + 4U);
    t14 = *((int *)t19);
    xsi_vhdl_check_range_of_index(t7, t14, t8, t32);
    t15 = (1U * t9);
    t46 = (0 + t15);
    t20 = (t16 + t46);
    *((unsigned char *)t20) = (unsigned char)3;

LAB7:    t12 = (t22 + 56U);
    t16 = *((char **)t12);
    t7 = *((int *)t16);
    t8 = (t7 / 2);
    t12 = (t22 + 56U);
    t17 = *((char **)t12);
    t12 = (t17 + 0);
    *((int *)t12) = t8;

LAB4:    if (t32 == t33)
        goto LAB5;

LAB9:    t7 = (t32 + 1);
    t32 = t7;
    goto LAB2;

LAB6:    t34 = (t13 + 56U);
    t39 = *((char **)t34);
    t34 = (t10 + 0U);
    t40 = *((int *)t34);
    t41 = (t10 + 8U);
    t42 = *((int *)t41);
    t43 = (t32 - t40);
    t15 = (t43 * t42);
    t44 = (t10 + 4U);
    t45 = *((int *)t44);
    xsi_vhdl_check_range_of_index(t40, t45, t42, t32);
    t46 = (1U * t15);
    t47 = (0 + t46);
    t48 = (t39 + t47);
    *((unsigned char *)t48) = (unsigned char)2;
    goto LAB7;

LAB10:    goto LAB11;

LAB13:;
}

char *work_p_2392574874_sub_452662619_3353671955(char *t1, char *t2, int t3, int t4)
{
    char t5[368];
    char t6[16];
    char t10[16];
    char t25[8];
    char t31[8];
    char *t0;
    int t7;
    int t8;
    unsigned int t9;
    int t11;
    char *t12;
    char *t13;
    int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    unsigned char t36;
    char *t37;
    char *t38;
    int t39;
    unsigned char t40;
    int t41;
    int t42;
    int t43;
    int t44;
    unsigned int t45;
    unsigned char t46;
    unsigned char t47;
    unsigned char t48;

LAB0:    t7 = (t4 - 1);
    t8 = (0 - t7);
    t9 = (t8 * -1);
    t9 = (t9 + 1);
    t9 = (t9 * 1U);
    t11 = (t4 - 1);
    t12 = (t10 + 0U);
    t13 = (t12 + 0U);
    *((int *)t13) = t11;
    t13 = (t12 + 4U);
    *((int *)t13) = 0;
    t13 = (t12 + 8U);
    *((int *)t13) = -1;
    t14 = (0 - t11);
    t15 = (t14 * -1);
    t15 = (t15 + 1);
    t13 = (t12 + 12U);
    *((unsigned int *)t13) = t15;
    t13 = (t5 + 4U);
    t16 = ((IEEE_P_2592010699) + 4024);
    t17 = (t13 + 88U);
    *((char **)t17) = t16;
    t18 = (char *)alloca(t9);
    t19 = (t13 + 56U);
    *((char **)t19) = t18;
    xsi_type_set_default_value(t16, t18, t10);
    t20 = (t13 + 64U);
    *((char **)t20) = t10;
    t21 = (t13 + 80U);
    *((unsigned int *)t21) = t9;
    t22 = (t5 + 124U);
    t23 = ((IEEE_P_2592010699) + 3320);
    t24 = (t22 + 88U);
    *((char **)t24) = t23;
    t26 = (t22 + 56U);
    *((char **)t26) = t25;
    *((unsigned char *)t25) = (unsigned char)2;
    t27 = (t22 + 80U);
    *((unsigned int *)t27) = 1U;
    t28 = (t5 + 244U);
    t29 = ((STD_STANDARD) + 384);
    t30 = (t28 + 88U);
    *((char **)t30) = t29;
    t32 = (t28 + 56U);
    *((char **)t32) = t31;
    *((int *)t31) = t3;
    t33 = (t28 + 80U);
    *((unsigned int *)t33) = 4U;
    t34 = (t6 + 4U);
    *((int *)t34) = t3;
    t35 = (t6 + 8U);
    *((int *)t35) = t4;
    t36 = (t3 < 0);
    if (t36 != 0)
        goto LAB2;

LAB4:
LAB3:    t12 = (t10 + 0U);
    t7 = *((int *)t12);
    t8 = 0;
    t11 = t7;

LAB5:    if (t8 <= t11)
        goto LAB6;

LAB8:    t12 = (t28 + 56U);
    t16 = *((char **)t12);
    t7 = *((int *)t16);
    t40 = (t7 != 0);
    if (t40 == 1)
        goto LAB16;

LAB17:    t12 = (t22 + 56U);
    t17 = *((char **)t12);
    t46 = *((unsigned char *)t17);
    t12 = (t13 + 56U);
    t19 = *((char **)t12);
    t12 = (t10 + 0U);
    t8 = *((int *)t12);
    t20 = (t10 + 0U);
    t11 = *((int *)t20);
    t21 = (t10 + 8U);
    t14 = *((int *)t21);
    t39 = (t8 - t11);
    t9 = (t39 * t14);
    t15 = (1U * t9);
    t45 = (0 + t15);
    t23 = (t19 + t45);
    t47 = *((unsigned char *)t23);
    t48 = (t46 != t47);
    t36 = t48;

LAB18:    if (t36 != 0)
        goto LAB13;

LAB15:
LAB14:    t12 = (t13 + 56U);
    t16 = *((char **)t12);
    t12 = (t10 + 12U);
    t9 = *((unsigned int *)t12);
    t9 = (t9 * 1U);
    t0 = xsi_get_transient_memory(t9);
    memcpy(t0, t16, t9);
    t17 = (t10 + 0U);
    t7 = *((int *)t17);
    t19 = (t10 + 4U);
    t8 = *((int *)t19);
    t20 = (t10 + 8U);
    t11 = *((int *)t20);
    t21 = (t2 + 0U);
    t23 = (t21 + 0U);
    *((int *)t23) = t7;
    t23 = (t21 + 4U);
    *((int *)t23) = t8;
    t23 = (t21 + 8U);
    *((int *)t23) = t11;
    t14 = (t8 - t7);
    t15 = (t14 * t11);
    t15 = (t15 + 1);
    t23 = (t21 + 12U);
    *((unsigned int *)t23) = t15;

LAB1:    return t0;
LAB2:    t37 = (t22 + 56U);
    t38 = *((char **)t37);
    t37 = (t38 + 0);
    *((unsigned char *)t37) = (unsigned char)3;
    t7 = (t3 + 1);
    t8 = (-(t7));
    t12 = (t28 + 56U);
    t16 = *((char **)t12);
    t12 = (t16 + 0);
    *((int *)t12) = t8;
    goto LAB3;

LAB6:    t16 = (t28 + 56U);
    t17 = *((char **)t16);
    t14 = *((int *)t17);
    t39 = xsi_vhdl_mod(t14, 2);
    t36 = (t39 == 0);
    if (t36 != 0)
        goto LAB9;

LAB11:    t12 = (t22 + 56U);
    t16 = *((char **)t12);
    t36 = *((unsigned char *)t16);
    t40 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t36);
    t12 = (t13 + 56U);
    t17 = *((char **)t12);
    t12 = (t10 + 0U);
    t7 = *((int *)t12);
    t19 = (t10 + 8U);
    t14 = *((int *)t19);
    t39 = (t8 - t7);
    t9 = (t39 * t14);
    t20 = (t10 + 4U);
    t41 = *((int *)t20);
    xsi_vhdl_check_range_of_index(t7, t41, t14, t8);
    t15 = (1U * t9);
    t45 = (0 + t15);
    t21 = (t17 + t45);
    *((unsigned char *)t21) = t40;

LAB10:    t12 = (t28 + 56U);
    t16 = *((char **)t12);
    t7 = *((int *)t16);
    t14 = (t7 / 2);
    t12 = (t28 + 56U);
    t17 = *((char **)t12);
    t12 = (t17 + 0);
    *((int *)t12) = t14;

LAB7:    if (t8 == t11)
        goto LAB8;

LAB12:    t7 = (t8 + 1);
    t8 = t7;
    goto LAB5;

LAB9:    t16 = (t22 + 56U);
    t19 = *((char **)t16);
    t40 = *((unsigned char *)t19);
    t16 = (t13 + 56U);
    t20 = *((char **)t16);
    t16 = (t10 + 0U);
    t41 = *((int *)t16);
    t21 = (t10 + 8U);
    t42 = *((int *)t21);
    t43 = (t8 - t41);
    t9 = (t43 * t42);
    t23 = (t10 + 4U);
    t44 = *((int *)t23);
    xsi_vhdl_check_range_of_index(t41, t44, t42, t8);
    t15 = (1U * t9);
    t45 = (0 + t15);
    t24 = (t20 + t45);
    *((unsigned char *)t24) = t40;
    goto LAB10;

LAB13:    goto LAB14;

LAB16:    t36 = (unsigned char)1;
    goto LAB18;

LAB19:;
}

char *work_p_2392574874_sub_805424436_3353671955(char *t1, char *t2, int t3, int t4)
{
    char t5[488];
    char t6[16];
    char t10[8];
    char t16[16];
    char t30[16];
    char t45[8];
    char t50[16];
    char *t0;
    char *t7;
    char *t8;
    char *t9;
    char *t11;
    char *t12;
    int t13;
    int t14;
    unsigned int t15;
    int t17;
    char *t18;
    char *t19;
    int t20;
    unsigned int t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    int t28;
    int t29;
    int t31;
    char *t32;
    char *t33;
    int t34;
    unsigned int t35;
    char *t36;
    char *t37;
    char *t38;
    char *t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    char *t44;
    char *t46;
    char *t47;
    char *t48;
    char *t49;
    char *t51;
    char *t52;
    char *t53;
    int t54;
    char *t55;
    int t56;
    char *t57;
    int t58;
    char *t59;
    char *t60;
    int t61;
    unsigned int t62;

LAB0:    t7 = (t5 + 4U);
    t8 = ((STD_STANDARD) + 384);
    t9 = (t7 + 88U);
    *((char **)t9) = t8;
    t11 = (t7 + 56U);
    *((char **)t11) = t10;
    *((int *)t10) = t3;
    t12 = (t7 + 80U);
    *((unsigned int *)t12) = 4U;
    t13 = (t4 - 1);
    t14 = (0 - t13);
    t15 = (t14 * -1);
    t15 = (t15 + 1);
    t15 = (t15 * 1U);
    t17 = (t4 - 1);
    t18 = (t16 + 0U);
    t19 = (t18 + 0U);
    *((int *)t19) = t17;
    t19 = (t18 + 4U);
    *((int *)t19) = 0;
    t19 = (t18 + 8U);
    *((int *)t19) = -1;
    t20 = (0 - t17);
    t21 = (t20 * -1);
    t21 = (t21 + 1);
    t19 = (t18 + 12U);
    *((unsigned int *)t19) = t21;
    t19 = (t5 + 124U);
    t22 = ((IEEE_P_2592010699) + 4024);
    t23 = (t19 + 88U);
    *((char **)t23) = t22;
    t24 = (char *)alloca(t15);
    t25 = (t19 + 56U);
    *((char **)t25) = t24;
    xsi_type_set_default_value(t22, t24, t16);
    t26 = (t19 + 64U);
    *((char **)t26) = t16;
    t27 = (t19 + 80U);
    *((unsigned int *)t27) = t15;
    t28 = (t4 - 1);
    t29 = (0 - t28);
    t21 = (t29 * -1);
    t21 = (t21 + 1);
    t21 = (t21 * 1U);
    t31 = (t4 - 1);
    t32 = (t30 + 0U);
    t33 = (t32 + 0U);
    *((int *)t33) = t31;
    t33 = (t32 + 4U);
    *((int *)t33) = 0;
    t33 = (t32 + 8U);
    *((int *)t33) = -1;
    t34 = (0 - t31);
    t35 = (t34 * -1);
    t35 = (t35 + 1);
    t33 = (t32 + 12U);
    *((unsigned int *)t33) = t35;
    t33 = (t5 + 244U);
    t36 = ((IEEE_P_2592010699) + 4024);
    t37 = (t33 + 88U);
    *((char **)t37) = t36;
    t38 = (char *)alloca(t21);
    t39 = (t33 + 56U);
    *((char **)t39) = t38;
    xsi_type_set_default_value(t36, t38, t30);
    t40 = (t33 + 64U);
    *((char **)t40) = t30;
    t41 = (t33 + 80U);
    *((unsigned int *)t41) = t21;
    t42 = (t5 + 364U);
    t43 = ((STD_STANDARD) + 832);
    t44 = (t42 + 88U);
    *((char **)t44) = t43;
    t46 = (t42 + 56U);
    *((char **)t46) = t45;
    xsi_type_set_default_value(t43, t45, 0);
    t47 = (t42 + 80U);
    *((unsigned int *)t47) = 4U;
    t48 = (t6 + 4U);
    *((int *)t48) = t3;
    t49 = (t6 + 8U);
    *((int *)t49) = t4;
    t51 = work_p_2392574874_sub_452662619_3353671955(t1, t50, t3, t4);
    t52 = (t50 + 12U);
    t35 = *((unsigned int *)t52);
    t35 = (t35 * 1U);
    t0 = xsi_get_transient_memory(t35);
    memcpy(t0, t51, t35);
    t53 = (t50 + 0U);
    t54 = *((int *)t53);
    t55 = (t50 + 4U);
    t56 = *((int *)t55);
    t57 = (t50 + 8U);
    t58 = *((int *)t57);
    t59 = (t2 + 0U);
    t60 = (t59 + 0U);
    *((int *)t60) = t54;
    t60 = (t59 + 4U);
    *((int *)t60) = t56;
    t60 = (t59 + 8U);
    *((int *)t60) = t58;
    t61 = (t56 - t54);
    t62 = (t61 * t58);
    t62 = (t62 + 1);
    t60 = (t59 + 12U);
    *((unsigned int *)t60) = t62;

LAB1:    return t0;
LAB2:;
}


void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

extern void work_p_2392574874_init()
{
	static char *se[] = {(void *)work_p_2392574874_sub_1548306548_3353671955,(void *)work_p_2392574874_sub_492870414_3353671955,(void *)work_p_2392574874_sub_2849945851_3353671955,(void *)work_p_2392574874_sub_452662619_3353671955,(void *)work_p_2392574874_sub_805424436_3353671955};
	xsi_register_didat("work_p_2392574874", "isim/NewCoreTB_isim_beh.exe.sim/work/p_2392574874.didat");
	xsi_register_subprogram_executes(se);
	xsi_register_resolution_function(1, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(2, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(3, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(4, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(5, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(6, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(7, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(8, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(9, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
	xsi_register_resolution_function(10, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 3);
}
