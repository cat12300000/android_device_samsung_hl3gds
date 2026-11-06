#!/bin/sh
# Copyright (C) 2014 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export DEVICE=hl3gds
export VENDOR=samsung

function extract() {
    for FILE in `egrep -v '(^#|^$)' $1`; do
        OLDIFS=$IFS IFS=":" PARSING_ARRAY=($FILE) IFS=$OLDIFS
        FILE=`echo ${PARSING_ARRAY[0]} | sed -e "s/^-//g"`
        DEST=${PARSING_ARRAY[1]}
        if [ -z "$DEST" ]; then
            DEST=$FILE
        fi
        DIR=`dirname $FILE`
        if [ ! -d $2/$DIR ]; then
            mkdir -p $2/$DIR
        fi
        if [ "$SRC" = "adb" ]; then
            adb pull /system/$DEST $2/$DEST
            if [ "$?" != "0" ]; then
                adb pull /system/$FILE $2/$DEST
            fi
        else
            cp $SRC/system/$FILE $2/$DEST
            if [ "$?" != "0" ]; then
                cp $SRC/system/$DEST $2/$DEST
            fi
        fi
    done
}

if [ $# -eq 0 ]; then
    SRC=adb
elif [ $# -eq 1 ]; then
    SRC=$1
else
    echo "$0: bad number of arguments"
    echo "usage: $0 [PATH_TO_EXPANDED_ROM]"
    exit 1
fi

DEVBASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $DEVBASE/*

extract ../../$VENDOR/$DEVICE/proprietary-files.txt $DEVBASE

./setup-makefiles.sh
