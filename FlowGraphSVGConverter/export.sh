#!/bin/sh
cd `dirname $0`

# Homebrewがインストールされていなければ終了
if ! which brew; then
  echo "brew not found. Prease install Homebrew."
  exit 1
fi

# graphvizがインストールされていなければインストールする
if ! brew list | grep -q graphviz; then
  brew install graphviz
fi

swift build -c release
.build/release/FlowGraphSVGConverter
