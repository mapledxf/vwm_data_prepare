#!/bin/bash

# Copyright 2018 Nagoya University (Tomoki Hayashi)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

is_tts=false
fs=16000
. ./path.sh || exit 1
. utils/parse_options.sh

db=$1
data=$2
data_dir=$data/all

# check directory existence
[ ! -e ${data_dir} ] && mkdir -p ${data_dir}

# set filenames
scp=${data_dir}/wav.scp
utt2spk=${data_dir}/utt2spk
spk2utt=${data_dir}/spk2utt
text=${data_dir}/text

echo "**** Creating LJSpeech data folder ****"

# check file existence
[ -e ${scp} ] && rm ${scp}
[ -e ${utt2spk} ] && rm ${utt2spk}

# make scp, utt2spk, and spk2utt
find ${db} -follow -name "*.wav" | sort | while read -r filename;do
    id=$(basename ${filename} | sed -e "s/\.[^\.]*$//g")
    echo "${id} ${filename}" >> ${scp}
    echo "${id} LJ" >> ${utt2spk}
done
utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}
echo "finished making wav.scp, utt2spk, spk2utt."

# make text
$(dirname $(readlink -f "$0"))/local/clean_ljspeech_text.py ${db}/metadata.csv phn > ${text}
echo "finished making text."

utils/data/resample_data_dir.sh ${fs} $data_dir
utils/data/validate_data_dir.sh --no-feats $data_dir || exit 1

train_set="train"
dev_set="dev"
n_total=$(wc -l <$data_dir/wav.scp)
echo total set:$n_total
n_dev=$(($n_total * 10 / 100))
n_train=$(($n_total - $n_dev))
echo train set:$n_train, dev set:$n_dev
# make a dev set
utils/subset_data_dir.sh --last $data_dir $n_dev $data/${dev_set}
utils/subset_data_dir.sh --first $data_dir $n_train $data/${train_set}

utils/data/validate_data_dir.sh --no-feats $data/${dev_set} || exit 1
utils/data/validate_data_dir.sh --no-feats $data/${train_set} || exit 1

touch $data/.complete
echo "$0: LJSpeech data preparation succeeded"
