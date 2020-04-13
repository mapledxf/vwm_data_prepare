#!/bin/bash

# Copyright 2019 Xingyu Na
# Apache 2.0

is_tts=false
fs=16000

. ./path.sh || exit 1;
. utils/parse_options.sh

corpus=$1
out_dir=$2
data_local=$out_dir/local
data_dir=$out_dir/all

echo "**** Creating primewords data folder ****"

mkdir -p $data_dir

# find wav audio file for train

find $corpus -iname "*.wav" > $data_local/wav.flist
n=`cat $data_local/wav.flist | wc -l`
[ $n -ne 50384 ] && \
  echo Warning: expected 50384 data files, found $n

echo "Filtering data using found wav list and provided transcript"
$(dirname $(readlink -f "$0"))/local/primewords_parse_transcript.py $data_local/wav.flist $corpus/set1_transcript.json $data_local
if $is_tts; then
  $(dirname $(readlink -f "$0"))/local/to_pinyin.py $data_local/transcripts.txt phn | sort -u > $data_local/text
else
  sort -u $data_local/transcripts.txt > $data_local/text
fi

for file in wav.scp utt2spk text; do
  sort $data_local/$file -o $data_dir/$file
done
utils/utt2spk_to_spk2utt.pl $data_dir/utt2spk > $data_dir/spk2utt

utils/data/resample_data_dir.sh ${fs} $data_dir
utils/data/validate_data_dir.sh --no-feats $data_dir || exit 1;

train_set="train"
dev_set="dev"
n_spk=$(wc -l < $data_dir/spk2utt)
n_total=$(wc -l < $data_dir/wav.scp)
echo total set:$n_total
n_dev=$(($n_total * 2 / 100 / $n_spk))
n_train=$(($n_total - $n_dev))
echo train set:$n_train, dev set:$n_dev
# make a dev set
utils/subset_data_dir.sh --per-spk $data_dir $n_dev $out_dir/${dev_set}
utils/subset_data_dir.sh $data_dir $n_total $out_dir/${train_set}

utils/data/validate_data_dir.sh --no-feats $out_dir/${dev_set} || exit 1;
utils/data/validate_data_dir.sh --no-feats $out_dir/${train_set} || exit 1;

touch $out_dir/.complete
echo "$0: primewords data preparation succeeded"
