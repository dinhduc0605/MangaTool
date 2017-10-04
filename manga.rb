require "rubygems"
require "nokogiri"
require "open-uri"
require "fileutils"
require 'sqlite3'

ROOT_FOLDER = "F:/Manga"
ROOT_URL = "http://raw.senmanga.com"

def show_menu
  print "
    -------------MENU-----------------
    | Chon chuc nang:                |
    | 1. Crawl manga from Sen Manga  |
    | 2. Convert from images to HTML |
    | 3. Rename image file           |
    ----------------------------------
    Chon: "
  # use chomp to remove enter character
  choice = gets.chomp
  case choice
    when "1"
      p "------------------ Crawl manga form SenManga ---------------------"
      p "Input manga name: "
      manga_name = gets.chomp
      crawl_manga manga_name
    when "2"
      p "------------------ Convert from images to HTML -------------------"
      p "Input manga folder path: "
      manga_folder_path = gets.chomp
      convert_to_html manga_folder_path
    when "3"
      p "--------------------- Rename image file --------------------------"
      p "Input manga folder path: "
      # path phai dung / khong duoc dung \
      manga_folder_path = gets.chomp
      rename_image_file manga_folder_path
  end
end

def download_photo(photo_url, filepath)
  photo_url = URI.parse(URI.encode(photo_url))
  print "Downloading #{photo_url}...\n\n"
  begin
    open photo_url do |f|
      File.open(filepath, "w") { |file| file.puts f.read }
    end
  rescue Exception => e
    p "Error_download_photo: #{e}"
  else
    print "Download successful, saved to #{filepath}\n\n"
  end
end

# crawl from sen manga
def crawl_manga manga_name
  processed_manga_name = manga_name.gsub(" ", "_")
  p "-------------------- Crawl Manga: #{manga_name}---------------------------"
  # FileUtils.makedirs(root_folder) unless File.exist?(ROOT_FOLDER)
  manga_page = Nokogiri::HTML open("#{ROOT_URL}/#{processed_manga_name}")
  manga_folder_path = "#{ROOT_FOLDER}/#{manga_name}"
  # FileUtils.makedirs(manga_folder_path) unless File.exist?(manga_folder_path)
  chapter_links = manga_page.css "div#post table a"
  chapter_links.each do |link|
    chapter_url = "#{ROOT_URL}#{link["href"]}"
    chapter_page = Nokogiri::HTML open(chapter_url)
    chapter_number = chapter_page.at_css("div.pager select[name='chapter'] option[selected='selected']")["value"]
    chapter_folder_path = "#{manga_folder_path}/chapter_#{chapter_number}"
    FileUtils.makedirs(chapter_folder_path) unless File.exist?(chapter_folder_path)
    page_number = chapter_page.css("div.pager select[name='page'] option").last["value"].to_i
    page_number.times do |i|
      index = i+1
      photo_path = "#{chapter_folder_path}/#{index}.jpg"
      photo_url = "#{ROOT_URL}/viewer/#{processed_manga_name}/#{chapter_number}/#{index}"
      download_photo photo_url, photo_path
      sleep 1.0 + rand
    end
    sleep 1.0 + rand
  end
end

def convert_to_html manga_folder_path
  index_file_content = '<!DOCTYPE html>
                        <html>
                        <head>
                          <title>Mangas</title>
                          <link rel="stylesheet" type="text/css" href="custom.css">

                        </head>
                        <body>
                          <h1>Chapter List</h1>
                          <ul>'
  chapter_dirs = Dir.glob("#{manga_folder_path}/*").select {|f| File.directory? f}

  chapter_dirs.each do |dir|
    chapter_name = File.basename dir
    chapter_path = "#{manga_folder_path}/#{chapter_name}"
    index_file_content += "<li><a href=\"#{chapter_name}.html\">#{chapter_name}</a></li>"
    image_files = Dir.glob("#{chapter_path}/*")
    chapter_file_content = "<!DOCTYPE html>
                          <html>
                          <head>
                            <title>#{chapter_name}</title>
                            <link rel=\"stylesheet\" type=\"text/css\" href=\"custom.css\">
                          </head>
                          <body>
                            <h1>#{chapter_name}</h1>"
    image_files.each do |file|
      file_name = File.basename file
      file_path = "#{chapter_path}/#{file_name}"
      chapter_file_content += "<img src=\"#{file_path}\">"
    end
    chapter_file_content += ' </body>
                              </html>'
    chapter_file = File.open("#{chapter_name}.html", 'w+')
    chapter_file.write chapter_file_content
    chapter_file.close
  end
  index_file_content += '</ul>
                      </body>
                      </html>'
  index_file = File.open('index.html', 'w+')
  index_file.write index_file_content
  index_file.close
end

def rename_image_file manga_folder_path
  p manga_folder_path
  chapter_dirs = Dir.glob("#{manga_folder_path}/*").select {|f| File.directory? f}
  chapter_dirs.each do |dir|
    # ten folder ko dc co dau []
    dir_name = File.basename dir
    chapter_path = "#{manga_folder_path}/#{dir_name}"
    p chapter_path
    image_files = Dir.glob("#{chapter_path}/*")
    image_files.each_with_index do |file, index|
      File.rename(file, chapter_path + "/" + ("%03d" % index) + File.extname(file))
    end
  end
end

show_menu
