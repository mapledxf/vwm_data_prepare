#!/bin/bash -e

# Copyright 2019 Nagoya University (Tomoki Hayashi)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)
is_tts=false
. ./path.sh || exit 1;
. utils/parse_options.sh

db=$1
data_dir=$2/train

# check directory existence
[ ! -e ${data_dir} ] && mkdir -p ${data_dir}

# set filenames
scp=${data_dir}/wav.scp
utt2spk=${data_dir}/utt2spk
spk2utt=${data_dir}/spk2utt
text=${data_dir}/text
segments=${data_dir}/segments
echo "**** Creating CSMSC data folder ****"

# check file existence
[ -e ${scp} ] && rm ${scp}
[ -e ${utt2spk} ] && rm ${utt2spk}
[ -e ${text} ] && rm ${text}
[ -e ${segments} ] && rm ${segments}

# make scp, utt2spk, and spk2utt
find ${db} -name "*.wav" -follow | sort | while read -r filename;do
    id="csmsc$(basename ${filename} .wav)"
    echo "${id} ${filename}" >> ${scp}
    echo "${id} csmsc" >> ${utt2spk}
done
echo "Successfully finished making wav.scp, utt2spk."

echo "csmsc f" > ${data_dir}/spk2gender

utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}
echo "Successfully finished making spk2utt."

# make text and segments
if $is_tts; then
  find ${db}/PhoneLabeling -name "*.interval" -follow | sort | while read -r filename;do
    id="csmsc$(basename ${filename} .interval)"
    content=$(tail -n +13 ${filename} | grep "\"" | grep -v "sil" | sed -e "s/\"//g" | tr "\n" " " | sed -e "s/ $//g")
    start_sec=$(tail -n +14 ${filename} | head -n 1)
    end_sec=$(head -n -2 ${filename} | tail -n 1)
    echo "${id} ${content}" >> ${text}
    echo "${id} ${id} ${start_sec} ${end_sec}" >> ${segments}
  done
else
  python local/rm_punctuation.py ${db}/ProsodyLabeling/000001-010000.txt | sed 's/#[0-9] */ /g' | awk '{print "csmsc"$0}'> ${text}
fi

echo "Successfully finished making text, segments."
utils/data/validate_data_dir.sh --no-feats $data_dir || exit 1;
echo "$0: CSMSC data preparation succeeded"
