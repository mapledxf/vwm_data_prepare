#!/bin/bash
. ./path.sh || exit 1;

src_dir=$1
out_dir=$2

script=$1/script/script.txt

train_dir=$out_dir/local/train

mkdir -p $train_dir
mkdir -p $out_dir/train

echo "**** Creating VWM data folder ****"
#file list
find $src_dir -iname "*.wav" > $train_dir/wav.flist
#utt
sed -e 's/\.wav//' $train_dir/wav.flist | awk -F '/' '{split($NF,a,"_");s="0000"a[2]; printf("vwm%s_%s\n",substr(s, 1+length(s)-4),$NF)}' \
	> $train_dir/utt.list_all
#utt2spk
awk '{split($0,a,"_");printf("%s %s\n", $0, a[1])}' $train_dir/utt.list_all > $train_dir/utt2spk_all
#wav.scp
paste -d' ' $train_dir/utt.list_all $train_dir/wav.flist > $train_dir/wav.scp_all
#spk2gender
awk '{split($0,a,"_");printf("%s %s\n", a[1], tolower(a[4]))}' $train_dir/utt.list_all | sort | uniq > $train_dir/spk2gender

#transcript
sed -e 's/\.wav//' $script | awk '{split($1,a,"_");s="0000"a[2]; printf("vwm%s_%s %s\n",substr(s, 1+length(s)-4),$1,$2)}'> $train_dir/transcripts.txt_all

utils/filter_scp.pl -f 1 $train_dir/utt.list_all $train_dir/transcripts.txt_all | sort -k 1 | uniq > $train_dir/transcripts.txt
awk '{print $1}' $train_dir/transcripts.txt > $train_dir/utt.list

#wav.scp
utils/filter_scp.pl -f 1 $train_dir/utt.list $train_dir/wav.scp_all | sort -k 1 | uniq > $train_dir/wav.scp
#utt2spk
utils/filter_scp.pl -f 1 $train_dir/utt.list $train_dir/utt2spk_all | sort -k 1 | uniq > $train_dir/utt2spk
#spk2utt
utils/utt2spk_to_spk2utt.pl $train_dir/utt2spk | sort -k 1 | uniq > $train_dir/spk2utt
#text
python2 local/jieba_segment.py $train_dir/transcripts.txt > $train_dir/text
#cat $vwm_text |\
#  local/word_segment.py |\
#  awk '{if (NF > 1) print $0;}' > $train_dir/text

for f in spk2utt utt2spk wav.scp text spk2gender; do
	cp $train_dir/$f $out_dir/train/$f || exit 1;
done

utils/data/validate_data_dir.sh --no-feats $out_dir/train || exit 1;

echo "$0: VWM $out_dir data preparation succeeded"
exit 0;
