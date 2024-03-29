#!/usr/bin/env bash

uname=$(uname)
[ $uname = Darwin ] || [ $uname = Linux ] || exit 1
which fzf > /dev/null 2>&1 || echo 'fzf' could not found || exit 1

cmd='xdg-open'
if [ $uname = Darwin ]; then
	cmd='open'
fi

/usr/bin/ruby -x $0                                 |
  fzf  --ansi --multi --no-hscroll --tiebreak=begin |
  ruby -ne 'url=$_.strip.split("\t")[1];puts url'   |
  xargs -I @ $cmd '@'

exit $?

#!ruby
# encoding: utf-8

require 'json'

isDarwin = (/darwin/ =~ RUBY_PLATFORM) != nil
FILE = isDarwin ? '~/Library/Application Support/Google/Chrome/Default/Bookmarks' : '~/.config/google-chrome/Default/Bookmarks'
CJK  = /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/

def build parent, json
  name = [parent, json['name']].compact.join('/')
  if json['type'] == 'folder'
    json['children'].map { |child| build name, child }
  else
    { name: name, url: json['url'] }
  end
end

def just str, width
  str.ljust(width - str.scan(CJK).length)
end

def trim str, width
  len = 0
  str.each_char.each_with_index do |char, idx|
    len += char =~ CJK ? 2 : 1
    return str[0, idx] if len > width
  end
  str
end

width = `tput cols`.strip.to_i / 2
json  = JSON.load File.read File.expand_path FILE
items = json['roots']
        .values_at(*%w(bookmark_bar synced other))
        .compact
        .map { |e| build nil, e }
        .flatten

items.each do |item|
  name = trim item[:name], width
  puts [just(name, width),
        item[:url]].join("\t\x1b[36m") + "\x1b[m"
end

