#!/bin/bash

is_tts=false

. ./path.sh || exit 1;
. utils/parse_options.sh


if [ $# != 2 ]; then
    echo "Usage: $0 <corpus> <data-path>"
    echo "Available pretrained models:"
    echo "    - aidatatang"
    echo "    - aishell"
    echo "    - cmlr"
    echo "    - csmsc"
    echo "    - vwm_noisy_48h"
    echo "    - vwm_quite-30h"
    echo "    - thchs"
    echo "    - magicdata"
    echo "    - primewords"
    echo "    - stcmds"
    exit 1;
fi

out_dir=$2

openslr_aidatatang=/home/data/xfding/dataset/asr/aidatatang_200zh
openslr_aishell=/home/data/xfding/dataset/asr/aishell/data_aishell
aishell_spk_info=/home/data/xfding/dataset/asr/aishell/resource_aishell/speaker.info
openslr_magicdata=/home/data/xfding/dataset/asr/magicdata
openslr_primewords=/home/data/xfding/dataset/asr/primewords_md_2018_set1
openslr_stcmds=/home/data/xfding/dataset/asr/ST-CMDS-20170001_1-OS
openslr_thchs=/home/data/xfding/dataset/asr/thchs30/data_thchs30

vwm_noisy_48h_src=/home/data/xfding/dataset/asr/noisy-48h
vwm_quite_30h_src=/home/data/xfding/dataset/asr/quite-30h
csmsc_data=/home/data/xfding/dataset/tts/csmsc/CSMSC
cmlr_data=/home/data/xfding/dataset/tts/cmlr

#        local/vwm_data_prep.sh $vwm_noisy_48h_src $out_dir/data/vwm_noisy_48h || exit 1;
#        local/vwm_data_prep.sh $vwm_quite_30h_src $out_dir/data/vwm_quite-30h || exit 1;

#        local/aidatatang_data_prep.sh $openslr_aidatatang $out_dir/data/aidatatang || exit 1;
#       local/aishell_data_prep.sh $openslr_aishell $out_dir/data/aishell || exit 1;
#       local/thchs-30_data_prep.sh $openslr_thchs $out_dir/data/thchs || exit 1;
#       local/magicdata_data_prep.sh $openslr_magicdata $out_dir/data/magicdata || exit 1;
#       local/primewords_data_prep.sh $openslr_primewords $out_dir/data/primewords || exit 1;
#       local/stcmds_data_prep.sh $openslr_stcmds $out_dir/data/stcmds || exit 1;


IFS=','
read -ra ADDR <<< $1
for corpus in "${ADDR[@]}"; do
    case "${corpus}" in
        "aidatatang")
            echo "Preparing aidatatang"
            $(dirname $(readlink -f "$0"))/aidatatang_data_prep.sh --is_tts $is_tts $openslr_aidatatang $out_dir/data/${corpus} || exit 1;
            
	    ;;
        "aishell")
            echo "Preparing aishell"
            $(dirname $(readlink -f "$0"))/aishell_data_prep.sh --is_tts $is_tts $openslr_aishell $aishell_spk_info $out_dir/data/aishell || exit 1;

	    ;;
        "cmlr")
            echo "Preparing cmlr"
            $(dirname $(readlink -f "$0"))/cmlr_data_prep.sh --is_tts $is_tts $cmlr_data $out_dir/data/cmlr || exit 1;

            ;;
        "csmsc")
            echo "Preparing csmsc"
            $(dirname $(readlink -f "$0"))/csmsc_data_prep.sh --is_tts $is_tts $csmsc_data $out_dir/data/csmsc || exit 1;
            
	    ;;
        "vwm_noisy_48h")
            echo "Preparing vwm_noisy_48h"
            $(dirname $(readlink -f "$0"))/vwm_data_prep.sh --is_tts $is_tts $vwm_noisy_48h_src $out_dir/data/vwm_noisy_48h || exit 1;

            ;;
        "vwm_quite_30h")
            echo "Preparing vwm_quite_30h"
	    $(dirname $(readlink -f "$0"))/vwm_data_prep.sh --is_tts $is_tts $vwm_quite_30h_src $out_dir/data/vwm_quite_30h || exit 1;

            ;;
        "stcmds")
            echo "Preparing stcmds"
	    $(dirname $(readlink -f "$0"))/stcmds_data_prep.sh --is_tts $is_tts $openslr_stcmds $out_dir/data/stcmds || exit 1;
            ;;
        "thchs")
            echo "Preparing thchs"
	    $(dirname $(readlink -f "$0"))/thchs-30_data_prep.sh --is_tts $is_tts $openslr_thchs $out_dir/data/thchs || exit 1;
            ;;
        "magicdata")
            echo "Preparing magicdata"
	    $(dirname $(readlink -f "$0"))/magicdata_data_prep.sh --is_tts $is_tts $openslr_magicdata $out_dir/data/magicdata || exit 1;
            ;;
        "primewords")
            echo "Preparing primewords"
	    $(dirname $(readlink -f "$0"))/primewords_data_prep.sh --is_tts $is_tts $openslr_primewords $out_dir/data/primewords || exit 1;
            ;;
        *) 
            echo "Do not support: ${corpus}"
            exit 1 
	    ;;
esac

done

