#!/bin/bash

# Copyright 2019 Xingyu Na
# Apache 2.0

is_tts=false
. ./path.sh || exit 1;
. utils/parse_options.sh

corpus=$1
data=$2

echo "**** Creating ST-CMDS data folder ****"

mkdir -p $data/train

# find wav audio file for train

find $corpus -iname "*.wav" > $data/wav.list
n=`cat $data/wav.list | wc -l`
[ $n -ne 102600 ] && \
  echo Warning: expected 102600 data files, found $n

cat $data/wav.list | awk -F'20170001' '{print $NF}' | awk -F'.' '{print $1}' > $data/utt.list
cat $data/utt.list | awk '{print substr($1,1,6)}' > $data/spk.list
while read line; do
  tn=`dirname $line`/`basename $line .wav`.txt;
  cat $tn; echo;
done < $data/wav.list > $data/text.list

paste -d' ' $data/utt.list $data/wav.list > $data/train/wav.scp
paste -d' ' $data/utt.list $data/spk.list > $data/train/utt2spk
paste -d' ' $data/utt.list $data/text.list |\
  sed 's/，//g' |\
  local/word_segment.py |\
  tr '[a-z]' '[A-Z]' |\
  awk '{if (NF > 1) print $0;}' > $data/transcripts.txt

if $is_tts; then
  $(dirname $(readlink -f "$0"))/local/to_pinyin.py $data/transcripts.txt phn | sort -u > $data/train/text
else
  cp $data/transcripts.txt $data/train/text
fi


for file in wav.scp utt2spk text; do
  sort $data/train/$file -o $data/train/$file
done

utils/utt2spk_to_spk2utt.pl $data/train/utt2spk > $data/train/spk2utt

rm -r $data/{wav,utt,spk,text}.list

utils/data/validate_data_dir.sh --no-feats $data/train || exit 1;
