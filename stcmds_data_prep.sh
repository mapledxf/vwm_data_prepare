#!/bin/bash

# Copyright 2019 Xingyu Na
# Apache 2.0

is_tts=false
fs=16000
. ./path.sh || exit 1
. utils/parse_options.sh

corpus=$1
data=$2
data_dir=$data/all

echo "**** Creating ST-CMDS data folder ****"

mkdir -p $data_dir $data/local

# find wav audio file for train

find $corpus -iname "*.wav" >$data/local/wav.list
n=$(cat $data/local/wav.list | wc -l)
[ $n -ne 102600 ] &&
  echo Warning: expected 102600 data files, found $n

cat $data/local/wav.list | awk -F'20170001' '{print $NF}' | awk -F'.' '{print $1}' >$data/local/utt.list
cat $data/local/utt.list | awk '{print substr($1,1,6)}' >$data/local/spk.list
while read line; do
  tn=$(dirname $line)/$(basename $line .wav).txt
  cat $tn
  echo
done <$data/local/wav.list >$data/local/text.list

paste -d' ' $data/local/utt.list $data/local/wav.list >$data_dir/wav.scp
paste -d' ' $data/local/utt.list $data/local/spk.list >$data_dir/utt2spk
paste -d' ' $data/local/utt.list $data/local/text.list >$data/local/transcripts.txt
#paste -d' ' $data/local/utt.list $data/local/text.list |\
#  sed 's/，//g' |\
#  $(dirname $(readlink -f "$0"))/local/word_segment.py |\
#  tr '[a-z]' '[A-Z]' |\
#  awk '{if (NF > 1) print $0;}' > $data/local/transcripts.txt

if $is_tts; then
  $(dirname $(readlink -f "$0"))/local/to_pinyin.py $data/local/transcripts.txt | sort -u \
    >$data_dir/text
else
  $(dirname $(readlink -f "$0"))/local/jieba_segment.py $data/local/transcripts.txt | sort -u \
    >$data_dir/text
fi

for file in wav.scp utt2spk text; do
  sort $data_dir/$file -o $data_dir/$file
done

utils/utt2spk_to_spk2utt.pl $data_dir/utt2spk >$data_dir/spk2utt

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
utils/subset_data_dir.sh --last $data/all $n_dev $data/${dev_set}
utils/subset_data_dir.sh --first $data/all $n_train $data/${train_set}

#train_set="train"
#dev_set="dev"
#n_spk=$(wc -l <$data_dir/spk2utt)
#n_total=$(wc -l <$data_dir/wav.scp)
#echo total set:$n_total
#n_dev=$(($n_total * 2 / 100 / $n_spk))
#n_train=$(($n_total - $n_dev))
#echo train set:$n_train, dev set:$n_dev
## make a dev set
#utils/subset_data_dir.sh --per-spk $data/all $n_dev $data/${dev_set}
#utils/subset_data_dir.sh $data/all $n_total $data/${train_set}

utils/data/validate_data_dir.sh --no-feats $data/${dev_set} || exit 1
utils/data/validate_data_dir.sh --no-feats $data/${train_set} || exit 1

touch $data/.complete
echo "$0: ST-CMDS data preparation succeeded"
