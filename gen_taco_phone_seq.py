#!/usr/bin/env python
# -*- coding:utf-8 -*-
# Copyright 2020 Mobovi Inc. All Rights Reserved.
# Author: hao.yin@mobvoi.com

# generate taco phone seq from scripts
# Usage: python gen_taco_phone_seq.py scripts.txt(with prosody) taco_phone_seq.txt
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import argparse
import os
import re
import sys
import codecs
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sm = 'b p m f d t n l g k h j q x zh ch sh r z c s y w'.split()

sil_list = ["。", "？", "！", "——", "……", "…", "·", "；", ".", "?", "!", "...", ";", "~"]
pau_list = ["，", "、", "：", "（", "）", "（", "）", "［", "］", "〔", "〕",
            "【", "】", "_", "—", "-", "～", "〜", "《", "》", "＿＿", ",",
            ":", "-", "–", "—", "(", ")", "[", "]", "{", "}", "<", ">"]
phr_list = ["“", "”", "﹃", "﹄", "‘", "’", "﹁", "﹂", "『", "』",
            "﹃", "﹄", "·", "〈", "〉", "﹏﹏", "\"", "'", "/", "「", "」", "^"]

xer_list = ['dianr', 'ker', 'niangr', 'nar', 'wanr', 'menr', 'huir', 'lianr', 'jinr', 'kuair', 'diaor', 'bianr', 'shir',
            'hair', 'zher', 'weir', 'ger', 'fanr', 'renr', 'gair', 'zhenr', 'jir', 'qur', 'zuir', 'danr', 'gunr',
            'yanr', 'huar', 'ganr', 'mingr', 'dunr', 'lir', 'weir', 'daor', 'far']

error_list = []
phoneme = []


def get_all_files(dir_name, ext='.txt'):
    all_files = list()
    if os.path.exists(dir_name):
        files = os.listdir(dir_name)
        for entry in files:
            full_path = os.path.join(dir_name, entry)
            if os.path.isdir(full_path):
                all_files = all_files + get_all_files(full_path, ext)
            elif full_path.endswith(ext):
                all_files.append(full_path)
    return all_files


def get_file_name(path):
    file_name = os.path.basename(path)
    file_name = os.path.splitext(file_name)
    return file_name[0]


def read_from_prosody_file(dir_name):
    sid_list, script_list, phone_list = [], [], []
    files = get_all_files(dir_name)
    for filename in files:
        tmp = filename.split('/')
        if "中英混" in tmp[-2]:
            wav_dir = os.path.join(os.path.dirname(dir_name), "wave_48k", tmp[-2])
        else:
            wav_dir = os.path.join(os.path.dirname(dir_name), "wave_48k", tmp[-2], get_file_name(tmp[-1]))
        lines = open(filename, encoding="utf-8").readlines()
        for i, line in enumerate(lines[:]):
            line = line.replace('\xef\xbb\xbf', '').replace('<feff>', '').strip()
            if i % 2 == 0:
                if line.strip()[:-2] != '#4':
                    line += '#4'
                pieces = line.strip().split('\t', 1)
                wav = os.path.join(wav_dir, pieces[0].strip().split('_')[-1]) + ".wav"
                sid_list.append(wav)
                tmp = pieces[1].strip().split('\t', 1)[-1]
                script_list.append(tmp)
            if i % 2 == 1:
                phone_list.append(line.strip())

    return sid_list, script_list, phone_list


def insert_sharp_iprocess(item):
    item_new = ''
    if len(item) < 2:
        return item
    # print(item, len(item))

    for i, t in enumerate(item):
        # print(t)
        if (t.lower() >= 'a' and t.lower() <= 'z') or t.isdigit():
            # print('1',t)
            item_new = item_new + t
        else:
            # print('2',t)
            if i > 0 and len(item[i - 1]) == 1 and 'a' <= item[i - 1].lower() <= 'z':
                item_new = item_new + '#1' + t + '#1'
            else:
                item_new = item_new + t + '#1'
    # print(item_new)
    # print(item_new)
    if not (item[-1].lower() >= 'a' and item[-1].lower() <= 'z'):
        item_new = item_new[:-2]
    # print(item_new)
    # print('\n')
    return item_new


