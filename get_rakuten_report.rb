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

# 引数から受けるならこっち
# uri = URI.parse(ARGV[0])

config = YAML.load(File.open("config/rakuten.yml"))
pp config["clients"]

config["clients"].each do |client|

  # basic 認証用 ID/PW をセット
  certs =  [client["id"], client['pw']]

  # 楽天の場合クライアント単位でリクエスト先が変わるので、用意する
  base_uri = config["asp_base_uri"] + client["id"] + "/"

  # クロールする始点のHTMLを取得
  html = YmdCrawler.get_html({:certs => certs, :uri => base_uri})

  # HTML の中を漁り、a タグを列挙
  doc = Nokogiri::HTML.parse(html, nil, nil)
  file_list = YmdCrawler.crawl(doc, base_uri, certs)

  # ファイル取得処理

  # ASP別ベースディレクトリに移動
  file_list.each_with_index do |uri, idx|

    fileName = File.basename(uri)
    dirName = "./tmp/#{config['asp_name']}/"
    filePath = dirName + fileName

    # 既に保存していないかをチェック。存在する場合 skip
    if  FileTest.exist? filePath
     pp "#{filePath} already exists" 
    else
      # 存在していない場合、get
      result = YmdCrawler.get_html({:certs => certs, :uri => uri})

      # ディレクトリをチェックしなければ作成
      FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)

      # ファイル書き出し
      open(filePath, 'wb') do |output|
        output.write result
      end
    end
  end
end

