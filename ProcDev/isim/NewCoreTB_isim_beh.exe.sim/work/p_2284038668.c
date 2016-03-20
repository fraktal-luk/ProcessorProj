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



int work_p_2284038668_sub_1279250441_2077180020(char *t1, char *t2, char *t3)
{
    char t4[128];
    char t5[24];
    char t9[8];
    int t0;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    char *t11;
    char *t12;
    unsigned char t13;
    char *t14;
    char *t15;
    int t16;
    char *t17;
    int t18;
    char *t19;
    int t20;
    int t21;
    int t22;
    int t23;
    int t24;
    char *t25;
    int t26;
    char *t27;
    int t28;
    int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned char t34;
    unsigned char t35;
    char *t36;
    char *t37;
    int t38;
    int t39;
    char *t40;

LAB0:    t6 = (t4 + 4U);
    t7 = ((STD_STANDARD) + 832);
    t8 = (t6 + 88U);
    *((char **)t8) = t7;
    t10 = (t6 + 56U);
    *((char **)t10) = t9;
    *((int *)t9) = 0;
    t11 = (t6 + 80U);
    *((unsigned int *)t11) = 4U;
    t12 = (t5 + 4U);
    t13 = (t2 != 0);
    if (t13 == 1)
        goto LAB3;

LAB2:    t14 = (t5 + 12U);
    *((char **)t14) = t3;
    t15 = (t3 + 8U);
    t16 = *((int *)t15);
    t17 = (t3 + 4U);
    t18 = *((int *)t17);
    t19 = (t3 + 0U);
    t20 = *((int *)t19);
    t21 = t20;
    t22 = t18;

LAB4:    t23 = (t22 * t16);
    t24 = (t21 * t16);
    if (t24 <= t23)
        goto LAB5;

LAB7:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t16 = *((int *)t8);
    t0 = t16;

LAB1:    return t0;
LAB3:    *((char **)t12) = t2;
    goto LAB2;

LAB5:    t25 = (t3 + 0U);
    t26 = *((int *)t25);
    t27 = (t3 + 8U);
    t28 = *((int *)t27);
    t29 = (t21 - t26);
    t30 = (t29 * t28);
    t31 = (1U * t30);
    t32 = (0 + t31);
    t33 = (t2 + t32);
    t34 = *((unsigned char *)t33);
    t35 = (t34 == (unsigned char)3);
    if (t35 != 0)
        goto LAB8;

LAB10:
LAB9:
LAB6:    if (t21 == t22)
        goto LAB7;

LAB11:    t18 = (t21 + t16);
    t21 = t18;
    goto LAB4;

LAB8:    t36 = (t6 + 56U);
    t37 = *((char **)t36);
    t38 = *((int *)t37);
    t39 = (t38 + 1);
    t36 = (t6 + 56U);
    t40 = *((char **)t36);
    t36 = (t40 + 0);
    *((int *)t36) = t39;
    goto LAB9;

LAB12:;
}

