#!/bin/bash
if [ -d "flutter" ]; then
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable
fi
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter pub get
./flutter/bin/flutter pub run sqflite_common_ffi_web:setup
./flutter/bin/flutter build web --release