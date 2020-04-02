#!/bin/bash

is_tts=false

. ./path.sh || exit 1;
. utils/parse_options.sh

cmlr_dir=$1
data=$2
train_dir=$data/local/train
mkdir -p $train_dir

echo "**** Creating cmlr data folder ****"
# find wav audio file for train, dev and test resp.
find $cmlr_dir -iname "*.wav" > $train_dir/wav.flist
n=`cat $train_dir/wav.flist | wc -l`
echo Found $n data files
echo Preparing $train_dir transcriptions

sed -e 's/\.wav//' $train_dir/wav.flist | \
	awk -F '/' '{i=NF-2;printf("cmlr%02d",substr($i,2));d=NF-1;printf("_%s_%s\n",$d,$NF)}' \
	> $train_dir/utt.list

sed -e 's/\.wav//' $train_dir/wav.flist | awk -F '/' '{i=NF-2;printf("cmlr%02d",substr($i,2));printf("\n")}' >$train_dir/spk.list

mkdir -p $data/train

while read line; do
  tn=`dirname $line`/`basename $line .wav`.txt;
  head -n 1 $tn | awk '{{printf $0}}'; echo;
done < $train_dir/wav.flist > $train_dir/text.list

paste -d' ' $train_dir/utt.list $train_dir/text.list > $train_dir/trans.txt
if $is_tts; then
	local/to_pinyin.py $train_dir/trans.txt phn | sort -u > $data/train/text
else
	python2 local/jieba_segment.py $train_dir/trans.txt > $data/train/text
fi
paste -d' ' $train_dir/utt.list $train_dir/wav.flist | sort > $data/train/wav.scp
paste -d' ' $train_dir/utt.list $train_dir/spk.list | sort > $data/train/utt2spk
utils/utt2spk_to_spk2utt.pl $data/train/utt2spk | sort > $data/train/spk2utt
echo "cmlr01 m" > $data/train/spk2gender
echo "cmlr03 m" >> $data/train/spk2gender
echo "cmlr06 f" >> $data/train/spk2gender
echo "cmlr10 m" >> $data/train/spk2gender

utils/data/validate_data_dir.sh --no-feats $data/train || exit 1;

echo "$0: CMLR data preparation succeeded"

