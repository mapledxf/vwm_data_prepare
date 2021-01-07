#!/bin/bash
is_tts=false
fs=16000

. ./path.sh || exit 1
. utils/parse_options.sh

src_dir=$1
out_dir=$2

script=$1/script/script.txt

train_dir=$out_dir/local/train

mkdir -p $train_dir

echo "**** Creating VWM data folder ****"
#file list
find $src_dir -iname "*.wav" >$train_dir/wav.flist
#utt
sed -e 's/\.wav//' $train_dir/wav.flist | awk -F '/' '{split($NF,a,"_");s="0000"a[2]; printf("vwm%s_%s\n",substr(s, 1+length(s)-4),$NF)}' \
  >$train_dir/utt.list_all
#utt2spk
awk '{split($0,a,"_");printf("%s %s\n", $0, a[1])}' $train_dir/utt.list_all >$train_dir/utt2spk_all
#wav.scp
paste -d' ' $train_dir/utt.list_all $train_dir/wav.flist >$train_dir/wav.scp_all
#spk2gender
awk '{split($0,a,"_");printf("%s %s\n", a[1], tolower(a[4]))}' $train_dir/utt.list_all | sort | uniq >$train_dir/spk2gender

#transcript
sed -e 's/\.wav//' $script | awk '{split($1,a,"_");s="0000"a[2]; printf("vwm%s_%s %s\n",substr(s, 1+length(s)-4),$1,$2)}' >$train_dir/transcripts.txt_all

utils/filter_scp.pl -f 1 $train_dir/utt.list_all $train_dir/transcripts.txt_all | sort -k 1 | uniq >$train_dir/transcripts.txt
awk '{print $1}' $train_dir/transcripts.txt >$train_dir/utt.list

#wav.scp
utils/filter_scp.pl -f 1 $train_dir/utt.list $train_dir/wav.scp_all | sort -k 1 | uniq >$train_dir/wav.scp
#utt2spk
utils/filter_scp.pl -f 1 $train_dir/utt.list $train_dir/utt2spk_all | sort -k 1 | uniq >$train_dir/utt2spk
#spk2utt
utils/utt2spk_to_spk2utt.pl $train_dir/utt2spk | sort -k 1 | uniq >$train_dir/spk2utt
#text
if $is_tts; then
  $(dirname $(readlink -f "$0"))/local/to_pinyin.py $train_dir/transcripts.txt | sort -u \
    >$train_dir/text
else
  $(dirname $(readlink -f "$0"))/local/jieba_segment.py $train_dir/transcripts.txt | sort -u \
    >$train_dir/text
fi

utils/data/resample_data_dir.sh ${fs} $train_dir
utils/data/validate_data_dir.sh --no-feats $train_dir || exit 1

train_set="train"
dev_set="dev"
n_total=$(wc -l <$train_dir/wav.scp)
echo total set:$n_total
n_dev=$(($n_total * 10 / 100))
n_train=$(($n_total - $n_dev))
echo train set:$n_train, dev set:$n_dev
# make a dev set
utils/subset_data_dir.sh --last $train_dir $n_dev $out_dir/${dev_set}
utils/subset_data_dir.sh --first $train_dir $n_train $out_dir/${train_set}

#train_set="train"
#dev_set="dev"
#n_spk=$(wc -l <$train_dir/spk2utt)
#n_total=$(wc -l <$train_dir/wav.scp)
#echo total set:$n_total
#n_dev=$(($n_total * 2 / 100 / $n_spk))
#n_train=$(($n_total - $n_dev))
#echo train set:$n_train, dev set:$n_dev
## make a dev set
#utils/subset_data_dir.sh --per-spk $train_dir $n_dev $out_dir/${dev_set}
#utils/subset_data_dir.sh $train_dir $n_total $out_dir/${train_set}

utils/data/validate_data_dir.sh --no-feats $out_dir/${dev_set} || exit 1
utils/data/validate_data_dir.sh --no-feats $out_dir/${train_set} || exit 1

touch $out_dir/.complete
echo "$0: VWM $out_dir data preparation succeeded"
exit 0
