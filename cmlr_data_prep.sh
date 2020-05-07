#!/bin/bash

is_tts=false
fs=16000

. ./path.sh || exit 1
. utils/parse_options.sh

cmlr_dir=$1
data=$2
temp_dir=$data/local
mkdir -p $temp_dir

echo "**** Creating cmlr data folder ****"
# find wav audio file for train, dev and test resp.
#find $cmlr_dir -iname "*.wav" >$temp_dir/wav.flist
find $cmlr_dir -iname "*.wav" | grep "s2" >$temp_dir/wav.flist

n=$(cat $temp_dir/wav.flist | wc -l)
echo Found $n data files
echo Preparing $temp_dir transcriptions

sed -e 's/\.wav//' $temp_dir/wav.flist |
  awk -F '/' '{i=NF-2;printf("cmlr%02d",substr($i,2));d=NF-1;printf("_%s_%s\n",$d,$NF)}' \
    >$temp_dir/utt.list

sed -e 's/\.wav//' $temp_dir/wav.flist | awk -F '/' '{i=NF-2;printf("cmlr%02d",substr($i,2));printf("\n")}' >$temp_dir/spk.list

while read line; do
  tn=$(dirname $line)/$(basename $line .wav).txt
  head -n 1 $tn | awk '{{printf $0}}'
  echo
done <$temp_dir/wav.flist >$temp_dir/text.list

paste -d' ' $temp_dir/utt.list $temp_dir/text.list >$temp_dir/trans.txt

mkdir -p $data/all

if $is_tts; then
  python $(dirname $(readlink -f "$0"))/local/clean_data.py $temp_dir/trans.txt \
    >$temp_dir/trans_clean.txt
  $(dirname $(readlink -f "$0"))/local/to_pinyin.py $temp_dir/trans_clean.txt | sort -u \
    >$data/all/text
else
  python $(dirname $(readlink -f "$0"))/local/clean_data.py $temp_dir/trans.txt all \
    >$temp_dir/trans_clean.txt
  python2 $(dirname $(readlink -f "$0"))/local/jieba_segment.py $temp_dir/trans_clean.txt | sort -u \
    >$data/all/text
fi
paste -d' ' $temp_dir/utt.list $temp_dir/wav.flist | sort >$data/all/wav.scp
paste -d' ' $temp_dir/utt.list $temp_dir/spk.list | sort >$data/all/utt2spk
utils/utt2spk_to_spk2utt.pl $data/all/utt2spk | sort >$data/all/spk2utt
echo "cmlr01 m" >$data/all/spk2gender
echo "cmlr02 m" >>$data/all/spk2gender
echo "cmlr03 m" >>$data/all/spk2gender
echo "cmlr04 f" >>$data/all/spk2gender
echo "cmlr05 f" >>$data/all/spk2gender
echo "cmlr06 f" >>$data/all/spk2gender
echo "cmlr07 f" >>$data/all/spk2gender
echo "cmlr08 f" >>$data/all/spk2gender
echo "cmlr09 m" >>$data/all/spk2gender
echo "cmlr10 m" >>$data/all/spk2gender
echo "cmlr11 m" >>$data/all/spk2gender

echo "cmlr02 m" >$data/all/spk2gender

utils/data/resample_data_dir.sh ${fs} $data/all
utils/data/validate_data_dir.sh --no-feats $data/all || exit 1

train_set="train"
dev_set="dev"
n_spk=$(wc -l <$data/all/spk2utt)
n_total=$(wc -l <$data/all/wav.scp)
echo total set:$n_total
n_dev=$(($n_total * 2 / 100 / $n_spk))
n_train=$(($n_total - $n_dev))
echo train set:$n_train, dev set:$n_dev
# make a dev set
utils/subset_data_dir.sh --per-spk $data/all $n_dev $data/${dev_set}
utils/subset_data_dir.sh $data/all $n_total $data/${train_set}

utils/data/validate_data_dir.sh --no-feats $data/${dev_set} || exit 1
utils/data/validate_data_dir.sh --no-feats $data/${train_set} || exit 1

touch $data/.complete
echo "$0: CMLR data preparation succeeded"