def insert_sharp(tmp):
    pieces = tmp.split('#')
    pieces_new = []
    for item in pieces:
        # item=item.decode('utf-8')
        item = item
        item = insert_sharp_iprocess(item)
        pieces_new.append(item)
    return '#'.join(pieces_new)


def get_script_sharp_list(tmp):
    pass


def replace_2lianxu_sharp(line):
    for i in range(1, 6):
        for j in range(1, 6):
            line = line.replace('#%s#%s' % (i, j), '#%s' % (j if j > i else i))
    return line


# 处理scripts
def process_scripts(script_list):
    script_list_new = []
    script_sharp_list = []
    for line in script_list:
        line = re.sub('\\s+', ' ', line)
        tmp = line.strip().replace('#1 ', '#1').replace('#0 ', '#0') \
            .replace('#2 ', '#2') \
            .replace('#3 ', '#3') \
            .replace('#4 ', '#4') \
            .replace('#5 ', '#5') \
            .replace(' ', '#9')
        for t in sil_list + phr_list:
            tmp = tmp.replace(t, '')
        for t in pau_list:
            tmp = tmp.replace(t, '&')

        tmp = tmp.replace('%', '#3')
        tmp = tmp.replace('#4', '#5')
        tmp = tmp.replace('#3&', '#5')
        tmp = tmp.replace('#3', '#4')
        tmp = tmp.replace('#2', '#3')
        tmp = tmp.replace('#1', '#2')
        tmp = tmp.replace('#0', '#1')
        tmp = tmp.replace('#9', '#2')
        tmp = tmp.replace('&', '')

        tmp = replace_2lianxu_sharp(tmp)

        if tmp[0] == '#':
            tmp = tmp[2:]
        tmp = insert_sharp(tmp)

        script_list_new.append(tmp)
        script_sharp_list.append(re.findall('#\d', tmp))

    return script_list_new, script_sharp_list


def cut_phone_seq(line):
    pieces = line.strip().split('/')
    pieces_new = []
    for item in pieces:
        item = item.strip()
        if len(item) == 0: continue
        print("++++", item)
        if 'A' <= item[0] <= 'Z':
            pieces_new.append(item.strip())
        elif 'a' <= item[0] <= 'z':
            for t in item.split():
                pieces_new.append(t)
    return pieces_new


def process_single_phone(phone_seq):
    phone_seq_new = []
    for item in phone_seq:
        # print(item)
        item = item.strip().replace('.', '#1')
        if item[:-1] not in xer_list:
            phone_seq_new.append(item)
        else:
            phone1, phone2 = item[:-2] + item[-1], 'x' + item[-2:]
            # print(phone1, phone2)
            phone_seq_new.append(phone1)
            phone_seq_new.append(phone2)
    return phone_seq_new


def process_phones(phone_list):
    phone_list_new = []
    for line in phone_list:
        phone_seq = cut_phone_seq(line)
        phone_seq_new = process_single_phone(phone_seq)
        phone_list_new.append(phone_seq_new)
    return phone_list_new


def verify_length(sid_list, script_sharp_list, phone_list_new, script_list):
    not_equal_count = 0
    print(len(script_sharp_list), len(phone_list_new))
    assert len(script_sharp_list) == len(phone_list_new), 'len(script_sharp_list)!=len(phone_list_new)'
    for a, b, c, d in zip(sid_list, script_sharp_list, phone_list_new, script_list):
        print(a, b, c, '==')
        print(len(a), len(b), len(c), '==')
        if len(b) < len(c):
            print(a, "b < c\t", len(b), len(c))
            error_list.append(a)
        if len(b) != len(c):
            not_equal_count += 1
            print('len(b)!=len(c) check:', len(re.findall('[a-zA-Z]#0[a-zA-Z]', d)), len(c), len(b))
            if len(re.findall('[a-zA-Z]#0[a-zA-Z]', d)) + len(c) != len(b):
                print('dbc verify_length err:', a)
                error_list.append(a)
    print('not_equal_count:', not_equal_count)
    print('length verify ok')