char *work_p_2284038668_sub_2592118765_2077180020(char *t1, char *t2, char *t3, char *t4, int t5)
{
    char t6[248];
    char t7[24];
    char t14[16];
    char t34[8];
    char *t0;
    char *t8;
    unsigned int t9;
    char *t10;
    char *t11;
    char *t12;
    unsigned int t13;
    char *t15;
    int t16;
    char *t17;
    int t18;
    char *t19;
    int t20;
    char *t21;
    char *t22;
    int t23;
    unsigned int t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t33;
    char *t35;
    char *t36;
    char *t37;
    unsigned char t38;
    char *t39;
    char *t40;
    char *t41;
    unsigned char t42;
    char *t43;
    char *t44;
    unsigned int t45;
    char *t46;
    int t47;
    char *t48;
    int t49;
    char *t50;
    int t51;
    char *t52;
    char *t53;
    int t54;
    unsigned int t55;

LAB0:    t8 = (t4 + 12U);
    t9 = *((unsigned int *)t8);
    t9 = (t9 * 1U);
    t10 = xsi_get_transient_memory(t9);
    memset(t10, 0, t9);
    t11 = t10;
    memset(t11, (unsigned char)2, t9);
    t12 = (t4 + 12U);
    t13 = *((unsigned int *)t12);
    t13 = (t13 * 1U);
    t15 = (t4 + 0U);
    t16 = *((int *)t15);
    t17 = (t4 + 4U);
    t18 = *((int *)t17);
    t19 = (t4 + 8U);
    t20 = *((int *)t19);
    t21 = (t14 + 0U);
    t22 = (t21 + 0U);
    *((int *)t22) = t16;
    t22 = (t21 + 4U);
    *((int *)t22) = t18;
    t22 = (t21 + 8U);
    *((int *)t22) = t20;
    t23 = (t18 - t16);
    t24 = (t23 * t20);
    t24 = (t24 + 1);
    t22 = (t21 + 12U);
    *((unsigned int *)t22) = t24;
    t22 = (t6 + 4U);
    t25 = ((IEEE_P_2592010699) + 4024);
    t26 = (t22 + 88U);
    *((char **)t26) = t25;
    t27 = (char *)alloca(t13);
    t28 = (t22 + 56U);
    *((char **)t28) = t27;
    memcpy(t27, t10, t13);
    t29 = (t22 + 64U);
    *((char **)t29) = t14;
    t30 = (t22 + 80U);
    *((unsigned int *)t30) = t13;
    t31 = (t6 + 124U);
    t32 = ((STD_STANDARD) + 832);
    t33 = (t31 + 88U);
    *((char **)t33) = t32;
    t35 = (t31 + 56U);
    *((char **)t35) = t34;
    *((int *)t34) = t5;
    t36 = (t31 + 80U);
    *((unsigned int *)t36) = 4U;
    t37 = (t7 + 4U);
    t38 = (t3 != 0);
    if (t38 == 1)
        goto LAB3;

LAB2:    t39 = (t7 + 12U);
    *((char **)t39) = t4;
    t40 = (t7 + 20U);
    *((int *)t40) = t5;
    t41 = (t4 + 12U);
    t24 = *((unsigned int *)t41);
    t42 = (t5 > t24);
    if (t42 != 0)
        goto LAB4;

LAB6:
LAB5:    t8 = (t4 + 8U);
    t16 = *((int *)t8);
    t10 = (t4 + 4U);
    t18 = *((int *)t10);
    t11 = (t4 + 0U);
    t20 = *((int *)t11);
    t23 = t20;
    t47 = t18;

LAB8:    t49 = (t47 * t16);
    t51 = (t23 * t16);
    if (t51 <= t49)
        goto LAB9;

LAB11:    t8 = (t22 + 56U);
    t10 = *((char **)t8);
    t8 = (t14 + 12U);
    t9 = *((unsigned int *)t8);
    t9 = (t9 * 1U);
    t0 = xsi_get_transient_memory(t9);
    memcpy(t0, t10, t9);
    t11 = (t14 + 0U);
    t16 = *((int *)t11);
    t12 = (t14 + 4U);
    t18 = *((int *)t12);
    t15 = (t14 + 8U);
    t20 = *((int *)t15);
    t17 = (t2 + 0U);
    t19 = (t17 + 0U);
    *((int *)t19) = t16;
    t19 = (t17 + 4U);
    *((int *)t19) = t18;
    t19 = (t17 + 8U);
    *((int *)t19) = t20;
    t23 = (t18 - t16);
    t13 = (t23 * t20);
    t13 = (t13 + 1);
    t19 = (t17 + 12U);
    *((unsigned int *)t19) = t13;

LAB1:    return t0;
LAB3:    *((char **)t37) = t3;
    goto LAB2;

LAB4:    t43 = (t22 + 56U);
    t44 = *((char **)t43);
    t43 = (t14 + 12U);
    t45 = *((unsigned int *)t43);
    t45 = (t45 * 1U);
    t0 = xsi_get_transient_memory(t45);
    memcpy(t0, t44, t45);
    t46 = (t14 + 0U);
    t47 = *((int *)t46);
    t48 = (t14 + 4U);
    t49 = *((int *)t48);
    t50 = (t14 + 8U);
    t51 = *((int *)t50);
    t52 = (t2 + 0U);
    t53 = (t52 + 0U);
    *((int *)t53) = t47;
    t53 = (t52 + 4U);
    *((int *)t53) = t49;
    t53 = (t52 + 8U);
    *((int *)t53) = t51;
    t54 = (t49 - t47);
    t55 = (t54 * t51);
    t55 = (t55 + 1);
    t53 = (t52 + 12U);
    *((unsigned int *)t53) = t55;
    goto LAB1;

LAB7:    goto LAB5;

LAB9:    t38 = (t23 >= t5);
    if (t38 != 0)
        goto LAB12;

LAB14:
LAB13:    t8 = (t22 + 56U);
    t10 = *((char **)t8);
    t8 = (t14 + 0U);
    t18 = *((int *)t8);
    t11 = (t14 + 8U);
    t20 = *((int *)t11);
    t49 = (t23 - t18);
    t9 = (t49 * t20);
    t12 = (t14 + 4U);
    t51 = *((int *)t12);
    xsi_vhdl_check_range_of_index(t18, t51, t20, t23);
    t13 = (1U * t9);
    t24 = (0 + t13);
    t15 = (t10 + t24);
    *((unsigned char *)t15) = (unsigned char)3;

LAB10:    if (t23 == t47)
        goto LAB11;

LAB16:    t18 = (t23 + t16);
    t23 = t18;
    goto LAB8;

LAB12:    goto LAB11;

LAB15:    goto LAB13;

LAB17:;
}

