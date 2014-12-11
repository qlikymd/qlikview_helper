require 'net/http'
require 'uri'
require 'json'
require 'open-uri'
require 'openssl'
require 'rubygems'
require 'pp'
require 'nokogiri'
require './ymd_crawler'
require 'yaml'
require "fileutils"

##
## QlikView のディレクトリ構造に従い、別途生成された成果フォルダからデータを取得するスクリプト。
##


# 引数から処理対象のフォルダ名（YYYYMMDD形式の日付）を取得
target_date = ARGV[0]

pp "YYYYMMDD 形式の日付を引数に指定してください。" unless ARGV[0]
exit unless ARGV[0]

# 引数指定なかったら今日とか昨日とかの日付を埋めてあげるのもあり

target_dir = "./external_data/#{ARGV[0]}"

pp "指定された日付のフォルダはありません。 : #{target_dir}" unless FileTest.exist? target_dir
exit unless FileTest.exist? target_dir

pp "フォルダが見つかりました : #{target_dir}"




############# 楽天ファイルチェック #################
pp "楽天の成果データコピー処理"
config = YAML.load(File.open("config/rakuten.yml"))
rakuten_dir = target_dir + "/rakuten/"
FileUtils.mkdir_p(rakuten_dir) unless FileTest.exist?(rakuten_dir)

# yaml に定義されているクライアントの数だけループする
config["clients"].each do |client|
  target_file_path = rakuten_dir + config["asp_short_name"] + "_" + client["name"] + "_table.csv"

  pp "#{target_file_path} は既に存在しています。" if FileTest.exist? target_file_path
  next if FileTest.exist? target_file_path

  # 取得済レポートをチェック
  client_raw_id = client["id"][2..256]
  tmp_file_path = "./tmp/#{config['asp_name']}/#{config['report_file_prefix']}_#{client_raw_id}_#{target_date}.csv"
  pp tmp_file_path
  pp "#{tmp_file_path} は存在しません" unless FileTest.exist? tmp_file_path
  next unless FileTest.exist? tmp_file_path

  # external_data にファイルがなくて tmp にファイルがあったときだけコピーする
  FileUtils.cp(tmp_file_path, target_file_path)
  pp "#{target_file_path} を作成しました"
end

############ amazon ファイルチェック #############
pp "Amazon の成果データコピー処理"
config = YAML.load(File.open("config/amazon.yml"))
amazon_dir = target_dir + "/amazon/"
FileUtils.mkdir_p(amazon_dir) unless FileTest.exist?(amazon_dir)

# yaml に定義されているクライアントの数だけループする
config["clients"].each do |client|
  target_file_path = amazon_dir + config["asp_short_name"] + "_" + client["name"] + "_table.csv"

  pp "#{target_file_path} は既に存在しています。" if FileTest.exist? target_file_path
  next if FileTest.exist? target_file_path

  # 取得済レポートをチェック
  client_raw_id = client["id"][2..256]
  tmp_file_path = "./tmp/#{config['asp_name']}/#{client['amazon_id']}#{config['report_file_prefix']}#{target_date}.tsv"
  pp tmp_file_path
  pp "#{tmp_file_path} は存在しません" unless FileTest.exist? tmp_file_path
  next unless FileTest.exist? tmp_file_path

  # external_data にファイルがなくて tmp にファイルがあったときだけコピーする
  FileUtils.cp(tmp_file_path, target_file_path)
  pp "#{target_file_path} を作成しました"
end

