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
extern char *IEEE_P_2592010699;
extern char *WORK_P_2392574874;
extern char *STD_STANDARD;

int work_p_2392574874_sub_492870414_3353671955(char *, char *, char *);
char *work_p_2392574874_sub_805424436_3353671955(char *, char *, int , int );


int work_p_2913168131_sub_2384492247_1522046508(char *t1, char *t2)
{
    char t3[128];
    char t4[24];
    char t5[16];
    char t10[16];
    char t15[8];
    int t0;
    char *t6;
    char *t7;
    int t8;
    unsigned int t9;
    char *t11;
    int t12;
    char *t13;
    char *t14;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    int t24;

LAB0:    t6 = (t5 + 0U);
    t7 = (t6 + 0U);
    *((int *)t7) = 0;
    t7 = (t6 + 4U);
    *((int *)t7) = 7;
    t7 = (t6 + 8U);
    *((int *)t7) = 1;
    t8 = (7 - 0);
    t9 = (t8 * 1);
    t9 = (t9 + 1);
    t7 = (t6 + 12U);
    *((unsigned int *)t7) = t9;
    t7 = (t10 + 0U);
    t11 = (t7 + 0U);
    *((int *)t11) = 7;
    t11 = (t7 + 4U);
    *((int *)t11) = 0;
    t11 = (t7 + 8U);
    *((int *)t11) = -1;
    t12 = (0 - 7);
    t9 = (t12 * -1);
    t9 = (t9 + 1);
    t11 = (t7 + 12U);
    *((unsigned int *)t11) = t9;
    t11 = (t3 + 4U);
    t13 = ((IEEE_P_2592010699) + 4024);
    t14 = (t11 + 88U);
    *((char **)t14) = t13;
    t16 = (t11 + 56U);
    *((char **)t16) = t15;
    memcpy(t15, t2, 8U);
    t17 = (t11 + 64U);
    *((char **)t17) = t10;
    t18 = (t11 + 80U);
    *((unsigned int *)t18) = 8U;
    t19 = (t4 + 4U);
    t20 = (t2 != 0);
    if (t20 == 1)
        goto LAB3;

LAB2:    t21 = (t4 + 12U);
    *((char **)t21) = t5;
    t22 = (t11 + 56U);
    t23 = *((char **)t22);
    t24 = work_p_2392574874_sub_492870414_3353671955(WORK_P_2392574874, t23, t10);
    t0 = t24;

LAB1:    return t0;
LAB3:    *((char **)t19) = t2;
    goto LAB2;

LAB4:;
}

