# Two rake tasks are defined here:
#   manifest:upload - Upload sprockets manifest file to S3
#   mainfest:download - Download sprockets manifest file from S3
# The sprockets file is a JSON file that contains a mapping of asset names to their digested versions.
# When uploading it, it will have a random generated filename, but should be uploaded as `sprockets-manifest.json`


def manifest_filename
  Sprockets::Manifest.new(nil, Rails.root + 'public/assets').filename
end

S3_FILENAME = 'sprockets-manifest.json'


task 'manifest:upload' => :environment do
  puts "Uploading manifest file to S3 from #{manifest_filename}"
  File.open(manifest_filename) do |file|
    helper.upload(file, S3_FILENAME)
  end
end

task 'manifest:download' => :environment do
  puts "Downloading manifest file from S3 to #{manifest_filename}"
  helper.download_file(S3_FILENAME, manifest_filename)
end
