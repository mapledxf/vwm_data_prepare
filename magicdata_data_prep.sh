#!/bin/bash

# Copyright 2019 Xingyu Na
# Apache 2.0

is_tts=false
fs=16000

. ./path.sh || exit 1;
. utils/parse_options.sh

corpus=$1
data=$2

echo "**** Creating magicdata data folder ****"

mkdir -p $data/{train,dev,test,tmp}

# find wav audio file for train, dev and test resp.
tmp_dir=$data/tmp
find $corpus -iname "*.wav" > $tmp_dir/wav.flist
n=`cat $tmp_dir/wav.flist | wc -l`
[ $n -ne 609552 ] && \
  echo Warning: expected 609552 data data files, found $n

for x in train dev test; do
  grep -i "/$x/" $tmp_dir/wav.flist > $data/$x/wav.flist || exit 1;
  echo "Filtering data using found wav list and provided transcript for $x"
  local/magicdata_data_filter.py $data/$x/wav.flist $corpus/$x/TRANS.txt $data/$x local/magicdata_badlist
  cat $data/$x/transcripts.txt |\
    sed 's/！//g' | sed 's/？//g' |\
    sed 's/，//g' | sed 's/－//g' |\
    sed 's/：//g' | sed 's/；//g' |\
    sed 's/　//g' | sed 's/。//g' |\
    sed 's/\[//g' | sed 's/]//g' |\
    sed 's/FIL//g' | sed 's/SPK//g' |\
    local/word_segment.py |\
    tr '[a-z]' '[A-Z]' |\
    awk '{if (NF > 1) print $0;}' > $data/$x/text
  for file in wav.scp utt2spk text; do
    sort $data/$x/$file -o $data/$x/$file
  done
  utils/utt2spk_to_spk2utt.pl $data/$x/utt2spk > $data/$x/spk2utt
done

rm -r $tmp_dir
utils/data/resample_data_dir.sh ${fs} $data/train
utils/data/resample_data_dir.sh ${fs} $data/dev
utils/data/resample_data_dir.sh ${fs} $data/test

utils/data/validate_data_dir.sh --no-feats $data/train || exit 1;
utils/data/validate_data_dir.sh --no-feats $data/dev || exit 1;
utils/data/validate_data_dir.sh --no-feats $data/test || exit 1;

touch $data/.complete
echo "$0: magicdata data preparation succeeded"
