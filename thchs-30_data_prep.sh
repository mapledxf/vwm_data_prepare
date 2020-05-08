#!/bin/bash
# Copyright 2016  Tsinghua University (Author: Dong Wang, Xuewei Zhang).  Apache 2.0.
#           2016  LeSpeech (Author: Xingyu Na)

#This script pepares the data directory for thchs30 recipe.
#It reads the corpus and get wav.scp and transcriptions.

is_tts=false
fs=16000
. ./path.sh || exit 1
. utils/parse_options.sh

corpus_dir=$1
data=$2

echo "**** Creating THCHS-30 data folder ****"
mkdir -p $data/{train,dev,test} $data/local/{train,dev,test}

#create wav.scp, utt2spk.scp, spk2utt.scp, text
(
  for x in train dev test; do
    part=$data/local/$x
    echo "cleaning $part"
    rm -rf $part/{wav.scp,utt2spk,spk2utt,text}
    echo "preparing scps and text in $part"
    # updated new "for loop" figured out the compatibility issue with Mac     created by Xi Chen, in 03/06/2018
    for nn in $(find $corpus_dir/$x -name "*.wav" | sort -u | xargs -I {} basename {} .wav); do
      spkid=$(echo $nn | awk -F"_" '{print "" $1}')
      spk_char=$(echo $spkid | sed 's/\([A-Z]\).*/\1/')
      spk_num=$(echo $spkid | sed 's/[A-Z]\([0-9]\)/\1/')
      spkid=$(printf '%s%.2d' "$spk_char" "$spk_num")
      utt_num=$(echo $nn | awk -F"_" '{print $2}')
      uttid=$(printf '%s%.2d_%.3d' "$spk_char" "$spk_num" "$utt_num")
      echo $uttid $corpus_dir/$x/$nn.wav >>$part/wav.scp
      echo $uttid $spkid >>$part/utt2spk
      echo $uttid $(sed -n 1p $corpus_dir/data/$nn.wav.trn) | sed 's/ l =//' >>$part/transcripts.txt
    done

    if $is_tts; then
      $(dirname $(readlink -f "$0"))/local/to_pinyin.py $part/transcripts.txt | sort -u \
        >$part/text
    else
      $(dirname $(readlink -f "$0"))/local/jieba_segment.py $part/transcripts.txt | sort -u \
        >$part/text
    fi

    sort $part/wav.scp -o $data/$x/wav.scp
    sort $part/utt2spk -o $data/$x/utt2spk
    sort $part/text -o $data/$x/text
    utils/utt2spk_to_spk2utt.pl $data/$x/utt2spk >$data/$x/spk2utt

  done
) || exit 1

utils/data/resample_data_dir.sh ${fs} $data/train
utils/data/resample_data_dir.sh ${fs} $data/dev
utils/data/resample_data_dir.sh ${fs} $data/test

utils/data/validate_data_dir.sh --no-feats $data/train || exit 1
utils/data/validate_data_dir.sh --no-feats $data/dev || exit 1
utils/data/validate_data_dir.sh --no-feats $data/test || exit 1

touch $data/.complete
echo "$0: THCHS-30 data preparation succeeded"