char *work_p_2284038668_sub_2398579266_2077180020(char *t1, char *t2, char *t3, char *t4)
{
    char t5[368];
    char t6[24];
    char t13[16];
    char t33[8];
    char t39[8];
    char *t0;
    char *t7;
    unsigned int t8;
    char *t9;
    char *t10;
    char *t11;
    unsigned int t12;
    char *t14;
    int t15;
    char *t16;
    int t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;
    char *t40;
    char *t41;
    char *t42;
    unsigned char t43;
    char *t44;
    char *t45;
    int t46;
    char *t47;
    int t48;
    char *t49;
    int t50;
    int t51;
    int t52;
    int t53;
    int t54;
    char *t55;
    char *t56;
    unsigned char t57;
    int t58;
    char *t59;
    int t60;
    int t61;
    unsigned int t62;
    unsigned int t63;
    char *t64;
    unsigned char t65;
    unsigned char t66;
    char *t67;
    char *t68;
    unsigned int t69;

LAB0:    t7 = (t4 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t9 = xsi_get_transient_memory(t8);
    memset(t9, 0, t8);
    t10 = t9;
    memset(t10, (unsigned char)2, t8);
    t11 = (t4 + 12U);
    t12 = *((unsigned int *)t11);
    t12 = (t12 * 1U);
    t14 = (t4 + 0U);
    t15 = *((int *)t14);
    t16 = (t4 + 4U);
    t17 = *((int *)t16);
    t18 = (t4 + 8U);
    t19 = *((int *)t18);
    t20 = (t13 + 0U);
    t21 = (t20 + 0U);
    *((int *)t21) = t15;
    t21 = (t20 + 4U);
    *((int *)t21) = t17;
    t21 = (t20 + 8U);
    *((int *)t21) = t19;
    t22 = (t17 - t15);
    t23 = (t22 * t19);
    t23 = (t23 + 1);
    t21 = (t20 + 12U);
    *((unsigned int *)t21) = t23;
    t21 = (t5 + 4U);
    t24 = ((IEEE_P_2592010699) + 4024);
    t25 = (t21 + 88U);
    *((char **)t25) = t24;
    t26 = (char *)alloca(t12);
    t27 = (t21 + 56U);
    *((char **)t27) = t26;
    memcpy(t26, t9, t12);
    t28 = (t21 + 64U);
    *((char **)t28) = t13;
    t29 = (t21 + 80U);
    *((unsigned int *)t29) = t12;
    t30 = (t5 + 124U);
    t31 = ((STD_STANDARD) + 0);
    t32 = (t30 + 88U);
    *((char **)t32) = t31;
    t34 = (t30 + 56U);
    *((char **)t34) = t33;
    *((unsigned char *)t33) = (unsigned char)1;
    t35 = (t30 + 80U);
    *((unsigned int *)t35) = 1U;
    t36 = (t5 + 244U);
    t37 = ((STD_STANDARD) + 0);
    t38 = (t36 + 88U);
    *((char **)t38) = t37;
    t40 = (t36 + 56U);
    *((char **)t40) = t39;
    *((unsigned char *)t39) = (unsigned char)0;
    t41 = (t36 + 80U);
    *((unsigned int *)t41) = 1U;
    t42 = (t6 + 4U);
    t43 = (t3 != 0);
    if (t43 == 1)
        goto LAB3;

LAB2:    t44 = (t6 + 12U);
    *((char **)t44) = t4;
    t45 = (t4 + 8U);
    t46 = *((int *)t45);
    t47 = (t4 + 4U);
    t48 = *((int *)t47);
    t49 = (t4 + 0U);
    t50 = *((int *)t49);
    t51 = t50;
    t52 = t48;

LAB4:    t53 = (t52 * t46);
    t54 = (t51 * t46);
    if (t54 <= t53)
        goto LAB5;

LAB7:    t7 = (t21 + 56U);
    t9 = *((char **)t7);
    t7 = (t13 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t0 = xsi_get_transient_memory(t8);
    memcpy(t0, t9, t8);
    t10 = (t13 + 0U);
    t15 = *((int *)t10);
    t11 = (t13 + 4U);
    t17 = *((int *)t11);
    t14 = (t13 + 8U);
    t19 = *((int *)t14);
    t16 = (t2 + 0U);
    t18 = (t16 + 0U);
    *((int *)t18) = t15;
    t18 = (t16 + 4U);
    *((int *)t18) = t17;
    t18 = (t16 + 8U);
    *((int *)t18) = t19;
    t22 = (t17 - t15);
    t12 = (t22 * t19);
    t12 = (t12 + 1);
    t18 = (t16 + 12U);
    *((unsigned int *)t18) = t12;

LAB1:    return t0;
LAB3:    *((char **)t42) = t3;
    goto LAB2;

LAB5:    t55 = (t30 + 56U);
    t56 = *((char **)t55);
    t57 = *((unsigned char *)t56);
    if (t57 != 0)
        goto LAB8;

LAB10:
LAB9:    t7 = (t30 + 56U);
    t9 = *((char **)t7);
    t43 = *((unsigned char *)t9);
    t57 = (!(t43));
    if (t57 != 0)
        goto LAB14;

LAB16:
LAB15:    t7 = (t36 + 56U);
    t9 = *((char **)t7);
    t43 = *((unsigned char *)t9);
    if (t43 != 0)
        goto LAB20;

LAB22:    t7 = (t4 + 0U);
    t15 = *((int *)t7);
    t9 = (t4 + 8U);
    t17 = *((int *)t9);
    t19 = (t51 - t15);
    t8 = (t19 * t17);
    t12 = (1U * t8);
    t23 = (0 + t12);
    t10 = (t3 + t23);
    t43 = *((unsigned char *)t10);
    t11 = (t21 + 56U);
    t14 = *((char **)t11);
    t11 = (t13 + 0U);
    t22 = *((int *)t11);
    t16 = (t13 + 8U);
    t48 = *((int *)t16);
    t50 = (t51 - t22);
    t62 = (t50 * t48);
    t18 = (t13 + 4U);
    t53 = *((int *)t18);
    xsi_vhdl_check_range_of_index(t22, t53, t48, t51);
    t63 = (1U * t62);
    t69 = (0 + t63);
    t20 = (t14 + t69);
    *((unsigned char *)t20) = t43;

LAB21:
LAB6:    if (t51 == t52)
        goto LAB7;

LAB23:    t15 = (t51 + t46);
    t51 = t15;
    goto LAB4;

LAB8:    t55 = (t4 + 0U);
    t58 = *((int *)t55);
    t59 = (t4 + 8U);
    t60 = *((int *)t59);
    t61 = (t51 - t58);
    t23 = (t61 * t60);
    t62 = (1U * t23);
    t63 = (0 + t62);
    t64 = (t3 + t63);
    t65 = *((unsigned char *)t64);
    t66 = (t65 == (unsigned char)3);
    if (t66 != 0)
        goto LAB11;

LAB13:
LAB12:    goto LAB9;

LAB11:    t67 = (t30 + 56U);
    t68 = *((char **)t67);
    t67 = (t68 + 0);
    *((unsigned char *)t67) = (unsigned char)0;
    goto LAB12;

LAB14:    t7 = (t4 + 0U);
    t15 = *((int *)t7);
    t10 = (t4 + 8U);
    t17 = *((int *)t10);
    t19 = (t51 - t15);
    t8 = (t19 * t17);
    t12 = (1U * t8);
    t23 = (0 + t12);
    t11 = (t3 + t23);
    t65 = *((unsigned char *)t11);
    t66 = (t65 == (unsigned char)2);
    if (t66 != 0)
        goto LAB17;

LAB19:
LAB18:    goto LAB15;

LAB17:    t14 = (t36 + 56U);
    t16 = *((char **)t14);
    t14 = (t16 + 0);
    *((unsigned char *)t14) = (unsigned char)1;
    goto LAB18;

LAB20:    t7 = (t21 + 56U);
    t10 = *((char **)t7);
    t7 = (t13 + 0U);
    t15 = *((int *)t7);
    t11 = (t13 + 8U);
    t17 = *((int *)t11);
    t19 = (t51 - t15);
    t8 = (t19 * t17);
    t14 = (t13 + 4U);
    t22 = *((int *)t14);
    xsi_vhdl_check_range_of_index(t15, t22, t17, t51);
    t12 = (1U * t8);
    t23 = (0 + t12);
    t16 = (t10 + t23);
    *((unsigned char *)t16) = (unsigned char)2;
    goto LAB21;

LAB24:;
}

char *work_p_2284038668_sub_1790567348_2077180020(char *t1, char *t2, char *t3, char *t4)
{
    char t5[248];
    char t6[24];
    char t13[16];
    char t33[8];
    char *t0;
    char *t7;
    unsigned int t8;
    char *t9;
    char *t10;
    char *t11;
    unsigned int t12;
    char *t14;
    int t15;
    char *t16;
    int t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t34;
    char *t35;
    char *t36;
    unsigned char t37;
    char *t38;
    char *t39;
    int t40;
    char *t41;
    int t42;
    char *t43;
    int t44;
    int t45;
    int t46;
    int t47;
    int t48;
    char *t49;
    char *t50;
    unsigned char t51;
    int t52;
    char *t53;
    int t54;
    int t55;
    unsigned int t56;
    unsigned int t57;
    char *t58;
    unsigned char t59;
    unsigned char t60;
    char *t61;
    char *t62;

LAB0:    t7 = (t4 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t9 = xsi_get_transient_memory(t8);
    memset(t9, 0, t8);
    t10 = t9;
    memset(t10, (unsigned char)2, t8);
    t11 = (t4 + 12U);
    t12 = *((unsigned int *)t11);
    t12 = (t12 * 1U);
    t14 = (t4 + 0U);
    t15 = *((int *)t14);
    t16 = (t4 + 4U);
    t17 = *((int *)t16);
    t18 = (t4 + 8U);
    t19 = *((int *)t18);
    t20 = (t13 + 0U);
    t21 = (t20 + 0U);
    *((int *)t21) = t15;
    t21 = (t20 + 4U);
    *((int *)t21) = t17;
    t21 = (t20 + 8U);
    *((int *)t21) = t19;
    t22 = (t17 - t15);
    t23 = (t22 * t19);
    t23 = (t23 + 1);
    t21 = (t20 + 12U);
    *((unsigned int *)t21) = t23;
    t21 = (t5 + 4U);
    t24 = ((IEEE_P_2592010699) + 4024);
    t25 = (t21 + 88U);
    *((char **)t25) = t24;
    t26 = (char *)alloca(t12);
    t27 = (t21 + 56U);
    *((char **)t27) = t26;
    memcpy(t26, t9, t12);
    t28 = (t21 + 64U);
    *((char **)t28) = t13;
    t29 = (t21 + 80U);
    *((unsigned int *)t29) = t12;
    t30 = (t5 + 124U);
    t31 = ((STD_STANDARD) + 0);
    t32 = (t30 + 88U);
    *((char **)t32) = t31;
    t34 = (t30 + 56U);
    *((char **)t34) = t33;
    *((unsigned char *)t33) = (unsigned char)1;
    t35 = (t30 + 80U);
    *((unsigned int *)t35) = 1U;
    t36 = (t6 + 4U);
    t37 = (t3 != 0);
    if (t37 == 1)
        goto LAB3;

LAB2:    t38 = (t6 + 12U);
    *((char **)t38) = t4;
    t39 = (t4 + 8U);
    t40 = *((int *)t39);
    t41 = (t4 + 4U);
    t42 = *((int *)t41);
    t43 = (t4 + 0U);
    t44 = *((int *)t43);
    t45 = t44;
    t46 = t42;

LAB4:    t47 = (t46 * t40);
    t48 = (t45 * t40);
    if (t48 <= t47)
        goto LAB5;

LAB7:    t7 = (t21 + 56U);
    t9 = *((char **)t7);
    t7 = (t13 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t0 = xsi_get_transient_memory(t8);
    memcpy(t0, t9, t8);
    t10 = (t13 + 0U);
    t15 = *((int *)t10);
    t11 = (t13 + 4U);
    t17 = *((int *)t11);
    t14 = (t13 + 8U);
    t19 = *((int *)t14);
    t16 = (t2 + 0U);
    t18 = (t16 + 0U);
    *((int *)t18) = t15;
    t18 = (t16 + 4U);
    *((int *)t18) = t17;
    t18 = (t16 + 8U);
    *((int *)t18) = t19;
    t22 = (t17 - t15);
    t12 = (t22 * t19);
    t12 = (t12 + 1);
    t18 = (t16 + 12U);
    *((unsigned int *)t18) = t12;

LAB1:    return t0;
LAB3:    *((char **)t36) = t3;
    goto LAB2;

LAB5:    t49 = (t30 + 56U);
    t50 = *((char **)t49);
    t51 = *((unsigned char *)t50);
    if (t51 != 0)
        goto LAB8;

LAB10:
LAB9:    t7 = (t30 + 56U);
    t9 = *((char **)t7);
    t37 = *((unsigned char *)t9);
    t51 = (!(t37));
    if (t51 != 0)
        goto LAB14;

LAB16:
LAB15:
LAB6:    if (t45 == t46)
        goto LAB7;

LAB17:    t15 = (t45 + t40);
    t45 = t15;
    goto LAB4;

LAB8:    t49 = (t4 + 0U);
    t52 = *((int *)t49);
    t53 = (t4 + 8U);
    t54 = *((int *)t53);
    t55 = (t45 - t52);
    t23 = (t55 * t54);
    t56 = (1U * t23);
    t57 = (0 + t56);
    t58 = (t3 + t57);
    t59 = *((unsigned char *)t58);
    t60 = (t59 == (unsigned char)3);
    if (t60 != 0)
        goto LAB11;

LAB13:
LAB12:    goto LAB9;

LAB11:    t61 = (t30 + 56U);
    t62 = *((char **)t61);
    t61 = (t62 + 0);
    *((unsigned char *)t61) = (unsigned char)0;
    goto LAB12;

LAB14:    t7 = (t21 + 56U);
    t10 = *((char **)t7);
    t7 = (t13 + 0U);
    t15 = *((int *)t7);
    t11 = (t13 + 8U);
    t17 = *((int *)t11);
    t19 = (t45 - t15);
    t8 = (t19 * t17);
    t14 = (t13 + 4U);
    t22 = *((int *)t14);
    xsi_vhdl_check_range_of_index(t15, t22, t17, t45);
    t12 = (1U * t8);
    t23 = (0 + t12);
    t16 = (t10 + t23);
    *((unsigned char *)t16) = (unsigned char)3;
    goto LAB15;

LAB18:;
}

int work_p_2284038668_sub_1864997209_2077180020(char *t1, char *t2, char *t3)
{
    char t4[128];
    char t5[24];
    char t9[8];
    int t0;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    char *t11;
    char *t12;
    unsigned char t13;
    char *t14;
    char *t15;
    int t16;
    char *t17;
    int t18;
    char *t19;
    int t20;
    int t21;
    int t22;
    int t23;
    int t24;
    char *t25;
    int t26;
    char *t27;
    int t28;
    int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned char t34;
    unsigned char t35;
    char *t36;
    char *t37;
    int t38;
    int t39;
    char *t40;

LAB0:    t6 = (t4 + 4U);
    t7 = ((STD_STANDARD) + 832);
    t8 = (t6 + 88U);
    *((char **)t8) = t7;
    t10 = (t6 + 56U);
    *((char **)t10) = t9;
    *((int *)t9) = 0;
    t11 = (t6 + 80U);
    *((unsigned int *)t11) = 4U;
    t12 = (t5 + 4U);
    t13 = (t2 != 0);
    if (t13 == 1)
        goto LAB3;

LAB2:    t14 = (t5 + 12U);
    *((char **)t14) = t3;
    t15 = (t3 + 8U);
    t16 = *((int *)t15);
    t17 = (t3 + 4U);
    t18 = *((int *)t17);
    t19 = (t3 + 0U);
    t20 = *((int *)t19);
    t21 = t20;
    t22 = t18;

LAB4:    t23 = (t22 * t16);
    t24 = (t21 * t16);
    if (t24 <= t23)
        goto LAB5;

LAB7:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t16 = *((int *)t8);
    t0 = t16;

LAB1:    return t0;
LAB3:    *((char **)t12) = t2;
    goto LAB2;

LAB5:    t25 = (t3 + 0U);
    t26 = *((int *)t25);
    t27 = (t3 + 8U);
    t28 = *((int *)t27);
    t29 = (t21 - t26);
    t30 = (t29 * t28);
    t31 = (1U * t30);
    t32 = (0 + t31);
    t33 = (t2 + t32);
    t34 = *((unsigned char *)t33);
    t35 = (t34 == (unsigned char)2);
    if (t35 != 0)
        goto LAB8;

LAB10:    goto LAB7;

LAB6:    if (t21 == t22)
        goto LAB7;

LAB12:    t18 = (t21 + t16);
    t21 = t18;
    goto LAB4;

LAB8:    t36 = (t6 + 56U);
    t37 = *((char **)t36);
    t38 = *((int *)t37);
    t39 = (t38 + 1);
    t36 = (t6 + 56U);
    t40 = *((char **)t36);
    t36 = (t40 + 0);
    *((int *)t36) = t39;

LAB9:    goto LAB6;

LAB11:    goto LAB9;

LAB13:;
}

char *work_p_2284038668_sub_237788728_2077180020(char *t1, char *t2, char *t3, char *t4)
{
    char t5[248];
    char t6[24];
    char t13[16];
    char t34[8];
    char *t0;
    char *t7;
    unsigned int t8;
    char *t9;
    char *t10;
    char *t11;
    unsigned int t12;
    char *t14;
    int t15;
    char *t16;
    int t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    int t30;
    char *t31;
    char *t32;
    char *t33;
    char *t35;
    char *t36;
    char *t37;
    unsigned char t38;
    char *t39;
    char *t40;
    int t41;
    char *t42;
    char *t43;
    int t44;
    int t45;
    int t46;
    int t47;
    int t48;
    char *t49;
    char *t50;
    int t51;
    int t52;
    int t53;
    char *t54;
    int t55;
    int t56;
    char *t57;
    int t58;
    unsigned int t59;
    unsigned int t60;
    char *t61;
    unsigned char t62;
    char *t63;
    char *t64;
    int t65;
    char *t66;
    int t67;
    int t68;
    unsigned int t69;
    char *t70;
    int t71;
    unsigned int t72;
    unsigned int t73;
    char *t74;

LAB0:    t7 = (t4 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t9 = xsi_get_transient_memory(t8);
    memset(t9, 0, t8);
    t10 = t9;
    memset(t10, (unsigned char)2, t8);
    t11 = (t4 + 12U);
    t12 = *((unsigned int *)t11);
    t12 = (t12 * 1U);
    t14 = (t4 + 0U);
    t15 = *((int *)t14);
    t16 = (t4 + 4U);
    t17 = *((int *)t16);
    t18 = (t4 + 8U);
    t19 = *((int *)t18);
    t20 = (t13 + 0U);
    t21 = (t20 + 0U);
    *((int *)t21) = t15;
    t21 = (t20 + 4U);
    *((int *)t21) = t17;
    t21 = (t20 + 8U);
    *((int *)t21) = t19;
    t22 = (t17 - t15);
    t23 = (t22 * t19);
    t23 = (t23 + 1);
    t21 = (t20 + 12U);
    *((unsigned int *)t21) = t23;
    t21 = (t5 + 4U);
    t24 = ((IEEE_P_2592010699) + 4024);
    t25 = (t21 + 88U);
    *((char **)t25) = t24;
    t26 = (char *)alloca(t12);
    t27 = (t21 + 56U);
    *((char **)t27) = t26;
    memcpy(t26, t9, t12);
    t28 = (t21 + 64U);
    *((char **)t28) = t13;
    t29 = (t21 + 80U);
    *((unsigned int *)t29) = t12;
    t30 = work_p_2284038668_sub_1864997209_2077180020(t1, t3, t4);
    t31 = (t5 + 124U);
    t32 = ((STD_STANDARD) + 832);
    t33 = (t31 + 88U);
    *((char **)t33) = t32;
    t35 = (t31 + 56U);
    *((char **)t35) = t34;
    *((int *)t34) = t30;
    t36 = (t31 + 80U);
    *((unsigned int *)t36) = 4U;
    t37 = (t6 + 4U);
    t38 = (t3 != 0);
    if (t38 == 1)
        goto LAB3;

LAB2:    t39 = (t6 + 12U);
    *((char **)t39) = t4;
    t40 = (t4 + 4U);
    t41 = *((int *)t40);
    t42 = (t31 + 56U);
    t43 = *((char **)t42);
    t44 = *((int *)t43);
    t45 = (t41 - t44);
    t42 = (t4 + 0U);
    t46 = *((int *)t42);
    t47 = t46;
    t48 = t45;

LAB4:    if (t47 <= t48)
        goto LAB5;

LAB7:    t7 = (t21 + 56U);
    t9 = *((char **)t7);
    t7 = (t13 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t0 = xsi_get_transient_memory(t8);
    memcpy(t0, t9, t8);
    t10 = (t13 + 0U);
    t15 = *((int *)t10);
    t11 = (t13 + 4U);
    t17 = *((int *)t11);
    t14 = (t13 + 8U);
    t19 = *((int *)t14);
    t16 = (t2 + 0U);
    t18 = (t16 + 0U);
    *((int *)t18) = t15;
    t18 = (t16 + 4U);
    *((int *)t18) = t17;
    t18 = (t16 + 8U);
    *((int *)t18) = t19;
    t22 = (t17 - t15);
    t12 = (t22 * t19);
    t12 = (t12 + 1);
    t18 = (t16 + 12U);
    *((unsigned int *)t18) = t12;

LAB1:    return t0;
LAB3:    *((char **)t37) = t3;
    goto LAB2;

LAB5:    t49 = (t31 + 56U);
    t50 = *((char **)t49);
    t51 = *((int *)t50);
    t52 = (t47 + t51);
    t49 = (t4 + 0U);
    t53 = *((int *)t49);
    t54 = (t4 + 8U);
    t55 = *((int *)t54);
    t56 = (t52 - t53);
    t23 = (t56 * t55);
    t57 = (t4 + 4U);
    t58 = *((int *)t57);
    xsi_vhdl_check_range_of_index(t53, t58, t55, t52);
    t59 = (1U * t23);
    t60 = (0 + t59);
    t61 = (t3 + t60);
    t62 = *((unsigned char *)t61);
    t63 = (t21 + 56U);
    t64 = *((char **)t63);
    t63 = (t13 + 0U);
    t65 = *((int *)t63);
    t66 = (t13 + 8U);
    t67 = *((int *)t66);
    t68 = (t47 - t65);
    t69 = (t68 * t67);
    t70 = (t13 + 4U);
    t71 = *((int *)t70);
    xsi_vhdl_check_range_of_index(t65, t71, t67, t47);
    t72 = (1U * t69);
    t73 = (0 + t72);
    t74 = (t64 + t73);
    *((unsigned char *)t74) = t62;

LAB6:    if (t47 == t48)
        goto LAB7;

LAB8:    t15 = (t47 + 1);
    t47 = t15;
    goto LAB4;

LAB9:;
}

char *work_p_2284038668_sub_3428617466_2077180020(char *t1, char *t2, char *t3, char *t4, int t5)
{
    char t6[128];
    char t7[24];
    char t14[16];
    char *t0;
    char *t8;
    unsigned int t9;
    char *t10;
    char *t11;
    char *t12;
    unsigned int t13;
    char *t15;
    int t16;
    char *t17;
    int t18;
    char *t19;
    int t20;
    char *t21;
    char *t22;
    int t23;
    unsigned int t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    unsigned char t32;
    char *t33;
    char *t34;
    char *t35;
    int t36;
    char *t37;
    int t38;
    char *t39;
    int t40;
    int t41;
    int t42;
    int t43;
    int t44;
    char *t45;
    int t46;
    char *t47;
    int t48;
    int t49;
    unsigned int t50;
    unsigned int t51;
    char *t52;
    int t53;
    unsigned char t54;
    char *t55;
    char *t56;
    int t57;
    char *t58;
    int t59;
    int t60;
    unsigned int t61;
    char *t62;
    int t63;
    unsigned int t64;
    unsigned int t65;
    char *t66;

LAB0:    t8 = (t4 + 12U);
    t9 = *((unsigned int *)t8);
    t9 = (t9 * 1U);
    t10 = xsi_get_transient_memory(t9);
    memset(t10, 0, t9);
    t11 = t10;
    memset(t11, (unsigned char)2, t9);
    t12 = (t4 + 12U);
    t13 = *((unsigned int *)t12);
    t13 = (t13 * 1U);
    t15 = (t4 + 0U);
    t16 = *((int *)t15);
    t17 = (t4 + 4U);
    t18 = *((int *)t17);
    t19 = (t4 + 8U);
    t20 = *((int *)t19);
    t21 = (t14 + 0U);
    t22 = (t21 + 0U);
    *((int *)t22) = t16;
    t22 = (t21 + 4U);
    *((int *)t22) = t18;
    t22 = (t21 + 8U);
    *((int *)t22) = t20;
    t23 = (t18 - t16);
    t24 = (t23 * t20);
    t24 = (t24 + 1);
    t22 = (t21 + 12U);
    *((unsigned int *)t22) = t24;
    t22 = (t6 + 4U);
    t25 = ((IEEE_P_2592010699) + 4024);
    t26 = (t22 + 88U);
    *((char **)t26) = t25;
    t27 = (char *)alloca(t13);
    t28 = (t22 + 56U);
    *((char **)t28) = t27;
    memcpy(t27, t10, t13);
    t29 = (t22 + 64U);
    *((char **)t29) = t14;
    t30 = (t22 + 80U);
    *((unsigned int *)t30) = t13;
    t31 = (t7 + 4U);
    t32 = (t3 != 0);
    if (t32 == 1)
        goto LAB3;

LAB2:    t33 = (t7 + 12U);
    *((char **)t33) = t4;
    t34 = (t7 + 20U);
    *((int *)t34) = t5;
    t35 = (t4 + 8U);
    t36 = *((int *)t35);
    t37 = (t4 + 4U);
    t38 = *((int *)t37);
    t39 = (t4 + 0U);
    t40 = *((int *)t39);
    t41 = t40;
    t42 = t38;

LAB4:    t43 = (t42 * t36);
    t44 = (t41 * t36);
    if (t44 <= t43)
        goto LAB5;

LAB7:    t8 = (t22 + 56U);
    t10 = *((char **)t8);
    t8 = (t14 + 12U);
    t9 = *((unsigned int *)t8);
    t9 = (t9 * 1U);
    t0 = xsi_get_transient_memory(t9);
    memcpy(t0, t10, t9);
    t11 = (t14 + 0U);
    t16 = *((int *)t11);
    t12 = (t14 + 4U);
    t18 = *((int *)t12);
    t15 = (t14 + 8U);
    t20 = *((int *)t15);
    t17 = (t2 + 0U);
    t19 = (t17 + 0U);
    *((int *)t19) = t16;
    t19 = (t17 + 4U);
    *((int *)t19) = t18;
    t19 = (t17 + 8U);
    *((int *)t19) = t20;
    t23 = (t18 - t16);
    t13 = (t23 * t20);
    t13 = (t13 + 1);
    t19 = (t17 + 12U);
    *((unsigned int *)t19) = t13;

LAB1:    return t0;
LAB3:    *((char **)t31) = t3;
    goto LAB2;

LAB5:    t45 = (t4 + 0U);
    t46 = *((int *)t45);
    t47 = (t4 + 8U);
    t48 = *((int *)t47);
    t49 = (t41 - t46);
    t24 = (t49 * t48);
    t50 = (4U * t24);
    t51 = (0 + t50);
    t52 = (t3 + t51);
    t53 = *((int *)t52);
    t54 = (t53 == t5);
    if (t54 != 0)
        goto LAB8;

LAB10:
LAB9:
LAB6:    if (t41 == t42)
        goto LAB7;

LAB11:    t16 = (t41 + t36);
    t41 = t16;
    goto LAB4;

LAB8:    t55 = (t22 + 56U);
    t56 = *((char **)t55);
    t55 = (t14 + 0U);
    t57 = *((int *)t55);
    t58 = (t14 + 8U);
    t59 = *((int *)t58);
    t60 = (t41 - t57);
    t61 = (t60 * t59);
    t62 = (t14 + 4U);
    t63 = *((int *)t62);
    xsi_vhdl_check_range_of_index(t57, t63, t59, t41);
    t64 = (1U * t61);
    t65 = (0 + t64);
    t66 = (t56 + t65);
    *((unsigned char *)t66) = (unsigned char)3;
    goto LAB9;

LAB12:;
}

char *work_p_2284038668_sub_1604624995_2077180020(char *t1, char *t2, char *t3, char *t4)
{
    char t5[128];
    char t6[24];
    char t13[16];
    char *t0;
    char *t7;
    unsigned int t8;
    char *t9;
    char *t10;
    char *t11;
    unsigned int t12;
    char *t14;
    int t15;
    char *t16;
    int t17;
    char *t18;
    int t19;
    char *t20;
    char *t21;
    int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    char *t30;
    unsigned char t31;
    char *t32;
    char *t33;
    int t34;
    char *t35;
    int t36;
    char *t37;
    int t38;
    int t39;
    int t40;
    int t41;
    int t42;
    char *t43;
    int t44;
    char *t45;
    int t46;
    int t47;
    unsigned int t48;
    unsigned int t49;
    char *t50;
    unsigned char t51;
    unsigned char t52;
    char *t53;
    char *t54;
    int t55;
    char *t56;
    int t57;
    int t58;
    unsigned int t59;
    char *t60;
    int t61;
    unsigned int t62;
    unsigned int t63;
    char *t64;

LAB0:    t7 = (t4 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t9 = xsi_get_transient_memory(t8);
    memset(t9, 0, t8);
    t10 = t9;
    memset(t10, (unsigned char)2, t8);
    t11 = (t4 + 12U);
    t12 = *((unsigned int *)t11);
    t12 = (t12 * 1U);
    t14 = (t4 + 0U);
    t15 = *((int *)t14);
    t16 = (t4 + 4U);
    t17 = *((int *)t16);
    t18 = (t4 + 8U);
    t19 = *((int *)t18);
    t20 = (t13 + 0U);
    t21 = (t20 + 0U);
    *((int *)t21) = t15;
    t21 = (t20 + 4U);
    *((int *)t21) = t17;
    t21 = (t20 + 8U);
    *((int *)t21) = t19;
    t22 = (t17 - t15);
    t23 = (t22 * t19);
    t23 = (t23 + 1);
    t21 = (t20 + 12U);
    *((unsigned int *)t21) = t23;
    t21 = (t5 + 4U);
    t24 = ((IEEE_P_2592010699) + 4024);
    t25 = (t21 + 88U);
    *((char **)t25) = t24;
    t26 = (char *)alloca(t12);
    t27 = (t21 + 56U);
    *((char **)t27) = t26;
    memcpy(t26, t9, t12);
    t28 = (t21 + 64U);
    *((char **)t28) = t13;
    t29 = (t21 + 80U);
    *((unsigned int *)t29) = t12;
    t30 = (t6 + 4U);
    t31 = (t3 != 0);
    if (t31 == 1)
        goto LAB3;

LAB2:    t32 = (t6 + 12U);
    *((char **)t32) = t4;
    t33 = (t4 + 8U);
    t34 = *((int *)t33);
    t35 = (t4 + 4U);
    t36 = *((int *)t35);
    t37 = (t4 + 0U);
    t38 = *((int *)t37);
    t39 = t38;
    t40 = t36;

LAB4:    t41 = (t40 * t34);
    t42 = (t39 * t34);
    if (t42 <= t41)
        goto LAB5;

LAB7:    t7 = (t21 + 56U);
    t9 = *((char **)t7);
    t7 = (t13 + 12U);
    t8 = *((unsigned int *)t7);
    t8 = (t8 * 1U);
    t0 = xsi_get_transient_memory(t8);
    memcpy(t0, t9, t8);
    t10 = (t13 + 0U);
    t15 = *((int *)t10);
    t11 = (t13 + 4U);
    t17 = *((int *)t11);
    t14 = (t13 + 8U);
    t19 = *((int *)t14);
    t16 = (t2 + 0U);
    t18 = (t16 + 0U);
    *((int *)t18) = t15;
    t18 = (t16 + 4U);
    *((int *)t18) = t17;
    t18 = (t16 + 8U);
    *((int *)t18) = t19;
    t22 = (t17 - t15);
    t12 = (t22 * t19);
    t12 = (t12 + 1);
    t18 = (t16 + 12U);
    *((unsigned int *)t18) = t12;

LAB1:    return t0;
LAB3:    *((char **)t30) = t3;
    goto LAB2;

LAB5:    t43 = (t4 + 0U);
    t44 = *((int *)t43);
    t45 = (t4 + 8U);
    t46 = *((int *)t45);
    t47 = (t39 - t44);
    t23 = (t47 * t46);
    t48 = (1U * t23);
    t49 = (0 + t48);
    t50 = (t3 + t49);
    t51 = *((unsigned char *)t50);
    t52 = (t51 == (unsigned char)3);
    if (t52 != 0)
        goto LAB8;

LAB10:
LAB9:
LAB6:    if (t39 == t40)
        goto LAB7;

LAB12:    t15 = (t39 + t34);
    t39 = t15;
    goto LAB4;

LAB8:    t53 = (t21 + 56U);
    t54 = *((char **)t53);
    t53 = (t13 + 0U);
    t55 = *((int *)t53);
    t56 = (t13 + 8U);
    t57 = *((int *)t56);
    t58 = (t39 - t55);
    t59 = (t58 * t57);
    t60 = (t13 + 4U);
    t61 = *((int *)t60);
    xsi_vhdl_check_range_of_index(t55, t61, t57, t39);
    t62 = (1U * t59);
    t63 = (0 + t62);
    t64 = (t54 + t63);
    *((unsigned char *)t64) = (unsigned char)3;
    goto LAB7;

LAB11:    goto LAB9;

LAB13:;
}

int work_p_2284038668_sub_3839206348_2077180020(char *t1, char *t2, char *t3)
{
    char t4[128];
    char t5[24];
    char t9[8];
    int t0;
    char *t6;
    char *t7;
    char *t8;
    char *t10;
    char *t11;
    char *t12;
    unsigned char t13;
    char *t14;
    char *t15;
    int t16;
    char *t17;
    int t18;
    char *t19;
    int t20;
    int t21;
    int t22;
    int t23;
    int t24;
    char *t25;
    int t26;
    char *t27;
    int t28;
    int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned char t34;
    unsigned char t35;
    char *t36;
    char *t37;

LAB0:    t6 = (t4 + 4U);
    t7 = ((STD_STANDARD) + 832);
    t8 = (t6 + 88U);
    *((char **)t8) = t7;
    t10 = (t6 + 56U);
    *((char **)t10) = t9;
    *((int *)t9) = 0;
    t11 = (t6 + 80U);
    *((unsigned int *)t11) = 4U;
    t12 = (t5 + 4U);
    t13 = (t2 != 0);
    if (t13 == 1)
        goto LAB3;

LAB2:    t14 = (t5 + 12U);
    *((char **)t14) = t3;
    t15 = (t3 + 8U);
    t16 = *((int *)t15);
    t17 = (t3 + 4U);
    t18 = *((int *)t17);
    t19 = (t3 + 0U);
    t20 = *((int *)t19);
    t21 = t20;
    t22 = t18;

LAB4:    t23 = (t22 * t16);
    t24 = (t21 * t16);
    if (t24 <= t23)
        goto LAB5;

LAB7:    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t16 = *((int *)t8);
    t0 = t16;

LAB1:    return t0;
LAB3:    *((char **)t12) = t2;
    goto LAB2;

LAB5:    t25 = (t3 + 0U);
    t26 = *((int *)t25);
    t27 = (t3 + 8U);
    t28 = *((int *)t27);
    t29 = (t21 - t26);
    t30 = (t29 * t28);
    t31 = (1U * t30);
    t32 = (0 + t31);
    t33 = (t2 + t32);
    t34 = *((unsigned char *)t33);
    t35 = (t34 == (unsigned char)3);
    if (t35 != 0)
        goto LAB8;

LAB10:
LAB9:
LAB6:    if (t21 == t22)
        goto LAB7;

LAB12:    t18 = (t21 + t16);
    t21 = t18;
    goto LAB4;

LAB8:    t36 = (t6 + 56U);
    t37 = *((char **)t36);
    t36 = (t37 + 0);
    *((int *)t36) = t21;
    goto LAB7;

LAB11:    goto LAB9;

LAB13:;
}

unsigned char work_p_2284038668_sub_3763702750_2077180020(char *t1, char *t2, char *t3)
{
    char t5[24];
    unsigned char t0;
    char *t6;
    unsigned char t7;
    char *t8;
    char *t9;
    int t10;
    char *t11;
    int t12;
    char *t13;
    int t14;
    int t15;
    int t16;
    int t17;
    int t18;
    char *t19;
    int t20;
    char *t21;
    int t22;
    int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    char *t27;
    unsigned char t28;
    unsigned char t29;

LAB0:    t6 = (t5 + 4U);
    t7 = (t2 != 0);
    if (t7 == 1)
        goto LAB3;

LAB2:    t8 = (t5 + 12U);
    *((char **)t8) = t3;
    t9 = (t3 + 8U);
    t10 = *((int *)t9);
    t11 = (t3 + 4U);
    t12 = *((int *)t11);
    t13 = (t3 + 0U);
    t14 = *((int *)t13);
    t15 = t14;
    t16 = t12;

LAB4:    t17 = (t16 * t10);
    t18 = (t15 * t10);
    if (t18 <= t17)
        goto LAB5;

LAB7:    t0 = (unsigned char)2;

LAB1:    return t0;
LAB3:    *((char **)t6) = t2;
    goto LAB2;

LAB5:    t19 = (t3 + 0U);
    t20 = *((int *)t19);
    t21 = (t3 + 8U);
    t22 = *((int *)t21);
    t23 = (t15 - t20);
    t24 = (t23 * t22);
    t25 = (1U * t24);
    t26 = (0 + t25);
    t27 = (t2 + t26);
    t28 = *((unsigned char *)t27);
    t29 = (t28 == (unsigned char)3);
    if (t29 != 0)
        goto LAB8;

LAB10:
LAB9:
LAB6:    if (t15 == t16)
        goto LAB7;

LAB12:    t12 = (t15 + t10);
    t15 = t12;
    goto LAB4;

LAB8:    t0 = (unsigned char)3;
    goto LAB1;

LAB11:    goto LAB9;

LAB13:;
}


extern void work_p_2284038668_init()
{
	static char *se[] = {(void *)work_p_2284038668_sub_1279250441_2077180020,(void *)work_p_2284038668_sub_2592118765_2077180020,(void *)work_p_2284038668_sub_2398579266_2077180020,(void *)work_p_2284038668_sub_1790567348_2077180020,(void *)work_p_2284038668_sub_1864997209_2077180020,(void *)work_p_2284038668_sub_237788728_2077180020,(void *)work_p_2284038668_sub_3428617466_2077180020,(void *)work_p_2284038668_sub_1604624995_2077180020,(void *)work_p_2284038668_sub_3839206348_2077180020,(void *)work_p_2284038668_sub_3763702750_2077180020};
	xsi_register_didat("work_p_2284038668", "isim/NewCoreTB_isim_beh.exe.sim/work/p_2284038668.didat");
	xsi_register_subprogram_executes(se);
}