def combine_phone_sharp(script_sharp_list, phone_list_new):
    combine_list = []
    for a, b in zip(script_sharp_list, phone_list_new):
        s = []
        for aa, bb in zip(a, b):
            s.append(bb + " " + aa)
        combine_list.append(s)
    return combine_list


def cut_pinyin_tone(tone):
    length = len(tone)
    i = length
    if tone == 'xr':
        return [tone]
    while i > 0:
        if tone[:i] in sm:
            break
        i -= 1
    if i > 0:
        if tone[i:] != 'va':
            return [tone[:i], tone[i:]]
        else:
            return [tone[:i], tone[i:] + 'n']
    else:
        return [tone]


# OW1 N #1 L IY0 #4 -> OW N 8 #1 L IY 7 #4
def post_process_english(item):
    eng_tone_map = {'0': '7', '1': '8', '2': '9'}
    pieces = item.strip().split()
    pieces_new = []
    print(item)
    for p in pieces:
        if p[0] != '#' and p[-1].isdigit() and int(p[-1]) in [0, 1, 2]:
            tone = p[-1]
            pieces_new.append(p[:-1])
        elif p[0] == '#':
            assert str(tone) in eng_tone_map, 'eng tone %s not in eng_tone_map' % str(tone)
            pieces_new[-1] = pieces_new[-1]+eng_tone_map[str(tone)]
#            pieces_new.append(eng_tone_map[str(tone)])
            pieces_new.append(p)
        else:
            pieces_new.append(p)
    return pieces_new


def post_process(combine_list):
    global phoneme
    combine_list_new = []
    for item in combine_list:
        s = []
        # for chinese
        if item[0].islower():
            phone, p = item.strip().split()
            assert phone[-1].isdigit(), '%s not digit' % (phone)
            ct = ' '.join(cut_pinyin_tone(phone[:-1]))
            s = [ct + phone[-1] + ' ' + p]
        # for english
        else:
            s = [' '.join(post_process_english(item))]

        phoneme += (s[0].split())
        combine_list_new += s
    return combine_list_new


def gen_taco_phone_seq_end(combine_list_new):
    taco_phone_seq = []

    for item in combine_list_new:
        s = 'SIL ' + ' '.join(item[:])
        taco_phone_seq.append(s[:-2] + 'SIL')
    return taco_phone_seq


def gen_taco_phone_seq(prosody_file):
    sid_list, script_list, phone_list = read_from_prosody_file(prosody_file)

    # 处理后的scripts
    script_list_new, script_sharp_list = process_scripts(script_list)

    phone_list_new = process_phones(phone_list)

    verify_length(sid_list, script_sharp_list, phone_list_new, script_list)

    combine_list = combine_phone_sharp(script_sharp_list, phone_list_new)
    combine_list_new = []
    for item in combine_list:
        combine_list_new.append(post_process(item))

    taco_phone_seq = gen_taco_phone_seq_end(combine_list_new)

    assert len(sid_list) == len(taco_phone_seq), 'len(sid_list)!=len(taco_phone_seq)'
    return sid_list, taco_phone_seq


def main():
    prosody_file = sys.argv[1]
    taco_phone_seq_file = sys.argv[2]
    sid_list, taco_phone_seq = gen_taco_phone_seq(prosody_file)
    f = codecs.open(taco_phone_seq_file, 'w', encoding='utf-8')
    for sid, seq in zip(sid_list, taco_phone_seq):
        if (sid not in error_list):
            s = '%s\t%s\n' % (sid.replace('\ufeff', ''), seq)
            f.write(s)
    f.close()
    print("bad phon list")
    print(error_list)
    print(sorted(set(phoneme)))


if __name__ == '__main__':
    main()

