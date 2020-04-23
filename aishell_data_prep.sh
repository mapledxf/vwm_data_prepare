#!/bin/bash

# Copyright 2017 Xingyu Na
# Apache 2.0

is_tts=false
fs=16000

. ./path.sh || exit 1
. utils/parse_options.sh

aishell_audio_dir=$1/wav
aishell_text=$1/transcript/aishell_transcript_v0.8.txt
data=$3
spk_info=$2

train_dir=$data/local/train
dev_dir=$data/local/dev
test_dir=$data/local/test
tmp_dir=$data/local/tmp

mkdir -p $train_dir
mkdir -p $dev_dir
mkdir -p $test_dir
mkdir -p $tmp_dir

# data directory check
if [ ! -d $aishell_audio_dir ] || [ ! -f $aishell_text ]; then
  echo "Error: $0 requires two directory arguments"
  exit 1
fi

echo "**** Creating aishell data folder ****"
# find wav audio file for train, dev and test resp.
find $aishell_audio_dir -iname "*.wav" >$tmp_dir/wav.flist
n=$(cat $tmp_dir/wav.flist | wc -l)
[ $n -ne 141925 ] &&
  echo Warning: expected 141925 data data files, found $n

grep -i "wav/train" $tmp_dir/wav.flist >$train_dir/wav.flist || exit 1
grep -i "wav/dev" $tmp_dir/wav.flist >$dev_dir/wav.flist || exit 1
grep -i "wav/test" $tmp_dir/wav.flist >$test_dir/wav.flist || exit 1

rm -r $tmp_dir

# Transcriptions preparation
for dir in $train_dir $dev_dir $test_dir; do
  echo Preparing $dir transcriptions
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{print $NF}' >$dir/utt.list
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{i=NF-1;printf("%s %s\n",$NF,$i)}' >$dir/utt2spk_all
  paste -d' ' $dir/utt.list $dir/wav.flist >$dir/wav.scp_all
  utils/filter_scp.pl -f 1 $dir/utt.list $aishell_text |
    sed 's/ａ/a/g' | sed 's/ｂ/b/g' |
    sed 's/ｃ/c/g' | sed 's/ｋ/k/g' |
    sed 's/ｔ/t/g' >$dir/transcripts.txt
  awk '{print $1}' $dir/transcripts.txt >$dir/utt.list
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/utt2spk_all | sort -u | awk '{print $1" BAC009"$2}' >$dir/utt2spk
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/wav.scp_all | sort -u >$dir/wav.scp

  if $is_tts; then
    python $(dirname $(readlink -f "$0"))/local/clean_data.py $dir/transcripts.txt \
      >$dir/trans_clean.txt
    $(dirname $(readlink -f "$0"))/local/to_pinyin.py $dir/trans_clean.txt | sort -u >$dir/text
  else
    python $(dirname $(readlink -f "$0"))/local/clean_data.py $dir/transcripts.txt all \
      >$dir/trans_clean.txt
    sort -u $dir/trans_clean.txt >$dir/text
  fi

  utils/utt2spk_to_spk2utt.pl $dir/utt2spk >$dir/spk2utt
  # create spk2gender
  awk '{print "BAC009S"$1" "$2}' $spk_info | sed 's/ M/ m/g' | sed 's/ F/ f/g' >$dir/spk2gender_all
  utils/filter_scp.pl -f 1 $dir/spk2utt $dir/spk2gender_all >$dir/spk2gender
done

mkdir -p $data/train $data/dev $data/test

for f in spk2utt utt2spk wav.scp text spk2gender; do
  cp $train_dir/$f $data/train/$f || exit 1
  cp $dev_dir/$f $data/dev/$f || exit 1
  cp $test_dir/$f $data/test/$f || exit 1
done

utils/data/resample_data_dir.sh ${fs} $data/train || exit 1
utils/data/resample_data_dir.sh ${fs} $data/dev || exit 1
utils/data/resample_data_dir.sh ${fs} $data/test || exit 1

utils/data/validate_data_dir.sh --no-feats $data/train || exit 1
utils/data/validate_data_dir.sh --no-feats $data/dev || exit 1
utils/data/validate_data_dir.sh --no-feats $data/test || exit 1

touch $data/.complete
echo "$0: AISHELL data preparation succeeded"
exit 0
