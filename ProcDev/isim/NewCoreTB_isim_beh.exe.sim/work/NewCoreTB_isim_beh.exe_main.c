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

#include "xsi.h"

struct XSI_INFO xsi_info;

char *IEEE_P_2592010699;
char *STD_STANDARD;
char *WORK_P_2392574874;
char *WORK_P_0629994561;
char *WORK_P_2913168131;
char *WORK_P_2284038668;
char *WORK_P_4234477589;
char *WORK_P_0311766069;
char *WORK_P_0937207982;
char *VL_P_2533777724;
char *WORK_P_1873144592;
char *WORK_P_3178049071;


int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    work_m_00000000004134447467_2073120511_init();
    work_m_00000000003404880040_0704559786_init();
    work_m_00000000004226915032_0868512641_init();
    work_m_00000000000796210778_0842653801_init();
    work_m_00000000002180939344_2240448696_init();
    work_m_00000000000493532047_1979947349_init();
    work_m_00000000002249749207_0415011089_init();
    ieee_p_2592010699_init();
    work_p_2392574874_init();
    work_p_2284038668_init();
    work_p_0629994561_init();
    work_p_2913168131_init();
    work_p_4234477589_init();
    work_p_0311766069_init();
    work_p_0937207982_init();
    work_p_1873144592_init();
    work_p_3178049071_init();
    vl_p_2533777724_init();
    work_a_4060132910_3212880686_init();
    work_a_3831697636_3212880686_init();
    work_a_3337218246_3212880686_init();
    work_a_2047717864_3212880686_init();
    work_a_1303830672_3212880686_init();
    work_a_2934060513_3212880686_init();
    work_a_3501452797_3212880686_init();
    work_a_3575107912_3212880686_init();
    work_a_3265312990_3212880686_init();
    work_a_3772717429_3212880686_init();
    work_a_1547386971_3212880686_init();
    work_a_4050926721_3212880686_init();
    work_a_2244275876_3212880686_init();
    work_a_0958445450_3212880686_init();
    work_a_3056845610_3212880686_init();
    work_a_2776971433_1263834759_init();
    work_a_2063723557_2372691052_init();


    xsi_register_tops("work_a_2063723557_2372691052");
    xsi_register_tops("work_m_00000000004134447467_2073120511");

    IEEE_P_2592010699 = xsi_get_engine_memory("ieee_p_2592010699");
    xsi_register_ieee_std_logic_1164(IEEE_P_2592010699);
    STD_STANDARD = xsi_get_engine_memory("std_standard");
    WORK_P_2392574874 = xsi_get_engine_memory("work_p_2392574874");
    WORK_P_0629994561 = xsi_get_engine_memory("work_p_0629994561");
    WORK_P_2913168131 = xsi_get_engine_memory("work_p_2913168131");
    WORK_P_2284038668 = xsi_get_engine_memory("work_p_2284038668");
    WORK_P_4234477589 = xsi_get_engine_memory("work_p_4234477589");
    WORK_P_0311766069 = xsi_get_engine_memory("work_p_0311766069");
    WORK_P_0937207982 = xsi_get_engine_memory("work_p_0937207982");
    VL_P_2533777724 = xsi_get_engine_memory("vl_p_2533777724");
    WORK_P_1873144592 = xsi_get_engine_memory("work_p_1873144592");
    WORK_P_3178049071 = xsi_get_engine_memory("work_p_3178049071");

    return xsi_run_simulation(argc, argv);

}