char *work_p_2913168131_sub_1615625482_1522046508(char *t1, int t2, unsigned char t3)
{
    char t4[248];
    char t5[16];
    char t8[16];
    char t15[8];
    char t24[8];
    char t29[16];
    char *t0;
    char *t6;
    char *t7;
    char *t9;
    char *t10;
    int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t30;
    char *t31;
    char *t32;
    char *t33;

LAB0:    t6 = xsi_get_transient_memory(8U);
    memset(t6, 0, 8U);
    t7 = t6;
    memset(t7, (unsigned char)2, 8U);
    t9 = (t8 + 0U);
    t10 = (t9 + 0U);
    *((int *)t10) = 0;
    t10 = (t9 + 4U);
    *((int *)t10) = 7;
    t10 = (t9 + 8U);
    *((int *)t10) = 1;
    t11 = (7 - 0);
    t12 = (t11 * 1);
    t12 = (t12 + 1);
    t10 = (t9 + 12U);
    *((unsigned int *)t10) = t12;
    t10 = (t4 + 4U);
    t13 = (t1 + 6152);
    t14 = (t10 + 88U);
    *((char **)t14) = t13;
    t16 = (t10 + 56U);
    *((char **)t16) = t15;
    memcpy(t15, t6, 8U);
    t17 = (t10 + 64U);
    t18 = (t13 + 80U);
    t19 = *((char **)t18);
    *((char **)t17) = t19;
    t20 = (t10 + 80U);
    *((unsigned int *)t20) = 8U;
    t21 = (t4 + 124U);
    t22 = ((STD_STANDARD) + 832);
    t23 = (t21 + 88U);
    *((char **)t23) = t22;
    t25 = (t21 + 56U);
    *((char **)t25) = t24;
    *((int *)t24) = t2;
    t26 = (t21 + 80U);
    *((unsigned int *)t26) = 4U;
    t27 = (t5 + 4U);
    *((int *)t27) = t2;
    t28 = (t5 + 8U);
    *((unsigned char *)t28) = t3;
    t30 = work_p_2392574874_sub_805424436_3353671955(WORK_P_2392574874, t29, t2, 8);
    t31 = (t10 + 56U);
    t32 = *((char **)t31);
    t31 = (t32 + 0);
    t33 = (t29 + 12U);
    t12 = *((unsigned int *)t33);
    t12 = (t12 * 1U);
    memcpy(t31, t30, t12);
    t6 = (t10 + 56U);
    t7 = *((char **)t6);
    xsi_vhdl_check_range_of_slice(0, 7, 1, 0, 7, 1);
    t0 = xsi_get_transient_memory(8U);
    memcpy(t0, t7, 8U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_1685871437_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;

LAB0:    t4 = xsi_get_transient_memory(48U);
    memset(t4, 0, 48U);
    t5 = t4;
    t6 = (t4 + 0U);
    t7 = t6;
    memset(t7, (unsigned char)3, 32U);
    t8 = (t4 + 32U);
    t9 = t8;
    memset(t9, (unsigned char)2, 8U);
    t10 = (t4 + 40U);
    t11 = t10;
    memset(t11, (unsigned char)2, 8U);
    t0 = xsi_get_transient_memory(48U);
    memcpy(t0, t4, 48U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_3620397739_1522046508(char *t1)
{
    char *t0;
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
    char *t19;

LAB0:    t4 = xsi_get_transient_memory(24U);
    memset(t4, 0, 24U);
    t5 = t4;
    t6 = (t4 + 0U);
    *((unsigned char *)t6) = (unsigned char)2;
    t7 = (t4 + 1U);
    *((unsigned char *)t7) = (unsigned char)2;
    t8 = (t4 + 2U);
    *((unsigned char *)t8) = (unsigned char)2;
    t9 = (t4 + 3U);
    *((unsigned char *)t9) = (unsigned char)2;
    t10 = (t4 + 4U);
    *((unsigned char *)t10) = (unsigned char)2;
    t11 = (t4 + 5U);
    *((unsigned char *)t11) = (unsigned char)2;
    t12 = (t4 + 6U);
    *((unsigned char *)t12) = (unsigned char)2;
    t13 = (t4 + 7U);
    t14 = t13;
    memset(t14, (unsigned char)3, 8U);
    t15 = (t4 + 15U);
    *((unsigned char *)t15) = (unsigned char)2;
    t16 = (t4 + 16U);
    *((unsigned char *)t16) = (unsigned char)2;
    t17 = (t4 + 17U);
    *((unsigned char *)t17) = (unsigned char)2;
    t18 = (t4 + 18U);
    *((unsigned char *)t18) = (unsigned char)2;
    t19 = (t4 + 19U);
    *((unsigned char *)t19) = (unsigned char)2;
    t0 = xsi_get_transient_memory(24U);
    memcpy(t0, t4, 24U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_2141115829_1522046508(char *t1)
{
    char *t0;
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

LAB0:    t4 = xsi_get_transient_memory(16U);
    memset(t4, 0, 16U);
    t5 = t4;
    t6 = (t4 + 0U);
    *((unsigned char *)t6) = (unsigned char)2;
    t7 = (t4 + 1U);
    *((unsigned char *)t7) = (unsigned char)2;
    t8 = (t4 + 2U);
    *((unsigned char *)t8) = (unsigned char)2;
    t9 = (t4 + 3U);
    *((unsigned char *)t9) = (unsigned char)2;
    t10 = (t4 + 4U);
    *((unsigned char *)t10) = (unsigned char)2;
    t11 = (t4 + 5U);
    *((unsigned char *)t11) = (unsigned char)2;
    t12 = (t4 + 6U);
    t13 = t12;
    memset(t13, (unsigned char)3, 8U);
    t0 = xsi_get_transient_memory(16U);
    memcpy(t0, t4, 16U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_2867232991_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t11;
    char *t12;

LAB0:    t4 = xsi_get_transient_memory(48U);
    memset(t4, 0, 48U);
    t5 = t4;
    *((unsigned char *)t5) = (unsigned char)2;
    t6 = (t4 + 1U);
    t7 = t6;
    memset(t7, (unsigned char)2, 32U);
    t8 = (t4 + 33U);
    t9 = (t1 + 13252);
    memcpy(t8, t9, 5U);
    t11 = (t4 + 38U);
    t12 = (t1 + 13257);
    memcpy(t11, t12, 5U);
    t0 = xsi_get_transient_memory(48U);
    memcpy(t0, t4, 48U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_732444313_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;
    char *t11;
    char *t12;
    char *t14;
    char *t15;

LAB0:    t4 = xsi_get_transient_memory(24U);
    memset(t4, 0, 24U);
    t5 = t4;
    t6 = (t1 + 13262);
    memcpy(t5, t6, 3U);
    t8 = (t4 + 3U);
    t9 = (t1 + 13265);
    memcpy(t8, t9, 5U);
    t11 = (t4 + 8U);
    t12 = (t1 + 13270);
    memcpy(t11, t12, 5U);
    t14 = (t4 + 13U);
    t15 = (t1 + 13275);
    memcpy(t14, t15, 5U);
    t0 = xsi_get_transient_memory(24U);
    memcpy(t0, t4, 24U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_190370233_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;

LAB0:    t4 = xsi_get_transient_memory(8U);
    memset(t4, 0, 8U);
    t5 = t4;
    t6 = (t1 + 13280);
    memcpy(t5, t6, 1U);
    t8 = (t4 + 1U);
    t9 = (t1 + 13281);
    memcpy(t8, t9, 5U);
    t0 = xsi_get_transient_memory(8U);
    memcpy(t0, t4, 8U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_961825381_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;
    char *t11;
    char *t12;
    char *t14;
    char *t15;

LAB0:    t4 = xsi_get_transient_memory(24U);
    memset(t4, 0, 24U);
    t5 = t4;
    t6 = (t1 + 13286);
    memcpy(t5, t6, 3U);
    t8 = (t4 + 3U);
    t9 = (t1 + 13289);
    memcpy(t8, t9, 6U);
    t11 = (t4 + 9U);
    t12 = (t1 + 13295);
    memcpy(t11, t12, 6U);
    t14 = (t4 + 15U);
    t15 = (t1 + 13301);
    memcpy(t14, t15, 6U);
    t0 = xsi_get_transient_memory(24U);
    memcpy(t0, t4, 24U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_1967254405_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;

LAB0:    t4 = xsi_get_transient_memory(8U);
    memset(t4, 0, 8U);
    t5 = t4;
    t6 = (t1 + 13307);
    memcpy(t5, t6, 1U);
    t8 = (t4 + 1U);
    t9 = (t1 + 13308);
    memcpy(t8, t9, 6U);
    t0 = xsi_get_transient_memory(8U);
    memcpy(t0, t4, 8U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_2756105093_1522046508(char *t1)
{
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;

LAB0:    t4 = xsi_get_transient_memory(104U);
    memset(t4, 0, 104U);
    t5 = t4;
    t6 = (t1 + 13314);
    memcpy(t5, t6, 3U);
    t8 = (t4 + 3U);
    t9 = t8;
    memset(t9, (unsigned char)2, 32U);
    t10 = (t4 + 35U);
    t11 = t10;
    memset(t11, (unsigned char)2, 32U);
    t12 = (t4 + 67U);
    t13 = t12;
    memset(t13, (unsigned char)2, 32U);
    t0 = xsi_get_transient_memory(104U);
    memcpy(t0, t4, 104U);

LAB1:    return t0;
LAB2:;
}

char *work_p_2913168131_sub_1721094058_1522046508(char *t1)
{
    char t2[128];
    char t7[424];
    char *t0;
    char *t4;
    char *t5;
    char *t6;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    unsigned int t13;

LAB0:    t4 = (t2 + 4U);
    t5 = (t1 + 7720);
    t6 = (t4 + 88U);
    *((char **)t6) = t5;
    t8 = (t4 + 56U);
    *((char **)t8) = t7;
    xsi_type_set_default_value(t5, t7, 0);
    t9 = (t4 + 80U);
    *((unsigned int *)t9) = 424U;
    t10 = work_p_2913168131_sub_3620397739_1522046508(t1);
    t11 = (t4 + 56U);
    t12 = *((char **)t11);
    t13 = (0 + 0U);
    t11 = (t12 + t13);
    memcpy(t11, t10, 24U);
    t5 = work_p_2913168131_sub_1685871437_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 24U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 48U);
    t5 = xsi_get_transient_memory(32U);
    memset(t5, 0, 32U);
    t6 = t5;
    memset(t6, (unsigned char)2, 32U);
    t8 = (t4 + 56U);
    t9 = *((char **)t8);
    t13 = (0 + 72U);
    t8 = (t9 + t13);
    memcpy(t8, t5, 32U);
    t5 = work_p_2913168131_sub_2141115829_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 112U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 16U);
    t5 = work_p_2913168131_sub_2867232991_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 128U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 48U);
    t5 = work_p_2913168131_sub_732444313_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 176U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 24U);
    t5 = work_p_2913168131_sub_190370233_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 200U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 8U);
    t5 = work_p_2913168131_sub_961825381_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 208U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 24U);
    t5 = work_p_2913168131_sub_1967254405_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 232U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 8U);
    t5 = xsi_get_transient_memory(8U);
    memset(t5, 0, 8U);
    t6 = t5;
    memset(t6, (unsigned char)2, 8U);
    t8 = (t4 + 56U);
    t9 = *((char **)t8);
    t13 = (0 + 240U);
    t8 = (t9 + t13);
    memcpy(t8, t5, 8U);
    t5 = xsi_get_transient_memory(8U);
    memset(t5, 0, 8U);
    t6 = t5;
    memset(t6, (unsigned char)2, 8U);
    t8 = (t4 + 56U);
    t9 = *((char **)t8);
    t13 = (0 + 248U);
    t8 = (t9 + t13);
    memcpy(t8, t5, 8U);
    t5 = work_p_2913168131_sub_2756105093_1522046508(t1);
    t6 = (t4 + 56U);
    t8 = *((char **)t6);
    t13 = (0 + 256U);
    t6 = (t8 + t13);
    memcpy(t6, t5, 104U);
    t5 = xsi_get_transient_memory(32U);
    memset(t5, 0, 32U);
    t6 = t5;
    memset(t6, (unsigned char)2, 32U);
    t8 = (t4 + 56U);
    t9 = *((char **)t8);
    t13 = (0 + 360U);
    t8 = (t9 + t13);
    memcpy(t8, t5, 32U);
    t5 = xsi_get_transient_memory(32U);
    memset(t5, 0, 32U);
    t6 = t5;
    memset(t6, (unsigned char)2, 32U);
    t8 = (t4 + 56U);
    t9 = *((char **)t8);
    t13 = (0 + 392U);
    t8 = (t9 + t13);
    memcpy(t8, t5, 32U);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    t0 = xsi_get_transient_memory(424U);
    memcpy(t0, t6, 424U);

LAB1:    return t0;
LAB2:;
}


void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

void ieee_p_2592010699_sub_3130575329_503743352();

extern void work_p_2913168131_init()
{
	static char *se[] = {(void *)work_p_2913168131_sub_2384492247_1522046508,(void *)work_p_2913168131_sub_1615625482_1522046508,(void *)work_p_2913168131_sub_1685871437_1522046508,(void *)work_p_2913168131_sub_3620397739_1522046508,(void *)work_p_2913168131_sub_2141115829_1522046508,(void *)work_p_2913168131_sub_2867232991_1522046508,(void *)work_p_2913168131_sub_732444313_1522046508,(void *)work_p_2913168131_sub_190370233_1522046508,(void *)work_p_2913168131_sub_961825381_1522046508,(void *)work_p_2913168131_sub_1967254405_1522046508,(void *)work_p_2913168131_sub_2756105093_1522046508,(void *)work_p_2913168131_sub_1721094058_1522046508};
	xsi_register_didat("work_p_2913168131", "isim/NewCoreTB_isim_beh.exe.sim/work/p_2913168131.didat");
	xsi_register_subprogram_executes(se);
	xsi_register_resolution_function(1, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 5);
	xsi_register_resolution_function(3, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 5);
	xsi_register_resolution_function(11, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 5);
	xsi_register_resolution_function(12, 2, (void *)ieee_p_2592010699_sub_3130575329_503743352, 5);
}
