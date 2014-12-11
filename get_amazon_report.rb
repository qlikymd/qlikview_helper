require 'net/http'
require 'uri'
require 'open-uri'
require 'openssl'
require 'rubygems'
require 'pp'
require 'nokogiri'
require './ymd_crawler'
require 'yaml'
require "fileutils"

config = YAML.load(File.open("config/amazon.yml"))
pp config["clients"]

uri = URI.parse config["asp_base_uri"]

config["clients"].each do |client|
certs =  ['orico', 'oricomall']
  certs =  [client["id"], client['pw']]

  # クロールする始点のHTMLを取得
  html = YmdCrawler.get_html({:certs => certs, :uri => config["asp_base_uri"], :auth => "digest"})
  # HTML の中を漁り、a タグを列挙
  doc = Nokogiri::HTML.parse(html, nil, nil)

  file_list = YmdCrawler.crawl(doc, uri.path, certs)

  pp file_list

  file_list.each_with_index do |uri, idx|

#    uri.gsub!("listReportsgetReport?filename=", "")
    next if uri.include? "xml"
#    next if uri.include? ""

    fileName = File.basename(uri)
    dirName = "./tmp/#{config['asp_name']}/"
    filePath = dirName + fileName.gsub!("listReportsgetReport?filename=", "").gsub!(".gz", "")

    target = config["asp_host"] + uri
    target.gsub!("listReports", "")
#pp target

    # 既に保存していないかをチェック。存在する場合 skip
    if  FileTest.exist? filePath
     pp "#{filePath} already exists"
    else
      # 存在していない場合、get
      result = YmdCrawler.get_html({:certs => certs, :uri => target, :auth => "digest"})

      # ディレクトリをチェックしなければ作成
      FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)

      # ファイル書き出し
      open(filePath, 'wb') do |output|
#        open(result) do |data| 
#          output.write data.read
#        end
        output.write result
      end
    end
  end
end

