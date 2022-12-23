# Two rake tasks are defined here:
#   manifest:upload - Upload sprockets manifest file to S3
#   mainfest:download - Download sprockets manifest file from S3
# The sprockets file is a JSON file that contains a mapping of asset names to their digested versions.
# When uploading it, it will have a random generated filename, but should be uploaded as `sprockets-manifest.json`


def manifest_filename
  Sprockets::Manifest.new(nil, Rails.root + 'public/assets').filename
end

def upload_file(filename, s3_filename)
  puts "Uploading #{filename} to S3 as #{s3_filename}"
  File.open(filename) do |file|
    helper.upload(file, s3_filename)
  end
end

def download_file(s3_filename, filename)
  puts "Downloading #{s3_filename} from S3 to #{filename}"
  FileUtils.mkdir_p(File.dirname(filename))
  helper.download_file(s3_filename, filename)
end

S3_FILENAME = 'sprockets-manifest.json'

CHUNKS_FILENAME = '/var/www/discourse/app/assets/javascripts/discourse/dist/chunks.json'
CHUNKS_S3_FILENAME = 'chunks.json'

SPLASH_SCREEN_FILENAME = '/var/www/discourse/app/assets/javascripts/discourse/dist/assets/splash-screen.js'
SPLASH_SCREEN_S3_FILENAME = 'splash-screen.js'

task 'manifest:upload' => :environment do
  upload_file(manifest_filename, S3_FILENAME)
  upload_file(CHUNKS_FILENAME, CHUNKS_S3_FILENAME)
  upload_file(SPLASH_SCREEN_FILENAME, SPLASH_SCREEN_S3_FILENAME)
end

task 'manifest:download' => :environment do
  download_file(S3_FILENAME, manifest_filename)
  download_file(CHUNKS_S3_FILENAME, CHUNKS_FILENAME)
  download_file(SPLASH_SCREEN_S3_FILENAME, SPLASH_SCREEN_FILENAME)
end
