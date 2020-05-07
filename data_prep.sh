#!/bin/bash

is_tts=false
fs=16000
out_dir=/data/xfding/data_prep
. ./path.sh || exit 1;
. utils/parse_options.sh

if [ $# != 1 ]; then
    echo "Usage: $0 <corpus1,corpus2>"
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
    echo "    - ljspeech"
    exit 1;
fi

if $is_tts; then
	out_dir=$out_dir/tts
else
	out_dir=$out_dir/asr
fi

openslr_aidatatang=/data/xfding/share/ASR/aidatatang_200zh
openslr_aishell=/data/xfding/share/ASR/aishell/data_aishell
aishell_spk_info=/data/xfding/share/ASR/aishell/resource_aishell/speaker.info
openslr_magicdata=/data/xfding/share/ASR/magic
openslr_primewords=/data/xfding/share/ASR/primewords_md_2018_set1
openslr_stcmds=/data/xfding/share/ASR/ST-CMDS-20170001_1-OS
openslr_thchs=/data/xfding/share/ASR/thchs30/data_thchs30
openslr_celeb=/data/xfding/share/ASR/CN-Celeb
vwm_noisy_48h_src=/data/xfding/share/ASR/noisy-48h
vwm_quite_30h_src=/data/xfding/share/ASR/quite-30h
openslr_ljspeech=/data/xfding/share/TTS/LJSpeech-1.1

csmsc_data=/data/xfding/share/TTS/csmsc
cmlr_data=/data/xfding/share/TTS/cmlr

train_set=""
dev_set=""

IFS=','
read -ra ADDR <<< $1
for corpus in "${ADDR[@]}"; do
	corpus_dir=$out_dir/${corpus}_$fs
	train_set="$train_set $corpus_dir/train"
	dev_set="$dev_set $corpus_dir/dev"
	if [ -f $corpus_dir/.complete ]; then
		echo "$corpus_dir/.complete exists, skip"
	else
		case "${corpus}" in
			"aidatatang")
				echo "Preparing aidatatang"
				$(dirname $(readlink -f "$0"))/aidatatang_data_prep.sh --is_tts $is_tts --fs $fs $openslr_aidatatang $corpus_dir || exit 1;
				;;
			"aishell")
				echo "Preparing aishell"
				$(dirname $(readlink -f "$0"))/aishell_data_prep.sh --is_tts $is_tts --fs $fs $openslr_aishell $aishell_spk_info $corpus_dir || exit 1;
				;;
			"cmlr")
				echo "Preparing cmlr"
				$(dirname $(readlink -f "$0"))/cmlr_data_prep.sh --is_tts $is_tts --fs $fs $cmlr_data $corpus_dir || exit 1;
				;;
			"csmsc")
				echo "Preparing csmsc"
				$(dirname $(readlink -f "$0"))/csmsc_data_prep.sh --is_tts $is_tts --fs $fs $csmsc_data $corpus_dir || exit 1;
				;;
			"vwm_noisy_48h")
				echo "Preparing vwm_noisy_48h"
				$(dirname $(readlink -f "$0"))/vwm_data_prep.sh --is_tts $is_tts --fs $fs $vwm_noisy_48h_src $corpus_dir || exit 1;
				;;
			"vwm_quite_30h")
				echo "Preparing vwm_quite_30h"
				$(dirname $(readlink -f "$0"))/vwm_data_prep.sh --is_tts $is_tts --fs $fs $vwm_quite_30h_src $corpus_dir || exit 1;
				;;
			"stcmds")
				echo "Preparing stcmds"
				$(dirname $(readlink -f "$0"))/stcmds_data_prep.sh --is_tts $is_tts --fs $fs $openslr_stcmds $corpus_dir || exit 1;
				;;
			"thchs")
				echo "Preparing thchs"
				$(dirname $(readlink -f "$0"))/thchs-30_data_prep.sh --is_tts $is_tts --fs $fs $openslr_thchs $corpus_dir || exit 1;
				;;
			"magicdata")
				echo "Preparing magicdata"
				$(dirname $(readlink -f "$0"))/magicdata_data_prep.sh --is_tts $is_tts --fs $fs $openslr_magicdata $corpus_dir || exit 1;
				;;
			"primewords")
				echo "Preparing primewords"
				$(dirname $(readlink -f "$0"))/primewords_data_prep.sh --is_tts $is_tts --fs $fs $openslr_primewords $corpus_dir || exit 1;
				;;
			"ljspeech")
				echo "Preparing ljspeech"
				$(dirname $(readlink -f "$0"))/ljspeech_data_prep.sh --is_tts $is_tts --fs $fs $openslr_ljspeech $corpus_dir || exit 1;
				;;
			*) 
				echo "Do not support: ${corpus}"
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
                                echo "    - ljspeech"
				exit 1 
				;;
		esac
	fi
	echo ""
done

echo "Combine train data"
utils/combine_data.sh $out_dir/combined_${fs}/train \
	$train_set || exit 1;
echo "Combine dev data"
utils/combine_data.sh $out_dir/combined_${fs}/dev \
       	$dev_set || exit 1;
echo $'\nData prepare done'
